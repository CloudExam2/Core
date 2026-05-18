# HTTP status counts from app log lines (catalog.inbound, sales.api, sales.catalog).
# CloudWatch filter patterns: space-separated terms = AND; no quotes or ?* wildcards.

locals {
  http_metric_namespace = "Exam2/Http"
}

# --- Catalog: middleware logs "inbound ... status=200" + uvicorn "200 OK" ---

resource "aws_cloudwatch_log_metric_filter" "catalog_http_2xx_inbound" {
  name           = "catalog-http-2xx-inbound"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = "inbound status=200"

  metric_transformation {
    name          = "CatalogHttp2xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "catalog_http_2xx_uvicorn" {
  name           = "catalog-http-2xx-uvicorn"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = "200 OK"

  metric_transformation {
    name          = "CatalogHttp2xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "catalog_http_4xx_400" {
  name           = "catalog-http-4xx-400"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = "status=400"

  metric_transformation {
    name          = "CatalogHttp4xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "catalog_http_4xx_404" {
  name           = "catalog-http-4xx-404"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = "status=404"

  metric_transformation {
    name          = "CatalogHttp4xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "catalog_http_4xx_422" {
  name           = "catalog-http-4xx-422"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = "422 Unprocessable"

  metric_transformation {
    name          = "CatalogHttp4xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "catalog_http_5xx_500" {
  name           = "catalog-http-5xx-500"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = "status=500"

  metric_transformation {
    name          = "CatalogHttp5xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "catalog_http_5xx_502" {
  name           = "catalog-http-5xx-502"
  log_group_name = aws_cloudwatch_log_group.catalog.name
  pattern        = "status=502"

  metric_transformation {
    name          = "CatalogHttp5xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

# --- Sales: middleware "status=200" + uvicorn "200 OK" ---

resource "aws_cloudwatch_log_metric_filter" "sales_http_2xx_api" {
  name           = "sales-http-2xx-api"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "status=200"

  metric_transformation {
    name          = "SalesHttp2xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_http_2xx_uvicorn" {
  name           = "sales-http-2xx-uvicorn"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "200 OK"

  metric_transformation {
    name          = "SalesHttp2xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_http_4xx_400" {
  name           = "sales-http-4xx-400"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "status=400"

  metric_transformation {
    name          = "SalesHttp4xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_http_4xx_404" {
  name           = "sales-http-4xx-404"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "status=404"

  metric_transformation {
    name          = "SalesHttp4xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_http_4xx_422" {
  name           = "sales-http-4xx-422"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "422 Unprocessable"

  metric_transformation {
    name          = "SalesHttp4xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_http_5xx_500" {
  name           = "sales-http-5xx-500"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "status=500"

  metric_transformation {
    name          = "SalesHttp5xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_http_5xx_502" {
  name           = "sales-http-5xx-502"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "status=502"

  metric_transformation {
    name          = "SalesHttp5xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

# --- Sales → Catalog: sales.catalog logger "catalog outbound GET ... -> 200 (12.3ms)" ---

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_2xx" {
  name           = "sales-catalog-2xx"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "catalog outbound GET 200"

  metric_transformation {
    name          = "SalesCatalog2xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_4xx_404" {
  name           = "sales-catalog-4xx-404"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "catalog outbound GET 404"

  metric_transformation {
    name          = "SalesCatalog4xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_4xx_400" {
  name           = "sales-catalog-4xx-400"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "catalog outbound GET 400"

  metric_transformation {
    name          = "SalesCatalog4xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_5xx_502" {
  name           = "sales-catalog-5xx-502"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "catalog outbound GET 502"

  metric_transformation {
    name          = "SalesCatalog5xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "sales_catalog_5xx_fail" {
  name           = "sales-catalog-5xx-fail"
  log_group_name = aws_cloudwatch_log_group.sales.name
  pattern        = "catalog outbound GET failed"

  metric_transformation {
    name          = "SalesCatalog5xx"
    namespace     = local.http_metric_namespace
    value         = "1"
    default_value = 0
  }
}
