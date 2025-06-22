locals {
  default_ttl = 1800
  mx_value = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 aspmx2.googlemail.com.",
    "10 aspmx3.googlemail.com.",
  ]
}

resource "aws_route53_zone" "zone" {
  name = local.domain_name
}

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = local.domain_name
  type    = "MX"
  records = local.mx_value
  ttl     = local.default_ttl
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = local.domain_name
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.api.domain_name
    zone_id                = aws_cloudfront_distribution.api.hosted_zone_id
  }
}

output "dns_zone" {
  value = {
    tostring(local.domain_name) = aws_route53_zone.zone.name_servers
  }
}
