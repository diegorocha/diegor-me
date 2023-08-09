from json import loads
from os import environ
from urllib.parse import parse_qsl

from dynamo import get_url_by_alias, remove_url, save_url


def json_parser(body):
    return loads(body)


def url_encoded_parser(body):
    return dict(parse_qsl(body, strict_parsing=True))


def parse_alias(path):
    if path.startswith('/') and path != "/":
        return path[1:]
    return path


def body_validation(data, required_filds):
    errors = []
    for field in required_filds:
        if field not in data:
            errors.append(f"Field '{field}' is required")
    return errors


def empty_response_with_status(status):
    return {
        "isBase64Encoded": False,
        "statusCode": status,
        "headers": {},
        "body": ""
    }


def get(**args):
    alias = parse_alias(args["path"])
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


def post(**args):
    alias = parse_alias(args["path"])
    content_types_parsers = {
        "application/json": json_parser,
        "application/x-www-form-urlencoded": url_encoded_parser,
    }
    required_filds = [
        "url"
    ]

    content_type = args["headers"].get("Content-Type") or args["headers"].get("content-type")
    if content_type not in content_types_parsers:
        return empty_response_with_status(415)
    data = content_types_parsers[content_type](args["body"])

    field_errors = body_validation(data, required_filds)

    if field_errors:
        body = ",".join(field_errors)
        return {
            "isBase64Encoded": False,
            "statusCode": 400,
            "headers": {
                "content-type": "text/plain",
                "content-length": len(body),
            },
            "body": body
        }

    url = data["url"]
    save_url(alias, url)
    return empty_response_with_status(204)


def delete(**args):
    alias = parse_alias(args["path"])
    remove_url(alias)
    return empty_response_with_status(204)


def method_not_allowed(**args):
    return empty_response_with_status(405)


def handler(event, _):
    methods_handlers = {
        "GET": get,
        "POST": post,
        "DELETE": delete,
    }
    method = event["httpMethod"]
    method_args = {
        "path": event["path"],
        "headers": event.get("headers", {}),
        "body": event.get("body", "")
    }
    method_handler = methods_handlers.get(method, method_not_allowed)
    response = method_handler(**method_args)
    return response


if __name__ == '__main__':
    data_sample = {
        "application/json": '{"url": "https://example.org/"}',
        "application/x-www-form-urlencoded": 'url=http%3A%2F%2Fexample.org%2F',
    }
    content_type = ""
    sample_event = {
        "body": data_sample[content_type],
        "headers": {"content-type": content_type},
        "httpMethod": "POST",
        "path": "/foo",
    }
    print(handler(sample_event, None))
