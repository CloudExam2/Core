# Shared log groups (stable names across lab resets; streams are per EC2/container).
# EC2 uses LabInstanceProfile — do not attach inline policies to LabRole here (voclabs
# denies iam:PutRolePolicy). Docker awslogs needs logs:CreateLogStream / PutLogEvents on
# this group; the lab role usually already allows that.

resource "aws_cloudwatch_log_group" "catalog" {
  name              = "/exam2/catalog"
  retention_in_days = 7

  tags = {
    Name    = "catalog-app"
    Service = "catalog"
  }
}

resource "aws_cloudwatch_log_group" "sales" {
  name              = "/exam2/sales"
  retention_in_days = 7

  tags = {
    Name    = "sales-app"
    Service = "sales"
  }
}
