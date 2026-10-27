terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# 主区域：WAF、S3、Route53
provider "aws" {
  region = var.aws_region
}

# CloudFront 证书必须 us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}