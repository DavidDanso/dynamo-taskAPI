resource "aws_dynamodb_table" "tasks" {
    name = "tasks"
    billing_mode = "PAY_PER__REQUEST"
    hash_key = "task_id"

    atrribute {
        name = "task_id"
        type = "S"
    }

    tags = {
        Name = "tasks"
        Environment = "dev"
    }
}