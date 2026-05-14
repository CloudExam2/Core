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

output "api_gateway_invoke_url" {
  description = "Invoke URL for prod stage (GET / shows placeholder until catalog_backend_url is set)"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "catalog_proxy_path" {
  description = "Path prefix proxied to Catalog when catalog_backend_url is set"
  value       = "/catalog/{proxy+}"
}