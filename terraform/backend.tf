terraform {
  backend "s3" {
    bucket         = "mycompany-tfstate-20261027"
    key            = "cloudfront-waf-cicd/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}