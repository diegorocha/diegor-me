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

resource "google_dns_managed_zone" "zone" {
  name     = replace(local.domain_name, ".", "-")
  dns_name = "${local.domain_name}."
}

resource "google_dns_record_set" "mx" {
  name         = google_dns_managed_zone.zone.dns_name
  type         = "MX"
  ttl          = local.default_ttl
  managed_zone = google_dns_managed_zone.zone.name
  rrdatas      = local.mx_value
}

output "dns_zone" {
  value = {
    tostring(local.domain_name) = google_dns_managed_zone.zone.name_servers
  }
}
