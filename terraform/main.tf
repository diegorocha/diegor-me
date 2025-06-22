terraform {
  required_version = "1.10.5"
  required_providers {
    aws = {
      version = "5.65.0"
    }
  }
  backend "s3" {
    bucket               = "diegor-terraform"
    workspace_key_prefix = ""
    key                  = "diegor.me/terraform.tfstate"
    region               = "us-east-1"
  }
}

provider "aws" {
  region = local.aws_region
  default_tags {
    tags = {
      service = local.app_name
    }
  }
}

locals {
  app_name      = "diegor.me"
  domain_name   = "diegor.me"
  aws_region    = "us-east-1"
  not_found_url = "https://error.diegorocha.com.br"
}
