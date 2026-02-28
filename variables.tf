# Variables allow configuring the deployment without modifying core code

# Required: The region to deploy the infrastructure in
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# The name for the DynamoDB table
variable "table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "tasks"
}

# The name identity for the Lambda function
variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  default     = "tasks_function"
}

# Defining what language and OS the Lambda function will use
variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

# The deployment stage suffix for the API URL (e.g. dev, prod, staging)
variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}