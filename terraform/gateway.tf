data "aws_region" "current" {}

locals {
  catalog_proxy_enabled = trimspace(var.catalog_backend_url) != ""
  catalog_base          = trimsuffix(trimspace(var.catalog_backend_url), "/")
}

resource "aws_api_gateway_rest_api" "main" {
  name = "exam-core-gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# --- ROOT (/) CONFIGURATION ---

resource "aws_api_gateway_method" "root_any" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method

  # If URL exists, Proxy to Catalog; Else, stay MOCK
  type                    = local.catalog_proxy_enabled ? "HTTP_PROXY" : "MOCK"
  integration_http_method = local.catalog_proxy_enabled ? "ANY" : null
  uri                     = local.catalog_proxy_enabled ? "${local.catalog_base}/" : null
  
  # This template only applies if type is MOCK
  request_templates = local.catalog_proxy_enabled ? {} : {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Only need a response if we are in MOCK mode. 
# Proxy integrations handle responses automatically.
resource "aws_api_gateway_method_response" "root_200" {
  count       = local.catalog_proxy_enabled ? 0 : 1
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "root_200" {
  count       = local.catalog_proxy_enabled ? 0 : 1
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method
  status_code = aws_api_gateway_method_response.root_200[0].status_code
  response_templates = {
    "application/json" = "{\"message\":\"Set TF_VAR_catalog_backend_url to Catalog http://IP:80 then re-apply Core for /catalog proxy\"}"
  }
}

# --- /catalog CONFIGURATION ---

resource "aws_api_gateway_resource" "catalog" {
  count       = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "catalog"
}

resource "aws_api_gateway_method" "catalog_base_any" {
  count         = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.catalog[0].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "catalog_base_http" {
  count                   = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.catalog[0].id
  http_method             = aws_api_gateway_method.catalog_base_any[0].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "${local.catalog_base}/"
}

# --- /catalog/{proxy+} CONFIGURATION ---

resource "aws_api_gateway_resource" "catalog_proxy" {
  count       = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.catalog[0].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "catalog_proxy_any" {
  count         = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.catalog_proxy[0].id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "catalog_proxy_http" {
  count                   = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.catalog_proxy[0].id
  http_method             = aws_api_gateway_method.catalog_proxy_any[0].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "${local.catalog_base}/{proxy}"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# --- DEPLOYMENT ---

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Triggers a redeploy if the URL or integrations change
  triggers = {
    redeploy = sha1(join(",", [
      var.catalog_backend_url,
      jsonencode(aws_api_gateway_integration.root_integration),
      local.catalog_proxy_enabled ? jsonencode(aws_api_gateway_integration.catalog_base_http[0]) : "",
      local.catalog_proxy_enabled ? jsonencode(aws_api_gateway_integration.catalog_proxy_http[0]) : ""
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.root_integration,
    aws_api_gateway_integration.catalog_base_http,
    aws_api_gateway_integration.catalog_proxy_http
  ]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"
}