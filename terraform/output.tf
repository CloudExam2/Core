# Outputs (To be used by other repos)
output "sales_ecr_url" {
  value = aws_ecr_repository.sales.repository_url
}

output "sqs_arn" {
  value = aws_sqs_queue.ticket_queue.arn
}

output "sqs_queue_url" {
  description = "Sales publishes new-sale JSON here; Notification Lambda consumes via event source mapping"
  value       = aws_sqs_queue.ticket_queue.url
}

# Shared network — consumed by Catalog (and others) via terraform_remote_state
output "vpc_id" {
  description = "ID of the shared VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (two AZs); use [0] for single-AZ EC2, all for RDS subnet groups"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "catalog_proxy_path" {
  description = "Path prefix proxied to Catalog when catalog_backend_url is set"
  value       = "/catalog/{proxy+}"
}

output "catalog_log_group_name" {
  description = "CloudWatch Logs group for Catalog Docker/uvicorn output"
  value       = aws_cloudwatch_log_group.catalog.name
}

output "sales_log_group_name" {
  description = "CloudWatch Logs group for Sales Docker/uvicorn output"
  value       = aws_cloudwatch_log_group.sales.name
}

output "ec2_metrics_dashboard_name" {
  description = "CloudWatch dashboard — EC2 CPU + NetworkIn (both) + HTTP % (Catalog, Sales, Sales→Catalog)"
  value       = aws_cloudwatch_dashboard.exam2_ec2.dashboard_name
}

output "ec2_metrics_dashboard_url" {
  description = "Console link to the Exam2 EC2 metrics dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards/dashboard/Exam2-EC2-Overview"
}

output "dashboard_catalog_instance_id" {
  description = "Catalog EC2 id wired into the metrics dashboard"
  value       = try(data.terraform_remote_state.catalog.outputs.ec2_catalog_id, "")
}

output "dashboard_sales_instance_id" {
  description = "Sales EC2 id wired into the metrics dashboard"
  value       = try(data.terraform_remote_state.sales.outputs.ec2_sales_id, "")
}

output "cpu_alerts_sns_topic_arn" {
  description = "SNS topic for CPU > 70% alarms (confirm email subscription once)"
  value       = aws_sns_topic.cpu_alerts.arn
}