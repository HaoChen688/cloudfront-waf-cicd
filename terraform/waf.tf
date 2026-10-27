resource "aws_wafv2_web_acl" "cloudfront" {
  provider    = aws.us_east_1
  name        = "${var.project}-${var.environment}-waf"
  description = "WAF for CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # ---------- 1. AWS 托管规则：常见漏洞 ----------
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # ---------- 2. SQL 注入 ----------
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 20
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # ---------- 3. 已知恶意 IP ----------
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 30
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IpReputation"
      sampled_requests_enabled   = true
    }
  }

  # ---------- 4. 速率限制（每 IP 5 分钟 2000 请求） ----------
  rule {
    name     = "RateLimitPerIP"
    priority = 40
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit                 = 2000
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  # ---------- 5. 自定义：拦截非中国/日本/美国 IP（按需） ----------
  rule {
    name     = "GeoBlockOthers"
    priority = 50
    action {
      block {}
    }
    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["CN", "JP", "US", "SG", "HK", "TW"]
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlock"
      sampled_requests_enabled   = true
    }
  }

  # ---------- 6. 拦截恶 User-Agent ----------
  rule {
    name     = "BlockBadUserAgents"
    priority = 60
    action {
      block {}
    }
    statement {
      byte_match_statement {
        search_string         = "sqlmap"
        positional_constraint = "CONTAINS"
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BadUA"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-waf"
  }
}

# WAF 日志（写入 CloudWatch Logs）
resource "aws_cloudwatch_log_group" "waf" {
  provider          = aws.us_east_1
  name              = "aws-waf-logs-${var.project}-${var.environment}"
  retention_in_days = 30
}

resource "aws_wafv2_web_acl_logging_configuration" "waf" {
  provider                = aws.us_east_1
  resource_arn            = aws_wafv2_web_acl.cloudfront.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  logging_filter {
    default_behavior = "DROP"
    filter {
      behavior    = "KEEP"
      requirement = "MEETS_ANY"
      condition {
        action_condition {
          action = "BLOCK"
        }
      }
    }
  }
}