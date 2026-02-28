data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Zip the Python file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}