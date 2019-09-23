#!/usr/bin/env bats

setup() {
    echo "setup"
    # Docker名を指定(docker_composeファイルの場所と連動)
    docker_name='coupon_api_default'
    # テストデータを用意
    data='{
        "id": {"S": "0001245"},
        "title": {"S": "【秋葉原店】全商品 10% OFF！"},
        "descriptive_text": {"S": "ご利用一回限り。他のクーポンとの併用はできません。クーポンをご利用いただいた場合、ポイントはつきません。"} }'
    data_id="0001245"
}

teardown() {
    echo "teardown"
}

@test "DynamoDB Get Function response the correct item" {

    expected=`echo "${data}" | jq -r .`
    echo $DOCKER_NAME
    # テストデータを LocalStack の DynamoDB に投入
    aws --endpoint-url=http://localhost:4569 dynamodb put-item --table-name COUPON_INFO --item "${data}"

    # SAM Local を起動し、Lambda Function の出力を得る
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/index/get_payload.json --env-vars environments/sam-local.json GetFunction | jq -r .body `

    #出力確認用コマンド
    #echo `echo "${actual}" | jq .`
    #echo `echo "${expected}" | jq .`

    # 出力内容をテスト(空白文字比較のためdouble bracket、bash,zsh,Korn shellで有効)
    [[ `echo "${actual}" | jq .id` = `echo "${expected}" | jq .id.S` ]]
    [[ `echo "${actual}" | jq .title` = `echo "${expected}" | jq .title.S` ]]
    [[ `echo "${actual}" | jq .text` = `echo "${expected}" | jq .text.S` ]]
}

@test "DynamoDB Transport Index Function correct item insert" {
    # テストデータ(put_payload.json)

    # 転置インデックステーブルにデータを登録
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/transport/put_payload.json --env-vars environments/sam-local.json TransportTablePutFunction`

    [[ `echo "${actual}" ` = `echo \"Done\"` ]]
}

@test "DynamoDB Transport Index Function correct item remove" {
    # テストデータ(delete_payload.json)

    # データの挿入
    sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/transport/put_payload.json --env-vars environments/sam-local.json TransportTablePutFunction

    # データの削除
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/transport/delete_payload.json --env-vars environments/sam-local.json TransportTablePutFunction`

    [[ `echo "${actual}" ` = `echo \"Done\"` ]]
}

@test "DynamoDB Transport Index Function correct item modify" {
    # テストデータ(modify_payload.json)

    # データの修正
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/transport/modify_payload.json --env-vars environments/sam-local.json TransportTablePutFunction`

    [[ `echo "${actual}" ` = `echo \"Done\"` ]]
}

@test "API Gateway End to End test  Get Function response" {
    # ローカルAPI Gatewayサーバの起動
    if [ `lsof -i :4000` = "" ]; then
      sam local start-api -p 4000 -t template_coupon.yaml --docker-network ${docker_name} --env-vars environments/sam-local.json
      api_server_flag="ON"
    else
      echo "Please Stop the process of port 4000: port check ex(MaxOS). lsof -i :4000"
      api_server_flag="OFF"
    fi

    expected=`echo "${data}" | jq -r .`

    aws --endpoint-url=http://localhost:4569 dynamodb put-item --table-name COUPON_INFO --item "${data}"

    # curlでレスポンスを取得
    actual=`curl -H "Content-type: application/json" -X GET http://127.0.0.1:4000/resource/${data_id} | jq `

    [[ `echo "${actual}" | jq .id` = `echo "${expected}" | jq .id.S` ]]
    [[ `echo "${actual}" | jq .title` = `echo "${expected}" | jq .title.S` ]]
    [[ `echo "${actual}" | jq .text` = `echo "${expected}" | jq .text.S` ]]

    # APIサーバを終了
    if [ api_server_flag="ON" ]; then
      ps ax | grep 'sam local start-api -p 4000' | grep -v grep | cut -f1 -d " " | xargs kill -9
    fi
}
