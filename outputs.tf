output "api_base_url" {
  description = "Base URL for the tasks API"
  value       = "https://${aws_api_gateway_rest_api.tasks_api.id}.execute-api.${data.aws_region.current.id}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}/tasks"
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.tasks_function.function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.tasks.name
}