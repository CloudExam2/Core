# One dashboard: CPU (AWS/EC2) + memory/disk (CloudWatch agent) for Catalog & Sales EC2.
# Instances are discovered by tag Name; re-run Core CI after replacing EC2 so widgets update.

data "aws_region" "current" {}

data "aws_instances" "catalog" {
  filter {
    name   = "tag:Name"
    values = ["Catalog-Service"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running", "pending", "stopped"]
  }
}

data "aws_instances" "sales" {
  filter {
    name   = "tag:Name"
    values = ["Sales-Service"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running", "pending", "stopped"]
  }
}

locals {
  region     = data.aws_region.current.name
  catalog_id = try(tolist(data.aws_instances.catalog.ids)[0], "")
  sales_id   = try(tolist(data.aws_instances.sales.ids)[0], "")

  metric_defaults = {
    region = local.region
    period = 300
    stat   = "Average"
    view   = "timeSeries"
    yAxis = {
      left = { min = 0, max = 100 }
    }
  }

  catalog_cpu = local.catalog_id != "" ? [
    {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = merge(local.metric_defaults, {
        title   = "Catalog – CPU %"
        metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", local.catalog_id]]
      })
    }
  ] : []

  sales_cpu = local.sales_id != "" ? [
    {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = merge(local.metric_defaults, {
        title   = "Sales – CPU %"
        metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", local.sales_id]]
      })
    }
  ] : []

  catalog_mem = local.catalog_id != "" ? [
    {
      type   = "metric"
      x      = 0
      y      = 6
      width  = 12
      height = 6
      properties = merge(local.metric_defaults, {
        title   = "Catalog – Memory %"
        metrics = [["Exam2/Catalog", "mem_used_percent", "InstanceId", local.catalog_id]]
      })
    }
  ] : []

  sales_mem = local.sales_id != "" ? [
    {
      type   = "metric"
      x      = 12
      y      = 6
      width  = 12
      height = 6
      properties = merge(local.metric_defaults, {
        title   = "Sales – Memory %"
        metrics = [["Exam2/Sales", "mem_used_percent", "InstanceId", local.sales_id]]
      })
    }
  ] : []

  catalog_disk = local.catalog_id != "" ? [
    {
      type   = "metric"
      x      = 0
      y      = 12
      width  = 12
      height = 6
      properties = merge(local.metric_defaults, {
        title   = "Catalog – Disk % (/)"
        metrics = [["Exam2/Catalog", "used_percent", "path", "/", "InstanceId", local.catalog_id]]
      })
    }
  ] : []

  sales_disk = local.sales_id != "" ? [
    {
      type   = "metric"
      x      = 12
      y      = 12
      width  = 12
      height = 6
      properties = merge(local.metric_defaults, {
        title   = "Sales – Disk % (/)"
        metrics = [["Exam2/Sales", "used_percent", "path", "/", "InstanceId", local.sales_id]]
      })
    }
  ] : []

  placeholder = (local.catalog_id == "" && local.sales_id == "") ? [
    {
      type   = "text"
      x      = 0
      y      = 0
      width  = 24
      height = 3
      properties = {
        markdown = "# Exam2 EC2 metrics\nDeploy **Catalog** and **Sales** EC2 (terraform), then **re-run Core CI** so this dashboard binds to instance IDs."
      }
    }
  ] : []

  dashboard_widgets = concat(
    local.placeholder,
    local.catalog_cpu,
    local.sales_cpu,
    local.catalog_mem,
    local.sales_mem,
    local.catalog_disk,
    local.sales_disk,
  )
}

resource "aws_cloudwatch_dashboard" "exam2_ec2" {
  dashboard_name = "Exam2-EC2-Overview"
  dashboard_body = jsonencode({ widgets = local.dashboard_widgets })
}
