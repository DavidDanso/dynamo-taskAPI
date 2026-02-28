# Defines the AWS Lambda function resource
resource "aws_lambda_function" "tasks_function" {
  function_name = var.lambda_function_name

  # Point to the zip file created by the archive_file data source mapping
  filename = data.archive_file.lambda_zip.output_path

  # Base64 hash of the zip file to detect code changes and trigger updates upon subsequent applies
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Set the execution runtime (e.g., Python 3.12)
  runtime = var.lambda_runtime

  # The entry point method inside the Python code format: <filename>.<method>
  handler = "lambda_function.handler"

  # The IAM role governing the function's permissions
  role = aws_iam_role.lambda_role.arn

  # Environment variables made accessible within the Python code process
  environment {
    variables = {
      # Pass the DynamoDB table name into the Lambda dynamically
      TABLE_NAME = aws_dynamodb_table.tasks.name
    }
  }

  tags = {
    Name        = var.lambda_function_name
    Environment = var.stage_name
  }
}