locals {
  certificate_domains = [local.domain_name]
  dns_validations = distinct([
    for dvo in aws_acm_certificate.certificate.domain_validation_options : {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  ])
  google_certificate_domains_with_wildcards = [
    for pair in setproduct(["", "*."], local.certificate_domains) : join("", pair)
  ]
}

resource "aws_acm_certificate" "certificate" {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "aws_certificate_dns_validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.resource_record_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }...
  }

  zone_id = aws_route53_zone.zone.zone_id
  name    = each.value[0].name
  type    = each.value[0].type
  records = [each.value[0].record]
  ttl     = local.default_ttl
}

resource "aws_acm_certificate_validation" "aws_certificate_dns_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_acm_certificate.certificate.domain_validation_options : trim(record.resource_record_name, ".")]

  depends_on = [aws_route53_record.aws_certificate_dns_validation]
}
