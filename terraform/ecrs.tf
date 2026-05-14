import {
  to = aws_ecr_repository.catalog
  id = "catalog-service"
}

import {
  to = aws_ecr_repository.sales
  id = "sales-service"
}

import {
  to = aws_ecr_repository.notification
  id = "notification-service"
}

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
