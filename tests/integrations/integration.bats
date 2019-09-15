#!/usr/bin/env bats

setup() {
    echo "setup"
    # Docker名を指定(docker_composeファイルの場所と連動)
    docker_name='coupon_api_default'
}
 
teardown() {
    echo "teardown"
}
 
@test "DynamoDB Get Function response the correct item" {
    # テストデータを用意
    data='{
        "id": {"S": "test-id"},
        "title": {"S": "test-title"},
        "text": {"S": "xxxxxxxxxxxxxxx"} }'

    expected=`echo "${data}" | jq -r .`
    echo $DOCKER_NAME
    # テストデータを LocalStack の DynamoDB に投入
    aws --endpoint-url=http://localhost:4569 dynamodb put-item --table-name COUPON_INFO --item "${data}"
 
    # SAM Local を起動し、Lambda Function の出力を得る
    actual=`sam local invoke --docker-network ${docker_name} -t pkg-template-coupon.yaml --event tests/integrations/get_payload.json --env-vars environments/sam-local.json GetFunction | jq -r .body `

    #テスト用コマンド
    #echo `echo "${actual}"` 

    # 出力内容をテスト
    [ `echo "${actual}" | jq .id` = `echo "${expected}" | jq .id.S` ]
    [ `echo "${actual}" | jq .title` = `echo "${expected}" | jq .title.S` ]
    [ `echo "${actual}" | jq .text` = `echo "${expected}" | jq .text.S` ]
}
