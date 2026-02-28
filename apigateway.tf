# ──────────────────────────────────────────
# REST API CONFIGURATION
# ──────────────────────────────────────────

# Create the main API Gateway REST API instance
resource "aws_api_gateway_rest_api" "tasks_api" {
  name        = var.lambda_function_name
  description = "REST API for tasks"

  tags = {
    Name        = var.lambda_function_name
    Environment = var.stage_name
  }
}

# Create a resource (URL path) under the API, e.g., /tasks
resource "aws_api_gateway_resource" "tasks_resource" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  parent_id   = aws_api_gateway_rest_api.tasks_api.root_resource_id
  path_part   = "tasks"
}

# ──────────────────────────────────────────
# API METHODS (HTTP VERBS)
# ──────────────────────────────────────────

# POST Method (for creating tasks)
resource "aws_api_gateway_method" "post_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "POST"
  authorization = "NONE" # Public API, no auth required
}

# GET Method (for fetching tasks)
resource "aws_api_gateway_method" "get_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# PUT Method (for updating tasks)
resource "aws_api_gateway_method" "put_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

# DELETE Method (for deleting tasks)
resource "aws_api_gateway_method" "delete_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# OPTIONS Method (Required for CORS preflight requests from web browsers)
resource "aws_api_gateway_method" "options_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# ──────────────────────────────────────────
# LAMBDA INTEGRATIONS
# ──────────────────────────────────────────

locals {
  # List of operational HTTP methods to integrate with our Lambda
  http_methods = ["POST", "GET", "PUT", "DELETE"]
}

# Connect each HTTP method to our Lambda function using API Gateway proxy integration
resource "aws_api_gateway_integration" "lambda_integration" {
  for_each = toset(local.http_methods)

  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_resource.id
  http_method = each.value
  # Lambda AWS_PROXY integration always uses POST internally to invoke the function
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tasks_function.invoke_arn
}

# ──────────────────────────────────────────
# CORS CONFIGURATION (handling OPTIONS request)
# ──────────────────────────────────────────

# Define the expected 200 OK response for the OPTIONS method
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_resource.id
  http_method = aws_api_gateway_method.options_task.http_method
  status_code = "200"

  # Declare which CORS headers we plan to return
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Mock integration for the OPTIONS method (API Gateway handles it directly without calling Lambda)
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_resource.id
  http_method = aws_api_gateway_method.options_task.http_method
  type        = "MOCK"

  # Hardcode the mock 200 response
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Define the actual CORS header values returned in the mock integration response
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_resource.id
  http_method = aws_api_gateway_method.options_task.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  # Set the specific values for the accepted headers, permitted HTTP methods, and allowed origins (*)
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_integration]
}

# ──────────────────────────────────────────
# DEPLOYMENT AND STAGE
# ──────────────────────────────────────────

# Package the API Gateway configuration into a deployment
resource "aws_api_gateway_deployment" "tasks_deployment" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id

  # Forces a redeployment whenever any underlying API methods or integrations are changed
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

# Publish the deployment to a specific environment stage (e.g., 'dev')
resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  deployment_id = aws_api_gateway_deployment.tasks_deployment.id
  stage_name    = var.stage_name

  tags = {
    Name        = "${var.lambda_function_name}_${var.stage_name}"
    Environment = var.stage_name
  }
}

# ──────────────────────────────────────────
# SECURITY AND PERMISSIONS
# ──────────────────────────────────────────

# Explicitly grant API Gateway permission to trigger/invoke our Lambda function
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tasks_function.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict invocation to this specific API Gateway instance to prevent unauthorized spoofing triggers
  source_arn = "arn:aws:execute-api:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.tasks_api.id}/*/*"
}
