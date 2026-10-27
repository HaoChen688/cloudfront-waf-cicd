# ==============================================================================
# 1. OIDC Provider (GitHub Actions)
# ==============================================================================
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # GitHub 官方根 CA 和中间 CA 指纹
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# ==============================================================================
# 2. 信任策略 (Trust Policy)
# ==============================================================================
data "aws_iam_policy_document" "gh_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # 验证 audience
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # 验证 sub (Public 仓库 + 指定 Environment 格式)
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${split("/", var.github_repo)[0]}@${var.github_owner_id}/${split("/", var.github_repo)[1]}@${var.github_repo_id}:environment:${var.github_environment}"
      ]
    }
  }
}

resource "aws_iam_role" "cf-waf-cicd-prod-gh-actions" {
  name               = "cf-waf-cicd-prod-gh-actions"
  description        = "Role assumed by GitHub Actions via OIDC for CloudCDN deployment"
  assume_role_policy = data.aws_iam_policy_document.gh_trust.json
}

# ==============================================================================
# 3. 权限策略 (Permissions Policy) - 遵循最小化原则
# ==============================================================================
data "aws_iam_policy_document" "gh_perms" {

  # ----------------------------------------------------------------------------
  # Terraform State 存储与锁 (已更新为 mymywebsite)
  # ----------------------------------------------------------------------------
  statement {
    sid       = "TerraformStateS3Access"
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::mymywebsite-tfstate-20261027", "arn:aws:s3:::mymywebsite-tfstate-20261027/*"]
  }

  statement {
    sid     = "TerraformLockDynamoDBAccess"
    actions = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    # 建议同步修改为 mymywebsite-tflocks (如果你在 AWS 里创建的锁表也叫这个名字的话)
    resources = ["arn:aws:dynamodb:us-east-1:*:table/mymywebsite-tflocks"]
  }

  # ----------------------------------------------------------------------------
  # CI/CD 部署专用权限 (Sync S3 & Invalidate CDN)
  # ----------------------------------------------------------------------------
  statement {
    sid       = "SiteDeploymentS3Access"
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::cloudcdn-enterprise-site-*", "arn:aws:s3:::cloudcdn-enterprise-site-*/*"]
  }

  statement {
    sid       = "CloudFrontInvalidationAccess"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation", "cloudfront:ListInvalidations"]
    resources = ["arn:aws:cloudfront::*:distribution/*"]
  }

  # ----------------------------------------------------------------------------
  # Terraform 资源管理权限 (精确到具体服务)
  # ----------------------------------------------------------------------------
  statement {
    sid = "ManageCloudFrontAndWAF"
    actions = [
      "cloudfront:CreateDistribution", "cloudfront:UpdateDistribution", "cloudfront:DeleteDistribution",
      "cloudfront:GetDistribution", "cloudfront:TagResource", "cloudfront:ListTagsForResource",
      "cloudfront:CreateOriginAccessControl", "cloudfront:UpdateOriginAccessControl", "cloudfront:DeleteOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:CreateResponseHeadersPolicy", "cloudfront:UpdateResponseHeadersPolicy", "cloudfront:DeleteResponseHeadersPolicy",
      "cloudfront:GetResponseHeadersPolicy",
      "wafv2:CreateWebACL", "wafv2:UpdateWebACL", "wafv2:DeleteWebACL", "wafv2:GetWebACL", "wafv2:ListWebACLs",
      "wafv2:AssociateWebACL", "wafv2:DisassociateWebACL", "wafv2:GetWebACLForResource"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ManageACMandRoute53"
    actions = [
      "acm:RequestCertificate", "acm:DescribeCertificate", "acm:DeleteCertificate",
      "acm:AddTagsToCertificate", "acm:ListTagsForCertificate", "acm:GetCertificate",
      "route53:GetHostedZone", "route53:ListHostedZones", "route53:ListHostedZonesByName",
      "route53:ChangeResourceRecordSets", "route53:GetChange", "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ManageS3Buckets"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket", "s3:PutBucketPolicy", "s3:GetBucketPolicy", "s3:DeleteBucketPolicy",
      "s3:PutBucketVersioning", "s3:GetBucketVersioning",
      "s3:PutBucketPublicAccessBlock", "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketEncryption", "s3:GetBucketEncryption",
      "s3:GetBucket*", "s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
      "s3:PutBucketTagging", "s3:GetBucketTagging"
    ]
    resources = ["*"]
  }
}

# ==============================================================================
# 4. 将策略附加到 IAM Role
# ==============================================================================
resource "aws_iam_policy" "gh_perms" {
  name        = "cf-waf-cicd-prod-gh-actions-policy"
  description = "Permissions for GitHub Actions to deploy CloudCDN"
  policy      = data.aws_iam_policy_document.gh_perms.json
}

resource "aws_iam_role_policy_attachment" "gh_perms_attach" {
  role       = aws_iam_role.cf-waf-cicd-prod-gh-actions.name
  policy_arn = aws_iam_policy.gh_perms.arn
}

# ==============================================================================
# 5. Output (输出 Role ARN 供 GitHub Actions 使用)
# ==============================================================================
output "github_actions_role_arn" {
  description = "ARN of the IAM role to be assumed by GitHub Actions"
  value       = aws_iam_role.cf-waf-cicd-prod-gh-actions.arn
}