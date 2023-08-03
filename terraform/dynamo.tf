resource "aws_dynamodb_table" "short_url" {
  name         = "ShortUrl"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "alias"

  attribute {
    name = "alias"
    type = "S"
  }

  attribute {
    name = "url"
    type = "S"
  }

  global_secondary_index {
    name     = "url"
    hash_key = "url"

    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = false
  }

  lifecycle {
    ignore_changes = [ttl, ]
  }
}
