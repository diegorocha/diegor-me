from os import environ

from boto3 import resource
from boto3.dynamodb.conditions import Key


def _get_table():
    table_name = environ.get('TABLE_NAME', 'ShortUrl')
    aws_region = environ.get('REGION', 'us-east-1')
    dynamodb = resource('dynamodb', region_name=aws_region)
    return dynamodb.Table(table_name)


def get_url_by_alias(alias):
    table = _get_table()
    response = table.query(
        KeyConditionExpression=Key('alias').eq(alias)
    )
    items = response['Items']
    if items:
        return items[0]['url']


def save_url(alias, url):
    table = _get_table()
    table.put_item(
        Item={
            "alias": alias,
            "url": url,
        },
        ReturnValues='NONE',
    )


def remove_url(alias):
    table = _get_table()
    table.delete_item(
        Key={
            "alias": alias,
        },
        ReturnValues='NONE',
    )
