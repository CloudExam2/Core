# Outputs (To be used by other repos)
output "sales_ecr_url" {
  value = aws_ecr_repository.sales.repository_url
}
output "sqs_arn" {
  value = aws_sqs_queue.ticket_queue.arn
}