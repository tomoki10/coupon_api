# coding: utf-8

import json
import boto3
from boto3.dynamodb.conditions import Key, Attr
from builtins import Exception
import os

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

# 一回のリクエストで取得するデータの上限
PAGE_LIST_LIMIT = 5

def getResource(event, context):
    try:
        id = event['pathParameters']['resourceId']
        print(DYNAMO)
        dynamo_response = DYNAMODB_TABLE_INFO.get_item(
            Key={
                "id": id
            }
        )
        return {
            'statusCode': 200,
            'headers': {
              'Content-Type': 'application/json; charset=utf-8'
            },
            'body': str(dynamo_response['Item']).replace("\'","\""),
            'isBase64Encoded': False
        }
    except Exception as error:
        id = event['pathParameters']['resourceId']
        return {
            'statusCode': 404,
            'headers': {
              'Content-Type': 'application/json; charset=utf-8'
            },
            'body': "Not Found. The requested id "+str(id)+" is not found",
            'isBase64Encoded': False
        }
        raise error

def getListResource(event, context):
    try:
        param = {
            'IndexName': 'update_at_index',
            'KeyConditionExpression': Key('coupon_type').eq('org_aws'),
            'ScanIndexForward': False,
            'Limit': PAGE_LIST_LIMIT
        }
        path_param = event['pathParameters']
        if path_param != None:
            input_key = json.loads(
                event['pathParameters']['lastEvaluatedKey'].replace("\'","\"")
            )
            param['ExclusiveStartKey'] = input_key
        #アンパックして検索
        dynamo_response = DYNAMODB_TABLE_INFO.query(**param)

        return {
            'statusCode': 200,
            'headers': {
              'Content-Type': 'application/json; charset=utf-8'
            },
            'body': str(dynamo_response).replace("\'","\""),
            'isBase64Encoded': False
        }
    except Exception as error:
        return {
            'statusCode': 404,
            'headers': {
              'Content-Type': 'application/json; charset=utf-8'
            },
            'body': "Not Found. The requested data is not found",
            'isBase64Encoded': False
        }
        raise error
