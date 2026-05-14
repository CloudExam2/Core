# Catalog ECR
resource "aws_ecr_repository" "catalog" {
  name                 = "catalog-service"
  image_tag_mutability = "MUTABLE" # Good for development/tags
  force_delete         = true     # Allows terraform destroy to work even if images exist
}

# Sales ECR 
resource "aws_ecr_repository" "sales" {
  name                 = "sales-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# Notification ECR
resource "aws_ecr_repository" "notification" {
  name                 = "notification-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}