# S3 Bucket for Tickets
resource "aws_s3_bucket" "tickets" {
  bucket = "iteso-tickets-377871695195" # Must be globally unique
}

resource "github_actions_organization_variable" "bucket_name" {
  variable_name = "TICKETS_BUCKET_NAME"
  visibility    = "all"
  value         = aws_s3_bucket.tickets.id
}