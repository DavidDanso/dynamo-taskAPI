# IAM Role that the Lambda function will assume to gain AWS permissions
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  # Trust policy dictating who can assume this role (AWS Lambda service)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "lambda_execution_role"
    Environment = var.stage_name
  }
}

# Attach the basic AWS Lambda execution policy
# This allows the Lambda function to write its execution logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create a custom IAM policy granting specific permissions to interact with DynamoDB
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name = "lambda_dynamodb_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # Allow Create, Read, Update, and Delete operations on DynamoDB
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        # Security: Restrict these actions to ONLY our specific tasks table (Principle of Least Privilege)
        Resource = aws_dynamodb_table.tasks.arn
      }
    ]
  })
}

# Attach our custom restricted DynamoDB policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}
