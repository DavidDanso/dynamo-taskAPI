# REST API
resource "aws_api_gateway_rest_api" "tasks_api" {
  name        = var.lambda_function_name
  description = "REST API for tasks"

  tags = {
    Name        = var.lambda_function_name
    Environment = var.stage_name
  }
}

# /tasks resource (URL path)
resource "aws_api_gateway_resource" "tasks_resource" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  parent_id   = aws_api_gateway_rest_api.tasks_api.root_resource_id
  path_part   = "tasks"
}

# POST
resource "aws_api_gateway_method" "post_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# GET
resource "aws_api_gateway_method" "get_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# PUT
resource "aws_api_gateway_method" "put_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

# DELETE
resource "aws_api_gateway_method" "delete_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# OPTIONS (required for CORS preflight)
resource "aws_api_gateway_method" "options_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# ──────────────────────────────────────────
# LAMBDA INTEGRATIONS (all methods → Lambda)
# ──────────────────────────────────────────

locals {
  http_methods = ["POST", "GET", "PUT", "DELETE"]
  method_ids = {
    POST   = aws_api_gateway_method.post_task.http_method
    GET    = aws_api_gateway_method.get_task.http_method
    PUT    = aws_api_gateway_method.put_task.http_method
    DELETE = aws_api_gateway_method.delete_task.http_method
  }
}

resource "aws_api_gateway_integration" "lambda_integration" {
  for_each = toset(local.http_methods)

  rest_api_id             = aws_api_gateway_rest_api.tasks_api.id
  resource_id             = aws_api_gateway_resource.tasks_resource.id
  http_method             = each.value
  integration_http_method = "POST" # Lambda always uses POST under the hood
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tasks_function.invoke_arn
}

# ──────────────────────────────────────────
# CORS — OPTIONS method response + integration
# ──────────────────────────────────────────

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_resource.id
  http_method = aws_api_gateway_method.options_task.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_resource.id
  http_method = aws_api_gateway_method.options_task.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_resource.id
  http_method = aws_api_gateway_method.options_task.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_integration]
}

# ──────────────────────────────────────────
# DEPLOYMENT + STAGE
# ──────────────────────────────────────────

resource "aws_api_gateway_deployment" "tasks_deployment" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id

  # Forces redeployment when methods or integrations change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.tasks_resource.id,
      aws_api_gateway_method.post_task.id,
      aws_api_gateway_method.get_task.id,
      aws_api_gateway_method.put_task.id,
      aws_api_gateway_method.delete_task.id,
      aws_api_gateway_method.options_task.id,
      aws_api_gateway_integration.lambda_integration,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration,
  ]
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  deployment_id = aws_api_gateway_deployment.tasks_deployment.id
  stage_name    = "dev"

  tags = {
    Name        = "tasks_api_dev"
    Environment = "dev"
  }
}

# ──────────────────────────────────────────
# LAMBDA PERMISSION
# ──────────────────────────────────────────

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tasks_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.tasks_api.execution_arn}/*/*"
}
