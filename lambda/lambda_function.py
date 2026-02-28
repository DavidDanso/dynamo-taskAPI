import json
import boto3
import os
import uuid

# Initialize the DynamoDB resource using Boto3 (AWS SDK for Python)
dynamodb = boto3.resource("dynamodb")

# Point to the specific table passed via Terraform environment variables
table = dynamodb.Table(os.environ["TABLE_NAME"])

def handler(event, context):
    """
    Main entry point for the Lambda function.
    API Gateway triggers this function and passes the HTTP request details in the 'event' argument.
    """
    http_method = event["httpMethod"]

    # Route requests to the appropriate CRUD helper based on the HTTP method
    routes = {
        "POST":   create_task,
        "GET":    get_task,
        "PUT":    update_task,
        "DELETE": delete_task,
    }

    action = routes.get(http_method)
    
    # Catch any unsupported HTTP methods
    if not action:
        return response(405, {"message": f"Method {http_method} not allowed"})

    try:
        # Execute the mapped action
        return action(event)
    except Exception as e:
        # Gracefully handle server errors
        return response(500, {"message": "Internal server error", "error": str(e)})


# ──────────────────────────────────────────
# CREATE — POST /tasks
# ──────────────────────────────────────────
def create_task(event):
    """Handles creating a new database record."""
    body = json.loads(event.get("body") or "{}")

    # Generate a unique identifying UUID for the new task
    task_id = str(uuid.uuid4())
    title = body.get("title")
    status = body.get("status", "pending")

    if not title:
        return response(400, {"message": "'title' is required"})

    # Assemble the new item
    item = {
        "task_id": task_id,
        "title":   title,
        "status":  status,
    }

    # Include any extra custom fields the caller might have sent
    item.update({k: v for k, v in body.items() if k not in item})

    # Save to DynamoDB
    table.put_item(Item=item)
    return response(201, {"message": "Task created", "task": item})


# ──────────────────────────────────────────
# READ — GET /tasks?task_id=<id>
# ──────────────────────────────────────────
def get_task(event):
    """Retrieves an existing database record by ID."""
    params = event.get("queryStringParameters") or {}
    task_id = params.get("task_id")

    if not task_id:
        return response(400, {"message": "'task_id' query parameter is required"})

    # Query DynamoDB for the specific task
    result = table.get_item(Key={"task_id": task_id})
    item = result.get("Item")

    if not item:
        return response(404, {"message": f"Task '{task_id}' not found"})

    return response(200, {"task": item})


# ──────────────────────────────────────────
# UPDATE — PUT /tasks
# ──────────────────────────────────────────
def update_task(event):
    """Updates specific fields of an existing task."""
    body = json.loads(event.get("body") or "{}")
    task_id = body.get("task_id")

    if not task_id:
        return response(400, {"message": "'task_id' is required"})

    # Extract dynamic fields (we ignore task_id as it cannot be modified)
    fields = {k: v for k, v in body.items() if k != "task_id"}

    if not fields:
        return response(400, {"message": "No fields provided to update"})

    # Build DynamoDB update expressions dynamically
    update_expression = "SET " + ", ".join(f"#f{i} = :v{i}" for i in range(len(fields)))
    expression_attribute_names = {f"#f{i}": key for i, key in enumerate(fields)}
    expression_attribute_values = {f":v{i}": val for i, val in enumerate(fields.values())}

    # Perform the update
    result = table.update_item(
        Key={"task_id": task_id},
        UpdateExpression=update_expression,
        ExpressionAttributeNames=expression_attribute_names,
        ExpressionAttributeValues=expression_attribute_values,
        ConditionExpression="attribute_exists(task_id)", # Fails if task doesn't exist
        ReturnValues="ALL_NEW",
    )

    return response(200, {"message": "Task updated", "task": result["Attributes"]})


# ──────────────────────────────────────────
# DELETE — DELETE /tasks
# ──────────────────────────────────────────
def delete_task(event):
    """Deletes an existing task from the table."""
    body = json.loads(event.get("body") or "{}")
    task_id = body.get("task_id")

    if not task_id:
        return response(400, {"message": "'task_id' is required"})

    # Remove item from DynamoDB
    table.delete_item(
        Key={"task_id": task_id},
        ConditionExpression="attribute_exists(task_id)", # Fails if task doesn't exist
    )

    return response(200, {"message": f"Task '{task_id}' deleted"})


# ──────────────────────────────────────────
# HELPER
# ──────────────────────────────────────────
def response(status_code, body):
    """Helper method to format the API Gateway response with required CORS headers."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*", # Allow cross-origin (CORS) requests
        },
        "body": json.dumps(body), # Automatically stringify dictionaries
    }