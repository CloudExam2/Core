# Catalog ECR
resource "aws_ecr_repository" "catalog" {
  name = "catalog-service"
}

# Sales ECR 
resource "aws_ecr_repository" "sales" {
  name = "sales-service"
}

# Notification ECR
resource "aws_ecr_repository" "notification" {
  name = "notification-service"
} 
