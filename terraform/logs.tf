# Shared log groups (stable names across lab resets; streams are per EC2/container).

resource "aws_cloudwatch_log_group" "catalog" {
  name              = "/exam2/catalog"
  retention_in_days = 7

  tags = {
    Name    = "catalog-app"
    Service = "catalog"
  }
}
