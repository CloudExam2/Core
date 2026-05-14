# Regional REST API: /catalog/{proxy+} -> HTTP_PROXY to Catalog EC2 (strip /catalog prefix in path).
# Set TF_VAR_catalog_backend_url after Catalog is up, e.g. http://12.34.56.78:80 (no trailing slash).
# True "API inside VPC only" needs NLB + VPC Link; this is the standard regional public invoke URL.

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

# Always: minimal method on root so first deployment succeeds before Catalog URL exists.
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_mock" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "root_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "root_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = aws_api_gateway_method_response.root_200.status_code
  response_templates = {
    "application/json" = "{\"message\":\"Set TF_VAR_catalog_backend_url to Catalog http://IP:80 then re-apply Core for /catalog proxy\"}"
  }
}

resource "aws_api_gateway_resource" "catalog" {
  count       = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "catalog"
}

resource "aws_api_gateway_resource" "catalog_proxy" {
  count       = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.catalog[0].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "catalog_any" {
  count         = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.catalog_proxy[0].id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "catalog_http" {
  count                   = local.catalog_proxy_enabled ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.catalog_proxy[0].id
  http_method             = aws_api_gateway_method.catalog_any[0].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "${local.catalog_base}/{proxy}"
  connection_type         = "INTERNET"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeploy = sha1(join(",", concat(
      [var.catalog_backend_url],
      aws_api_gateway_integration.catalog_http[*].id,
    )))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.root_mock,
    aws_api_gateway_integration_response.root_200,
  ]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"
}
