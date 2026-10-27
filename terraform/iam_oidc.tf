resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "gh_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}",
        "repo:${var.github_repo}:pull_request"
      ]
    }
  }
}

resource "aws_iam_role" "gh_actions" {
  name               = "${var.project}-${var.environment}-gh-actions"
  assume_role_policy = data.aws_iam_policy_document.gh_trust.json
}

data "aws_iam_policy_document" "gh_perms" {
  # Terraform state 读写
  statement {
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::mycompany-tfstate", "arn:aws:s3:::mycompany-tfstate/*"]
  }
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:us-east-1:*:table/terraform-locks"]
  }
  # 站点部署
  statement {
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [aws_s3_bucket.site.arn, "${aws_s3_bucket.site.arn}/*"]
  }
  statement {
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation", "cloudfront:ListInvalidations"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
  # Terraform 管理其余资源
  statement {
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "gh_actions" {
  role   = aws_iam_role.gh_actions.id
  policy = data.aws_iam_policy_document.gh_perms.json
}