locals {
  cognito_name = replace(local.app_name, ".", "-")
}

resource "aws_cognito_user_pool" "user_pool" {
  name                       = local.cognito_name
  email_verification_subject = "Your Verification Code"
  email_verification_message = "Please use the following code: {####}"
  alias_attributes           = ["email"]
  auto_verified_attributes   = ["email"]

  password_policy {
    minimum_length                   = 6
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  username_configuration {
    case_sensitive = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 7
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = true

    string_attribute_constraints {
      min_length = 3
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                = local.cognito_name
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  user_pool_id = aws_cognito_user_pool.user_pool.id
}

output "user_pool_client" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}
