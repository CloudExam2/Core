# Response logic only for MOCK mode
resource "aws_api_gateway_method_response" "root_mock_200" {
  count       = local.catalog_proxy_enabled ? 0 : 1
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "root_mock_200" {
  count       = local.catalog_proxy_enabled ? 0 : 1
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method
  status_code = aws_api_gateway_method_response.root_mock_200[0].status_code
  response_templates = {
    "application/json" = "{\"message\":\"Set TF_VAR_catalog_backend_url to Catalog http://IP:80 then re-apply Core for /catalog proxy\"}"
  }
}

# --- /catalog ---

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

# --- /catalog/{proxy+} ---

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

# --- DEPLOYMENT & STAGE ---

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeploy = sha1(join(",", [
      var.catalog_backend_url,
      aws_api_gateway_method.root_any.id,
      local.catalog_proxy_enabled ? aws_api_gateway_integration.catalog_base_http[0].id : "",
      local.catalog_proxy_enabled ? aws_api_gateway_integration.catalog_proxy_http[0].id : ""
    ]))
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"
}