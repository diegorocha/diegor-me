from os import environ

from dynamo import get_url_by_alias


def handler(event, _):
    alias = event["path"]
    if alias.startswith('/') and alias != "/":
        alias = alias[1:]
    url = get_url_by_alias(alias)
    if not url:
        url = environ.get('NOT_FOUND_URL', 'https://error.diegorocha.com.br/')
    response = {
        "isBase64Encoded": False,
        "statusCode": 302,
        "headers": {
            "location": url,
        },
        "body": ""
    }
    return response


if __name__ == '__main__':
    sample_event = {
        "path": "/foo",
    }
    print(handler(sample_event, None))
