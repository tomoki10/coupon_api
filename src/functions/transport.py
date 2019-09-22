import json
import os
import ctypes
import sys
import boto3
from boto3.dynamodb.types import TypeDeserializer
from boto3.dynamodb.conditions import Key, Attr

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

# Dictionary変換用
deser = TypeDeserializer()
# Mecab のインストール
libdir = '/opt/.mecab/lib/'
libmecab = ctypes.cdll.LoadLibrary(os.path.join(libdir, 'libmecab.so'))
sys.path.append('/opt')
import MeCab
tagger = MeCab.Tagger ('-Ochasen')

def putTitle(event, context):
    for record in event['Records']:
        new_img = record['dynamodb'].get('NewImage')
        new_images = {}
        if new_img:
            for key in new_img:
                new_images[key] = deser.deserialize(new_img[key])
        if (record['eventName'] == 'INSERT'):
            print(new_images['id'])
            insert_new_item(new_images)
        elif (record['eventName'] == 'REMOVE'):
            remove_item(record['dynamodb']['Keys']['id']['S'])
        elif (record['eventName'] == 'MODIFY'):
            remove_item(record['dynamodb']['Keys']['id']['S'])
            insert_new_item(new_images)
    return 'Done'

def insert_new_item(new_images):
    mecab_results = morphological_analysis_text(new_images)
    # 文字ごとにDynamoDBに投入する
    for mecab_result in mecab_results.split("\n")[:-2]:
        response = DYNAMODB_TABLE_TITLE.put_item(
            Item={
                "title_part": mecab_result.split("\t")[0],
                "coupon_info_id": new_images['id']
            }
        )

def morphological_analysis_text(new_images):
    # 文字の切り出し
    return tagger.parse(new_images['title'])

def remove_item(id):
    res = DYNAMODB_TABLE_TITLE.query(
        IndexName='coupon_info_id_index',
        KeyConditionExpression=Key('coupon_info_id').eq(id)
    )
    print('res: ', res)
    for item in res['Items']:
        print('item: ', item)
        res = DYNAMODB_TABLE_TITLE.delete_item(
            Key = {
                'title_part': item['title_part'],
                'coupon_info_id': item['coupon_info_id']
            }
        )
