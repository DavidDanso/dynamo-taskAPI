# Fetch the AWS Account ID of the current deployer
data "aws_caller_identity" "current" {}

# Fetch the current AWS region being used
data "aws_region" "current" {}

# Package the Python code into a zip archive for Lambda deployment automatically
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}