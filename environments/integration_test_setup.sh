#!/bin/sh

cd ..

# ローカルテスト用のDockerを起動
docker-compose -f docker-compose.yaml up -d

mkdir deploy
rsync -a src deploy --exclude 'layer'
mkdir deploylayer
cp -R src/layer/* deploylayer
cp -R src/layer/. deploylayer

# 擬似テーブル作成(templateと一緒に修正が必要)
aws --endpoint-url=http://localhost:4569 dynamodb \
    create-table --table-name  COUPON_INFO \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
        AttributeName=updated_at,AttributeType=S \
        AttributeName=coupon_type,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --global-secondary-indexes IndexName=update_at_index,KeySchema="[{AttributeName=coupon_type,KeyType=HASH},{AttributeName=updated_at,KeyType=RANGE}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5}"

# 擬似の転置インデックステーブルを作成
aws --endpoint-url=http://localhost:4569 dynamodb \
    create-table --table-name  COUPON_TITLE \
    --attribute-definitions \
        AttributeName=title_part,AttributeType=S \
        AttributeName=coupon_info_id,AttributeType=S \
    --key-schema \
        AttributeName=title_part,KeyType=HASH \
        AttributeName=coupon_info_id,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --global-secondary-indexes IndexName=coupon_info_id_index,KeySchema="[{AttributeName=coupon_info_id,KeyType=HASH},{AttributeName=title_part,KeyType=RANGE}],Projection={ProjectionType=KEYS_ONLY},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5}"

# ローカルのDynamoDB確認用
export DYNAMO_ENDPOINT=http://localhost:4569
dynamodb-admin
