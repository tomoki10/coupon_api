# coding: utf-8

import json
import boto3
from boto3.dynamodb.conditions import Key, Attr
from builtins import Exception
import os
import urllib.parse

# DynamoDB Localテスト用設定
DYNAMODB_ENDPOINT = os.getenv('DYNAMODB_ENDPOINT')
TABLE_NAME_INFO  = os.getenv('TABLE_NAME_INFO')
TABLE_NAME_TITLE = os.getenv('TABLE_NAME_TITLE')
DYNAMO = boto3.resource(
    'dynamodb',
    endpoint_url=DYNAMODB_ENDPOINT
)
DYNAMODB_TABLE_INFO = DYNAMO.Table(TABLE_NAME_INFO)
DYNAMODB_TABLE_TITLE = DYNAMO.Table(TABLE_NAME_TITLE)

def getTitleResource(event, context):
    try:
        # 転置インデックステーブルからIDを取得
        req_title_part = event['pathParameters']['titlePart']
        print(req_title_part)
        req_title_part = urllib.parse.unquote(req_title_part)
        print(req_title_part)
        title_response = DYNAMODB_TABLE_TITLE.query(
            KeyConditionExpression=Key('title_part').eq(req_title_part)
        )
        print(title_response)
        response = []
        for res in title_response['Items']:
            #print(res['coupon_info_id'])
            info_response = DYNAMODB_TABLE_INFO.query(
                KeyConditionExpression=Key('id').eq(res['coupon_info_id'])
            )
            print(info_response['Items'][0]['title'])
            response.append(info_response['Items'][0]['title'])

        return {
            'statusCode': 200,
            'headers': {
              'Content-Type': 'application/json; charset=utf-8'
            },
            'body': str(response).replace("\'","\""),
            'isBase64Encoded': False
        }
    except Exception as error:
        raise error
