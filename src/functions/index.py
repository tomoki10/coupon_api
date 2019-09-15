# coding: utf-8

import json
import boto3
from boto3.dynamodb.conditions import Key, Attr
from builtins import Exception
import os

DYNAMODB_ENDPOINT = os.getenv('DYNAMODB_ENDPOINT')
TABLE_NAME = os.getenv('TABLE_NAME')
DYNAMO = boto3.resource(
    'dynamodb',
    endpoint_url=DYNAMODB_ENDPOINT
)
DYNAMODB_TABLE = DYNAMO.Table(TABLE_NAME)

def get(event, context):
    try:
        id = event['pathParameters']['resourceId']
        print(DYNAMO)
        dynamo_response = DYNAMODB_TABLE.get_item(
            Key={
                "id": id
            }
        )
        return {
            'statusCode': 200,
            'body': json.dumps(dynamo_response['Item'])
        }
    except Exception as error:
        raise error
