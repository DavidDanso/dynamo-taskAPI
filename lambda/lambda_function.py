import json
import boto3
import os
import uuid
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def handler(event, context):
    http_method = event["httpMethod"]

    routes = {
        "POST":   create_task,
        "GET":    get_task,
        "PUT":    update_task,
        "DELETE": delete_task,
    }

    action = routes.get(http_method)
    if not action:
        return response(405, {"message": f"Method {http_method} not allowed"})

    try:
        return action(event)
    except Exception as e:
        return response(500, {"message": "Internal server error", "error": str(e)})


# ──────────────────────────────────────────
# CREATE — POST /tasks
# ──────────────────────────────────────────
def create_task(event):
    body = json.loads(event.get("body") or "{}")

    task_id = str(uuid.uuid4())
    title = body.get("title")
    status = body.get("status", "pending")

    if not title:
        return response(400, {"message": "'title' is required"})

    item = {
        "task_id": task_id,
        "title":   title,
        "status":  status,
    }

    # Include any extra fields the caller sends
    item.update({k: v for k, v in body.items() if k not in item})

    table.put_item(Item=item)
    return response(201, {"message": "Task created", "task": item})


# ──────────────────────────────────────────
# READ — GET /tasks?task_id=<id>
# ──────────────────────────────────────────
def get_task(event):
    params = event.get("queryStringParameters") or {}
    task_id = params.get("task_id")

    if not task_id:
        return response(400, {"message": "'task_id' query parameter is required"})

    result = table.get_item(Key={"task_id": task_id})
    item = result.get("Item")

    if not item:
        return response(404, {"message": f"Task '{task_id}' not found"})

    return response(200, {"task": item})


# ──────────────────────────────────────────
# UPDATE — PUT /tasks
# ──────────────────────────────────────────
def update_task(event):
    body = json.loads(event.get("body") or "{}")
    task_id = body.get("task_id")

    if not task_id:
        return response(400, {"message": "'task_id' is required"})

    # Build update expression dynamically from whatever fields are passed
    fields = {k: v for k, v in body.items() if k != "task_id"}

    if not fields:
        return response(400, {"message": "No fields provided to update"})

    update_expression = "SET " + ", ".join(f"#f{i} = :v{i}" for i in range(len(fields)))
    expression_attribute_names = {f"#f{i}": key for i, key in enumerate(fields)}
    expression_attribute_values = {f":v{i}": val for i, val in enumerate(fields.values())}

    result = table.update_item(
        Key={"task_id": task_id},
        UpdateExpression=update_expression,
        ExpressionAttributeNames=expression_attribute_names,
        ExpressionAttributeValues=expression_attribute_values,
        ConditionExpression="attribute_exists(task_id)",
        ReturnValues="ALL_NEW",
    )

    return response(200, {"message": "Task updated", "task": result["Attributes"]})


# ──────────────────────────────────────────
# DELETE — DELETE /tasks
# ──────────────────────────────────────────
def delete_task(event):
    body = json.loads(event.get("body") or "{}")
    task_id = body.get("task_id")

    if not task_id:
        return response(400, {"message": "'task_id' is required"})

    table.delete_item(
        Key={"task_id": task_id},
        ConditionExpression="attribute_exists(task_id)",
    )

    return response(200, {"message": f"Task '{task_id}' deleted"})


# ──────────────────────────────────────────
# HELPER
# ──────────────────────────────────────────
def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }