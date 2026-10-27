variable "aws_region" {
  default = "us-east-1"
}

variable "project" {
  default = "cf-waf-cicd"
}

variable "environment" {
  default = "prod"
}

variable "domain_name" {
  description = "已在 Route53 托管的域名"
  default     = "mymywebsite.click"
}

variable "github_repo" {
  description = "owner/repo，用于 OIDC 信任"
  default     = "your-org/your-repo"
}

variable "github_branch" {
  default = "main"
}

variable "alarm_email" {
  default = "ops@example.com"
}