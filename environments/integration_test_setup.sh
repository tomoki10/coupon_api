#!/bin/sh

# ローカルテスト用のDockerを起動
docker-compose -f ../docker-compose.yaml up -d

# 擬似テーブル作成(templateと一緒に修正が必要)
aws --endpoint-url=http://localhost:4569 dynamodb \
    create-table --table-name  COUPON_INFO \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
