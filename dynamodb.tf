resource "aws_dynamodb_table" "tasks" {
    name = var.table_name
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "task_id"

    attribute {
        name = "task_id"
        type = "S"
    }

    tags = {
        Name = var.table_name
        Environment = "dev"
    }
}