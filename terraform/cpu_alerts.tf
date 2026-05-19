# CPU > 70% → SNS email (confirm subscription in inbox after first Core apply).

variable "alert_email" {
  description = "Email for CPU high alerts"
  type        = string
  default     = "inaki.medina@gmail.com"
}

resource "aws_sns_topic" "cpu_alerts" {
  name = "exam2-cpu-alerts"
}

resource "aws_sns_topic_subscription" "cpu_alerts_email" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  catalog_alarm_id = try(data.terraform_remote_state.catalog.outputs.ec2_catalog_id, "")
  sales_alarm_id   = try(data.terraform_remote_state.sales.outputs.ec2_sales_id, "")
}

resource "aws_cloudwatch_metric_alarm" "catalog_cpu_high" {
  count = local.catalog_alarm_id != "" ? 1 : 0

  alarm_name          = "exam2-catalog-cpu-high"
  alarm_description   = "Catalog EC2 CPU > 70%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 10
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = local.catalog_alarm_id
  }

  alarm_actions = [aws_sns_topic.cpu_alerts.arn]
  ok_actions    = [aws_sns_topic.cpu_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "sales_cpu_high" {
  count = local.sales_alarm_id != "" ? 1 : 0

  alarm_name          = "exam2-sales-cpu-high"
  alarm_description   = "Sales EC2 CPU > 70%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 10
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = local.sales_alarm_id
  }

  alarm_actions = [aws_sns_topic.cpu_alerts.arn]
  ok_actions    = [aws_sns_topic.cpu_alerts.arn]
}
