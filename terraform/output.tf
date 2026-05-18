# Outputs (To be used by other repos)
output "sales_ecr_url" {
  value = aws_ecr_repository.sales.repository_url
}

output "sqs_arn" {
  value = aws_sqs_queue.ticket_queue.arn
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