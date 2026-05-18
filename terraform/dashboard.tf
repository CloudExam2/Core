# Exam2 EC2 dashboard: CPU (AWS/EC2) + memory/disk (CloudWatch agent).
# Instance IDs come from Catalog/Sales terraform state (not EC2 tag search), so widgets
# stay correct after -replace=aws_instance.*. Re-run Core CI after Catalog/Sales deploy.

data "aws_region" "current" {}

# Fallback only if remote state is missing (first lab setup).
data "aws_instances" "catalog_running" {
  filter {
    name   = "tag:Name"
    values = ["Catalog-Service"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "sales_running" {
  filter {
    name   = "tag:Name"
    values = ["Sales-Service"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

locals {
  region = data.aws_region.current.name

  catalog_id_state = try(data.terraform_remote_state.catalog.outputs.ec2_catalog_id, "")
  sales_id_state     = try(data.terraform_remote_state.sales.outputs.ec2_sales_id, "")

  catalog_id = local.catalog_id_state != "" ? local.catalog_id_state : try(tolist(data.aws_instances.catalog_running.ids)[0], "")
  sales_id   = local.sales_id_state != "" ? local.sales_id_state : try(tolist(data.aws_instances.sales_running.ids)[0], "")

  metric_defaults = {
    region = local.region
    period = 300
    stat   = "Average"
    view   = "timeSeries"
    yAxis = {
      left = { min = 0, max = 100 }
    }
  }

  header = [
    {
      type   = "text"
      x      = 0
      y      = 0
      width  = 24
      height = 2
      properties = {
        markdown = <<-EOT
          **Exam2 EC2** — Catalog `${local.catalog_id != "" ? local.catalog_id : "not in state"}` · Sales `${local.sales_id != "" ? local.sales_id : "not in state"}`
          IDs from Catalog/Sales terraform state. After EC2 replace: run **Catalog/Sales CI**, then **Core CI**.
        EOT
      }
    }
  ]

  catalog_cpu = local.catalog_id != "" ? [
    {
      type   = "metric"
      x      = 0
      y      = 2
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
      y      = 2
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
      y      = 8
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
      y      = 8
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
      y      = 14
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
      y      = 14
      width  = 12
      height = 6
      properties = merge(local.metric_defaults, {
        title   = "Sales – Disk % (/)"
        metrics = [["Exam2/Sales", "used_percent", "path", "/", "InstanceId", local.sales_id]]
      })
    }
  ] : []

  missing_sales = local.sales_id == "" ? [
    {
      type   = "text"
      x      = 12
      y      = 2
      width  = 12
      height = 3
      properties = {
        markdown = "**Sales EC2** — no instance id in terraform state. Run **Sales** CI first, then **Core**."
      }
    }
  ] : []

  dashboard_widgets = concat(
    local.header,
    local.catalog_cpu,
    local.sales_cpu,
    local.catalog_mem,
    local.sales_mem,
    local.catalog_disk,
    local.sales_disk,
    local.missing_sales,
  )
}

resource "aws_cloudwatch_dashboard" "exam2_ec2" {
  dashboard_name = "Exam2-EC2-Overview"
  dashboard_body = jsonencode({ widgets = local.dashboard_widgets })
}
