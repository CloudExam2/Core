# Exam2 dashboard — EC2 CPU (+ Catalog NetworkIn) + HTTP % from log metric filters.
# Instance IDs from Catalog/Sales terraform state. Re-run Core CI after EC2 replace.

data "aws_region" "current" {}

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
  sales_id_state   = try(data.terraform_remote_state.sales.outputs.ec2_sales_id, "")

  catalog_id = local.catalog_id_state != "" ? local.catalog_id_state : try(tolist(data.aws_instances.catalog_running.ids)[0], "")
  sales_id   = local.sales_id_state != "" ? local.sales_id_state : try(tolist(data.aws_instances.sales_running.ids)[0], "")

  metric_defaults = {
    region = local.region
    period = 60
    stat   = "Average"
    view   = "timeSeries"
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
          **Exam2 EC2** — Catalog `${local.catalog_id != "" ? local.catalog_id : "n/a"}` · Sales `${local.sales_id != "" ? local.sales_id : "n/a"}`
          CPU alarm >70% → SNS email. HTTP % from **Exam2/Http** log metrics (Catalog, Sales, Sales→Catalog).
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
        yAxis   = { left = { min = 0, max = 100 } }
        metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", local.catalog_id]]
      })
    }
  ] : []

  catalog_network = local.catalog_id != "" ? [
    {
      type   = "metric"
      x      = 0
      y      = 8
      width  = 12
      height = 6
      properties = merge(local.metric_defaults, {
        title   = "Catalog – Network in (bytes)"
        yAxis   = { left = { min = 0 } }
        metrics = [["AWS/EC2", "NetworkIn", "InstanceId", local.catalog_id]]
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
        yAxis   = { left = { min = 0, max = 100 } }
        metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", local.sales_id]]
      })
    }
  ] : []

  http_widget_defaults = {
    region = local.region
    period = 300
    view   = "timeSeries"
    yAxis  = { left = { min = 0, max = 100 } }
  }

  catalog_http_pct = [
    {
      type   = "metric"
      x      = 0
      y      = 14
      width  = 8
      height = 6
      properties = merge(local.http_widget_defaults, {
        title = "Catalog HTTP % (from logs)"
        metrics = [
          ["Exam2/Http", "CatalogHttp2xx", { id = "c2", stat = "Sum", visible = false }],
          [".", "CatalogHttp4xx", { id = "c4", stat = "Sum", visible = false }],
          [".", "CatalogHttp5xx", { id = "c5", stat = "Sum", visible = false }],
          [{ expression = "100 * c2 / (c2 + c4 + c5 + 1)", label = "% 2xx", id = "cp2" }],
          [{ expression = "100 * c4 / (c2 + c4 + c5 + 1)", label = "% 4xx", id = "cp4" }],
          [{ expression = "100 * c5 / (c2 + c4 + c5 + 1)", label = "% 5xx", id = "cp5" }],
        ]
      })
    }
  ]

  sales_http_pct = [
    {
      type   = "metric"
      x      = 8
      y      = 14
      width  = 8
      height = 6
      properties = merge(local.http_widget_defaults, {
        title = "Sales HTTP % (from logs)"
        metrics = [
          ["Exam2/Http", "SalesHttp2xx", { id = "s2", stat = "Sum", visible = false }],
          [".", "SalesHttp4xx", { id = "s4", stat = "Sum", visible = false }],
          [".", "SalesHttp5xx", { id = "s5", stat = "Sum", visible = false }],
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
      y      = 14
      width  = 8
      height = 6
      properties = merge(local.http_widget_defaults, {
        title = "Sales→Catalog % (from logs)"
        metrics = [
          ["Exam2/Http", "SalesCatalog2xx", { id = "x2", stat = "Sum", visible = false }],
          [".", "SalesCatalog4xx", { id = "x4", stat = "Sum", visible = false }],
          [".", "SalesCatalog5xx", { id = "x5", stat = "Sum", visible = false }],
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
    local.catalog_network,
    local.sales_cpu,
    local.catalog_http_pct,
    local.sales_http_pct,
    local.sales_catalog_http_pct,
  )
}

resource "aws_cloudwatch_dashboard" "exam2_ec2" {
  dashboard_name = "Exam2-EC2-Overview"
  dashboard_body = jsonencode({ widgets = local.dashboard_widgets })
}
