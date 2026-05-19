# SQS Queue
resource "aws_sqs_queue" "ticket_queue" {
  name = "sales-ticket-queue"
}

resource "github_actions_organization_variable" "sqs_queue_url" {
  variable_name = "SQS_QUEUE_URL"
  visibility    = "all"
  value         = aws_sqs_queue.ticket_queue.url
}