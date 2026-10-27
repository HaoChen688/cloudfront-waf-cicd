resource "aws_sns_topic" "alarms" {
  name = "${var.project}-${var.environment}-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudFront 5xx 错误率
resource "aws_cloudwatch_metric_alarm" "cf_5xx" {
  alarm_name          = "${var.project}-${var.environment}-cf-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "CloudFront 5xx 错误率 > 5%"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    DistributionId = aws_cloudfront_distribution.site.id
    Region         = "Global"
  }
}

# WAF 拦截量突增
resource "aws_cloudwatch_metric_alarm" "waf_blocked" {
  provider            = aws.us_east_1
  alarm_name          = "${var.project}-${var.environment}-waf-blocked"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "WAF 5 分钟拦截 > 1000，疑似攻击"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.cloudfront.name
    Region = "CloudFront"
    Rule   = "ALL"
  }
}

# 缓存命中率低告警
resource "aws_cloudwatch_metric_alarm" "cache_hit" {
  alarm_name          = "${var.project}-${var.environment}-cache-hit-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "缓存命中率 < 80%"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DistributionId = aws_cloudfront_distribution.site.id
    Region         = "Global"
  }
}