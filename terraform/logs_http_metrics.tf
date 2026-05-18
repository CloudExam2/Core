# HTTP status counts from uvicorn access logs + app loggers → dashboard % (2xx/4xx/5xx).

locals {
  http_metric_defaults = {
    namespace   = "Exam2/Http"
    period      = 300
    stat        = "Sum"
    default_val = 0
  }
}

# --- Catalog (/exam2/catalog): uvicorn access lines end with " 200 OK", " 422", etc. ---

resource "aws_cloudwatch_log_metric_filter" "catalog_http_2xx" {
  name           = "catalog-http-2xx"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = " \" 2"

  metric_transformation {
    name          = "CatalogHttp2xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

resource "aws_cloudwatch_log_metric_filter" "catalog_http_4xx" {
  name           = "catalog-http-4xx"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = " \" 4"

  metric_transformation {
    name          = "CatalogHttp4xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

resource "aws_cloudwatch_log_metric_filter" "catalog_http_5xx" {
  name           = "catalog-http-5xx"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = " \" 5"

  metric_transformation {
    name          = "CatalogHttp5xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

# --- Sales (/exam2/sales) ---

resource "aws_cloudwatch_log_metric_filter" "sales_http_2xx" {
  name           = "sales-http-2xx"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = " \" 2"

  metric_transformation {
    name          = "SalesHttp2xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_http_4xx" {
  name           = "sales-http-4xx"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = " \" 4"

  metric_transformation {
    name          = "SalesHttp4xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_http_5xx" {
  name           = "sales-http-5xx"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = " \" 5"

  metric_transformation {
    name          = "SalesHttp5xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

# --- Sales → Catalog (sales.catalog logger on /exam2/sales) ---

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_2xx" {
  name           = "sales-catalog-2xx"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "catalog outbound GET ?* -> 2"

  metric_transformation {
    name          = "SalesCatalog2xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_4xx" {
  name           = "sales-catalog-4xx"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "catalog outbound GET ?* -> 4"

  metric_transformation {
    name          = "SalesCatalog4xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_5xx" {
  name           = "sales-catalog-5xx"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "?*catalog outbound GET ?* -> 5"

  metric_transformation {
    name          = "SalesCatalog5xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_fail" {
  name           = "sales-catalog-fail"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "?*catalog outbound GET ?* failed"

  metric_transformation {
    name          = "SalesCatalog5xx"
    namespace     = local.http_metric_defaults.namespace
    value         = "1"
    default_value = local.http_metric_defaults.default_val
  }
}
