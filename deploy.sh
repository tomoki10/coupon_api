#!/usr/bin/env bash

item='coupon'
bucket='coupon-api-dev'

mkdir deploy
cp -R src deploy

# CloudFormation テンプレート作成
aws cloudformation package \
    --template-file template_${item}.yaml \
    --s3-bucket ${bucket} \
    --output-template-file pkg-template-${item}.yaml

# CloudFormation によるデプロイ
aws cloudformation deploy \
    --template-file pkg-template-${item}.yaml \
    --stack-name ${item}-api  \
    --capabilities CAPABILITY_IAM

rm -r deploy/
