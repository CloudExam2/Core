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
    period = 60
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

  # Fallback if agent uses host dimension instead of InstanceId (common on voclabs).
  catalog_mem_search = [
    {
      type   = "metric"
      x      = 0
      y      = 20
      width  = 12
      height = 4
      properties = merge(local.metric_defaults, {
        title = "Catalog – Memory % (SEARCH fallback)"
        metrics = [
          [{ expression = "SEARCH('{Exam2/Catalog} MetricName=\"mem_used_percent\"', 'Average', 60)", id = "m1", label = "mem" }]
        ]
      })
    }
  ]

  sales_mem_search = [
    {
      type   = "metric"
      x      = 12
      y      = 20
      width  = 12
      height = 4
      properties = merge(local.metric_defaults, {
        title = "Sales – Memory % (SEARCH fallback)"
        metrics = [
          [{ expression = "SEARCH('{Exam2/Sales} MetricName=\"mem_used_percent\"', 'Average', 60)", id = "m1", label = "mem" }]
        ]
      })
    }
  ]

  cw_http_widget_defaults = {
    region = local.region
    period = 300
    view   = "timeSeries"
  }

  catalog_http_pct = [
    {
      type   = "metric"
      x      = 0
      y      = 24
      width  = 8
      height = 6
      properties = merge(local.cw_http_widget_defaults, {
        title = "Catalog HTTP % (from logs)"
        metrics = [
          ["Exam2/Http", "CatalogHttp2xx", { id = "c2", stat = "Sum" }],
          [".", "CatalogHttp4xx", { id = "c4", stat = "Sum" }],
          [".", "CatalogHttp5xx", { id = "c5", stat = "Sum" }],
          [{ expression = "100 * c2 / (c2 + c4 + c5 + 1)", label = "% 2xx", id = "cp2", yAxis = "left" }],
          [{ expression = "100 * c4 / (c2 + c4 + c5 + 1)", label = "% 4xx", id = "cp4", yAxis = "left" }],
          [{ expression = "100 * c5 / (c2 + c4 + c5 + 1)", label = "% 5xx", id = "cp5", yAxis = "left" }],
        ]
      })
    }
  ]

  sales_http_pct = [
    {
      type   = "metric"
      x      = 8
      y      = 24
      width  = 8
      height = 6
      properties = merge(local.cw_http_widget_defaults, {
        title = "Sales HTTP % (from logs)"
        metrics = [
          ["Exam2/Http", "SalesHttp2xx", { id = "s2", stat = "Sum" }],
          [".", "SalesHttp4xx", { id = "s4", stat = "Sum" }],
          [".", "SalesHttp5xx", { id = "s5", stat = "Sum" }],
          [{ expression = "100 * s2 / (s2 + s4 + s5 + 1)", label = "% 2xx", id = "sp2" }],
          [{ expression = "100 * s4 / (s2 + s4 + s5 + 1)", label = "% 4xx", id = "sp4" }],
          [{ expression = "100 * s5 / (s2 + s4 + s5 + 1)", label = "% 5xx", id = "sp5" }],
        ]
      })
    }
  ]

  sales_catalog_http_pct = [
    {
      type   = "metric"
      x      = 16
      y      = 24
      width  = 8
      height = 6
      properties = merge(local.cw_http_widget_defaults, {
        title = "Sales→Catalog % (from logs)"
        metrics = [
          ["Exam2/Http", "SalesCatalog2xx", { id = "x2", stat = "Sum" }],
          [".", "SalesCatalog4xx", { id = "x4", stat = "Sum" }],
          [".", "SalesCatalog5xx", { id = "x5", stat = "Sum" }],
          [{ expression = "100 * x2 / (x2 + x4 + x5 + 1)", label = "% 2xx", id = "xp2" }],
          [{ expression = "100 * x4 / (x2 + x4 + x5 + 1)", label = "% 4xx", id = "xp4" }],
          [{ expression = "100 * x5 / (x2 + x4 + x5 + 1)", label = "% 5xx", id = "xp5" }],
        ]
      })
    }
  ]

  dashboard_widgets = concat(
    local.header,
    local.catalog_cpu,
    local.sales_cpu,
    local.catalog_mem,
    local.sales_mem,
    local.catalog_disk,
    local.sales_disk,
    local.catalog_mem_search,
    local.sales_mem_search,
    local.catalog_http_pct,
    local.sales_http_pct,
    local.sales_catalog_http_pct,
    local.missing_sales,
  )
}

resource "aws_cloudwatch_dashboard" "exam2_ec2" {
  dashboard_name = "Exam2-EC2-Overview"
  dashboard_body = jsonencode({ widgets = local.dashboard_widgets })
}
