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

resource "google_dns_record_set" "aws_certificate_dns_validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.resource_record_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }...
  }

  name         = each.value[0].name
  type         = each.value[0].type
  managed_zone = google_dns_managed_zone.zone.name
  ttl          = local.default_ttl
  rrdatas      = [each.value[0].record]
}

resource "aws_acm_certificate_validation" "aws_certificate_dns_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_acm_certificate.certificate.domain_validation_options : trim(record.resource_record_name, ".")]

  depends_on = [google_dns_record_set.aws_certificate_dns_validation]
}

resource "google_certificate_manager_certificate" "certificate" {
  name        = replace(local.app_name, ".", "-")
  description = "Certificate for all ${local.app_name} domains"
  scope       = "DEFAULT"
  managed {
    domains = local.google_certificate_domains_with_wildcards
    dns_authorizations = [
      for authorization in google_certificate_manager_dns_authorization.certificate : authorization.id
    ]
  }
}

resource "google_certificate_manager_dns_authorization" "certificate" {
  for_each = toset(local.certificate_domains)

  name        = "certificate-${replace(each.key, ".", "-")}"
  description = "Certificate validation for ${each.key} domain"
  domain      = each.key
}

resource "google_dns_record_set" "gcp_certificate_authorization" {
  for_each = toset(local.certificate_domains)

  name = google_certificate_manager_dns_authorization.certificate[each.key].dns_resource_record[0].name
  type = google_certificate_manager_dns_authorization.certificate[each.key].dns_resource_record[0].type
  ttl  = local.default_ttl

  managed_zone = replace(google_certificate_manager_dns_authorization.certificate[each.key].domain, ".", "-")

  rrdatas = [google_certificate_manager_dns_authorization.certificate[each.key].dns_resource_record[0].data]
}

resource "google_certificate_manager_certificate_map" "certificate" {
  name        = replace(local.app_name, ".", "-")
  description = "Map for all ${local.app_name} domains"
  labels = {
    "terraform" : true,
    "acc-test" : true,
  }
}

resource "google_certificate_manager_certificate_map_entry" "certificate" {
  name        = replace(local.app_name, ".", "-")
  description = "Map entry for all ${local.app_name} domains"
  map         = google_certificate_manager_certificate_map.certificate.name
  labels = {
    "terraform" : true,
    "acc-test" : true,
  }
  certificates = [google_certificate_manager_certificate.certificate.id]
  matcher      = "PRIMARY"
}
