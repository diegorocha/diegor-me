from os import environ

from boto3 import resource
from boto3.dynamodb.conditions import Key


def get_url_by_alias(alias):
    table_name = environ.get('TABLE_NAME', 'ShortUrl')
    aws_region = environ.get('REGION', 'us-east-1')
    dynamodb = resource('dynamodb', region_name=aws_region)
    table = dynamodb.Table(table_name)
    response = table.query(
        KeyConditionExpression=Key('alias').eq(alias)
    )
    items = response['Items']
    if items:
        return items[0]['url']
