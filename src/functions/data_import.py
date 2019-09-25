# coding: utf-8

import json
import boto3
import csv
import os
import time
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

BUCKET_NAME= "coupon-api-dev"
S3_PREFIX_IMP_BEF = "import-file/"
S3_PREFIX_IMP_AFT = "import-file-done/"

def dataImport(event, context):
    s3_client = boto3.client('s3')
    s3_file_lists = s3_client.list_objects_v2(Bucket=BUCKET_NAME, Prefix=S3_PREFIX_IMP_BEF)
    # フィールド定義
    fieldnames = ("id","title","descriptive_text","coupon_url",
        "coupon_qr_url","updated_at","coupon_type")

    # jsonlistにCSVの各行を格納
    jsonlist = []
    for filename in s3_file_lists['Contents']:
        if 0 != filename['Size']:
            #データ取得
            file = s3_client.get_object(Bucket=BUCKET_NAME,Key=filename['Key'])
            tmp_csv = file['Body'].read().decode('utf-8')
            lines = tmp_csv.split("\n")
            print(filename['Key'])
            # バケット名/ファイル名の文字列からファイル名のみ抜き出す
            copy_after_filename = filename['Key'].split("/")[1]
            # ファイルを取り込み後フォルダに移動
            s3_client.copy_object(Bucket=BUCKET_NAME,
                Key=S3_PREFIX_IMP_AFT+copy_after_filename,
                CopySource={'Bucket': BUCKET_NAME, 'Key': filename['Key']})
            s3_client.delete_object(Bucket=BUCKET_NAME, Key=filename['Key'])
            #読み込み用にデータを変換
            for row in csv.DictReader(lines,fieldnames):
                # ソート用の日付を設定(タイムゾーンでのずれが起きないようUNIX時間を使用)
                row.update({'updated_at':str(int(time.time()))})
                # ページングでするための共通項目PartitionKeyを追加
                row.update({'coupon_type':'org_aws'})
                jsonlist.append(row)
    # レコードを追加
    for put_row in jsonlist:
        DYNAMODB_TABLE_INFO.put_item(Item=put_row)
    return 'Done'
