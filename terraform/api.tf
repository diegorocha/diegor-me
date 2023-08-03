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

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
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
    allowed_methods        = ["GET", "HEAD"]
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
