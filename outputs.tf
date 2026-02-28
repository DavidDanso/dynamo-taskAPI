# Outputs provide useful information on the console after a successful `terraform apply`

# The full, ready-to-use URL for the deployed API Gateway endpoint
output "api_base_url" {
  description = "Base URL for the tasks API"
  value       = "https://${aws_api_gateway_rest_api.tasks_api.id}.execute-api.${data.aws_region.current.id}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}/tasks"
}

# The name of the successfully deployed Lambda Function
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.tasks_function.function_name
}

# The name of the freshly created DynamoDB database table
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.tasks.name
}