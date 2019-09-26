#!/usr/bin/env bats
api_server_flag="OFF"

setup() {
    echo "setup"
    # Docker名を指定(docker_composeファイルの場所と連動)
    docker_name='coupon_api_default'
    # テストデータを用意
    info_data='{
        "id": {"S": "0001245"},
        "title": {"S": "【秋葉原店】全商品 10% OFF！"},
        "descriptive_text": {"S": "ご利用一回限り。他のクーポンとの併用はできません。クーポンをご利用いただいた場合、ポイントはつきません。"} ,
        "updated_at": {"S":"1569430072"},
        "coupon_type": {"S":"org_aws"} }'
    info_data2='{
        "id": {"S": "0000999"},
        "title": {"S": "水道橋店限定_10円OFF"},
        "descriptive_text": {"S": "他のクーポンとの併用可能です。"},
        "updated_at": {"S":"1569430071"},
        "coupon_type": {"S":"org_aws"} }'
    title_data='{
      "title_part": {"S": "秋葉原"},
      "coupon_info_id": {"S": "0001245"} }'
    info_data_id="0001245"
}

teardown() {
    echo "teardown"
}

@test "DynamoDB Get Function response the correct item" {

    expected=`echo "${info_data}" | jq -r .`
    echo $DOCKER_NAME
    # テストデータを LocalStack の DynamoDB に投入
    aws --endpoint-url=http://localhost:4569 dynamodb put-item --table-name COUPON_INFO --item "${info_data}"

    # SAM Local を起動し、Lambda Function の出力を得る
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/index/get_payload.json --env-vars environments/sam-local.json GetFunction | jq -r .body `

    echo $actual
    # 出力内容をテスト(空白文字比較のためdouble bracket、bash,zsh,Korn shellで有効)
    [[ `echo "${actual}" | jq .id` = `echo "${expected}" | jq .id.S` ]]
    [[ `echo "${actual}" | jq .title` = `echo "${expected}" | jq .title.S` ]]
    [[ `echo "${actual}" | jq .text` = `echo "${expected}" | jq .text.S` ]]
}

@test "DynamoDB Get Title Function response the correct item" {
    aws --endpoint-url=http://localhost:4569 dynamodb put-item --table-name COUPON_INFO --item "${info_data}"
    aws --endpoint-url=http://localhost:4569 dynamodb put-item --table-name COUPON_TITLE --item "${title_data}"
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/title_index/get_payload.json --env-vars environments/sam-local.json GetTitleFunction | jq -r .body `

    [[ `echo "${actual}" | jq .id` = `echo "${expected}" | jq .id.S` ]]
    [[ `echo "${actual}" | jq .title` = `echo "${expected}" | jq .title.S` ]]
    [[ `echo "${actual}" | jq .text` = `echo "${expected}" | jq .text.S` ]]
}

@test "DynamoDB Get Function response the error item" {
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/index/error_get_payload.json --env-vars environments/sam-local.json GetFunction | jq `
    [[ `echo "${actual}" | jq .statusCode` = 404 ]]
}

@test "DynamoDB Get Title Function response the error item" {
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/title_index/error_get_payload.json --env-vars environments/sam-local.json GetTitleFunction | jq `
    [[ `echo "${actual}" | jq .statusCode` = 404 ]]
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

@test "API Gateway End to End test Get Function response" {
    # ローカルAPI Gatewayサーバの起動
    if [ `lsof -i :4000` = "" ]; then
        sam local start-api -p 4000 -t template_coupon.yaml --docker-network ${docker_name} --env-vars environments/sam-local.json
        api_server_flag="ON"
    else
        echo "Please Stop the process of port 4000: port check ex(MaxOS). lsof -i :4000"
        api_server_flag="OFF"
    fi
    expected=`echo "${info_data}" | jq -r .`

    aws --endpoint-url=http://localhost:4569 dynamodb put-item --table-name COUPON_INFO --item "${info_data}"

    # curlでレスポンスを取得
    actual=`curl -H "Content-type: application/json" -X GET http://127.0.0.1:4000/resource/${info_data_id} | jq `

    [[ `echo "${actual}" | jq .id` = `echo "${expected}" | jq .id.S` ]]
    [[ `echo "${actual}" | jq .title` = `echo "${expected}" | jq .title.S` ]]
    [[ `echo "${actual}" | jq .text` = `echo "${expected}" | jq .text.S` ]]

    # APIサーバを終了
    if [ api_server_flag="ON" ]; then
        ps ax | grep 'sam local start-api -p 4000' | grep -v grep | cut -f1 -d " " | xargs kill -9
    fi
}

@test "S3 Data Import Test" {
    # S3にファイルをアップロード(ローカルでテストできるように修正が必要)
    aws s3 cp tests/integrations/coupon.csv s3://coupon-api-dev/import-file/coupon.csv
    # SAM local 実行のため適当なEventを指定して実行
    actual=`sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/index/get_list_payload.json --env-vars environments/sam-local.json DataImportFunction`
    [[ `echo "${actual}" ` = `echo \"Done\"` ]]
}

@test "API Gateway Pagenation Request" {
    # ローカルAPI Gatewayサーバの起動
    if [ `lsof -i :4000` = "" ]; then
        sam local start-api -p 4000 -t template_coupon.yaml --docker-network ${docker_name} --env-vars environments/sam-local.json
        api_server_flag="ON"
    else
        echo "Please Stop the process of port 4000: port check ex(MaxOS). lsof -i :4000"
        api_server_flag="OFF"
    fi
    # PAGE_LIST_LIMITに設定した値以上のデータをDynamoDBに投入する
    aws s3 cp tests/integrations/coupon.csv s3://coupon-api-dev/import-file/coupon.csv
    sam local invoke --docker-network ${docker_name} -t template_coupon.yaml --event tests/integrations/index/get_list_payload.json --env-vars environments/sam-local.json DataImportFunction

    # １度目のデータ取得
    actual=`curl -H "Content-type: application/json" -X GET http://127.0.0.1:4000/resource-list | jq -r .LastEvaluatedKey`

    # URLエンコード
    nextval=`echo ${actual}| nkf -WwMQ | sed 's/=$//g' | tr = % | tr -d '\n'`
    # 2度目のデータ取得
    echo $nextval
    next_actual=`curl -H "Content-type: application/json" -X GET http://127.0.0.1:4000/resource-list/${nextval} | jq -r .ResponseMetadata.HTTPStatusCode`

    [[ `echo "${next_actual}" ` = `echo 200` ]]
    # APIサーバを終了
    if [ api_server_flag="ON" ]; then
        ps ax | grep 'sam local start-api -p 4000' | grep -v grep | cut -f1 -d " " | xargs kill -9
    fi
}
