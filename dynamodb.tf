# Create a DynamoDB table to store task data
resource "aws_dynamodb_table" "tasks" {
  # The name of the table, passed from our variables
  name = var.table_name

  # Use On-Demand billing (pay only for what you use) instead of provisioned read/write capacity
  billing_mode = "PAY_PER_REQUEST"

  # Define the primary key for the table
  hash_key = "task_id"

  # Define the attributes that will act as keys
  attribute {
    name = "task_id"
    type = "S" # 'S' stands for String type
  }

  # Tags for resource organization and cost tracking
  tags = {
    Name        = var.table_name
    Environment = var.stage_name
  }
}