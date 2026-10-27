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
  description = "GitHub 仓库完整路径 (owner/repo)"
  type        = string
  default     = "HaoChen688/cloudfront-waf-cicd"
}

variable "github_owner_id" {
  description = "GitHub 用户或组织的数字 ID"
  type        = string
  default     = "42665530" # 替换为你的实际 ID
}

variable "github_repo_id" {
  description = "GitHub 仓库的数字 ID"
  type        = string
  default     = "1435386396" # 替换为你的实际 ID
}

variable "github_environment" {
  description = "GitHub Actions 环境名称"
  type        = string
  default     = "production"
}

variable "github_branch" {
  description = "允许部署的分支"
  type        = string
  default     = "main"
}

variable "alarm_email" {
  default = "ops@example.com"
}