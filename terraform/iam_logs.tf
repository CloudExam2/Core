# Allow lab EC2 (LabInstanceProfile) to ship Docker awslogs to /exam2/catalog.

data "aws_iam_instance_profile" "lab" {
  name = "LabInstanceProfile"
}

resource "aws_iam_role_policy" "exam2_catalog_logs" {
  name = "exam2-catalog-cloudwatch-logs"
  role = data.aws_iam_instance_profile.lab.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.catalog.arn}:*"
      }
    ]
  })
}
