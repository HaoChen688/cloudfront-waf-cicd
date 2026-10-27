output "site_url" {
  value = "https://${var.domain_name}/"
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "waf_acl_arn" {
  value = aws_wafv2_web_acl.cloudfront.arn
}

output "gh_actions_role_arn" {
  value = aws_iam_role.gh_actions.arn
}