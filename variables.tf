variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# DynamoDB table name
variable "table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "tasks"
}

# Lambda function name
variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  default     = "tasks_function"
}

# Lambda runtime (e.g. python3.12)
variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

# API Gateway stage name (e.g. dev)
variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}