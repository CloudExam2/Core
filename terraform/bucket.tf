# Generates a random suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket with dynamic name
resource "aws_s3_bucket" "tickets" {
  # This results in something like: iteso-tickets-a1b2c3d4
  bucket = "iteso-tickets-${lower(random_id.bucket_suffix.hex)}"
  
  force_destroy = true # Allows deleting the bucket even if it has files
}

# Saves the dynamic name to GitHub so other repos can read it
resource "github_actions_organization_variable" "bucket_name" {
  variable_name = "TICKETS_BUCKET_NAME"
  visibility    = "all"
  value         = aws_s3_bucket.tickets.id
}