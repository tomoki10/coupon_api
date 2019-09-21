import json
import os
import ctypes
import sys
import boto3
from boto3.dynamodb.conditions import Key, Attr

def putTitle(event, context):
    res_body="test"
    return {
        'body': res_body
    }
