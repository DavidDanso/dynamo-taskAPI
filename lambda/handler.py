import json
import boto3
import os

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

def handler(event, context):
    http_method = event["httpMethod"]
    
    if http_method == "POST":
        body = json.loads(event["body"])
        table.put_item(Item=body)
        return {
            "statusCode": 201,
            "body": json.dumps({"message": "Task created"})
        }

    elif http_method == "GET":
        task_id = event["queryStringParameters"]["task_id"]
        response = table.get_item(Key={"task_id": task_id})
        item = response.get("Item")
        if not item:
            return {"statusCode": 404, "body": json.dumps({"message": "Task not found"})}
        return {"statusCode": 200, "body": json.dumps(item)}

    return {"statusCode": 400, "body": json.dumps({"message": "Unsupported method"})}
