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

variable "github_org" {
  type    = string
  default = "HaoChen688"
}

variable "github_repo" {
  type    = string
  default = "cloudfront-waf-cicd"
}

variable "github_owner_id" {
  type        = string
  default     = "42665530" # public 仓库必须带 owner id
  description = "GitHub owner numeric ID"
}

variable "github_repo_id" {
  type        = string
  default     = "1435386396" # public 仓库必须带 repo id
  description = "GitHub repo numeric ID"
}

variable "github_branch" {
  default = "main"
}

variable "alarm_email" {
  default = "ops@example.com"
}