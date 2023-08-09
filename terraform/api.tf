locals {
  caching_disabled = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  path_regex       = "(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?(?P<path>[^?#]*)(?:\\?(?P<query>[^#]*))?(?:#(?P<fragment>.*))?"
  stage_urlparse   = regex(local.path_regex, aws_api_gateway_stage.stage.invoke_url)
}

resource "aws_api_gateway_rest_api" "api" {
  name        = local.app_name
  description = "${local.app_name} service"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "api_authorizer" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  provider_arns = [aws_cognito_user_pool.user_pool.arn]
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_root_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "proxy_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "proxy_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id
}

resource "aws_api_gateway_method" "proxy_delete" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id
}

resource "aws_api_gateway_integration" "lambda_root_get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy_root_get.resource_id
  http_method = aws_api_gateway_method.proxy_root_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy_get.resource_id
  http_method = aws_api_gateway_method.proxy_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy_post.resource_id
  http_method = aws_api_gateway_method.proxy_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_delete" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy_delete.resource_id
  http_method = aws_api_gateway_method.proxy_delete.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_resource.proxy,
      aws_api_gateway_method.proxy_root_get,
      aws_api_gateway_method.proxy_get,
      aws_api_gateway_method.proxy_post,
      aws_api_gateway_method.proxy_delete,
      aws_api_gateway_integration.lambda_root_get,
      aws_api_gateway_integration.lambda_get,
      aws_api_gateway_integration.lambda_post,
      aws_api_gateway_integration.lambda_delete,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_root_get.id,
      aws_api_gateway_method.proxy_get.id,
      aws_api_gateway_method.proxy_post.id,
      aws_api_gateway_method.proxy_delete.id,
      aws_api_gateway_integration.lambda_root_get.id,
      aws_api_gateway_integration.lambda_get.id,
      aws_api_gateway_integration.lambda_post.id,
      aws_api_gateway_integration.lambda_delete.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prd"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_cloudfront_distribution" "api" {
  origin {
    origin_id   = aws_api_gateway_stage.stage.id
    domain_name = local.stage_urlparse.authority
    origin_path = local.stage_urlparse.path
    custom_origin_config {
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      https_port             = 443
      http_port              = 80
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution for ${local.domain_name}"
  default_root_object = "/"

  aliases = concat([aws_acm_certificate.certificate.domain_name], tolist(aws_acm_certificate.certificate.subject_alternative_names))

  default_cache_behavior {
    cache_policy_id        = local.caching_disabled
    allowed_methods        = ["GET", "HEAD", "POST", "DELETE", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_api_gateway_stage.stage.id
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
}

resource "google_dns_record_set" "api" {
  name         = google_dns_managed_zone.zone.dns_name
  type         = "ALIAS"
  ttl          = 600
  managed_zone = google_dns_managed_zone.zone.name
  rrdatas      = ["${aws_cloudfront_distribution.api.domain_name}."]
}
