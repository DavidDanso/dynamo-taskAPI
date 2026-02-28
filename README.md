# Serverless Task API with Terraform & AWS

A fully functional, serverless REST API infrastructure deployed automatically using Terraform. 

## Architecture
- **Amazon API Gateway**: Acts as the front door, routing HTTP requests and handling CORS.
- **AWS Lambda (Python)**: Contains the core business logic to perform Create, Read, Update, and Delete (CRUD) operations.
- **Amazon DynamoDB**: A fast and flexible NoSQL database to store the tasks.
- **AWS IAM**: Strict, least-privilege access control ensuring the Lambda function can only access the specific DynamoDB table.

## Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured (`aws configure`)

## Project Structure
- `main.tf` - Core configuration, provider setup, and Lambda packaging.
- `apigateway.tf` - API Gateway resources, methods, and Lambda integrations.
- `lambda.tf` - Lambda function setup and environment variables.
- `dynamodb.tf` - DynamoDB table definition.
- `iam.tf` - IAM Roles and scoped policies for Lambda limits access to DynamoDB.
- `variables.tf` / `terraform.tfvars` - Input parameters.
- `outputs.tf` - Resulting API Gateway URL after deployment.
- `lambda/lambda_function.py` - Python application code handling the API routes.

## How to Deploy

1. **Initialize Terraform** (downloads required providers)
   ```bash
   terraform init
   ```

2. **See the Plan** (optional, shows what will be created)
   ```bash
   terraform plan
   ```

3. **Deploy the Infrastructure**
   ```bash
   terraform apply
   ```
   *Type `yes` when prompted to confirm.*

4. **Get your API URL**
   Once deployed, Terraform will output your `api_base_url`. It will look something like this:
   `https://<api-id>.execute-api.<region>.amazonaws.com/dev/tasks`

---

## How to Use (Testing the API)

Replace `<YOUR_API_URL>` in the commands below with the `api_base_url` from your Terraform output.

### 1. Create a Task (POST)
```bash
curl -X POST <YOUR_API_URL> \
  -H "Content-Type: application/json" \
  -d '{"title": "Buy groceries", "status": "pending"}'
```
*(Copy the `task_id` from the response for the next steps)*

### 2. Read a Task (GET)
```bash
curl -X GET "<YOUR_API_URL>?task_id=<YOUR_TASK_ID>"
```

### 3. Update a Task (PUT)
```bash
curl -X PUT <YOUR_API_URL> \
  -H "Content-Type: application/json" \
  -d '{"task_id": "<YOUR_TASK_ID>", "status": "completed"}'
```

### 4. Delete a Task (DELETE)
```bash
curl -X DELETE <YOUR_API_URL> \
  -H "Content-Type: application/json" \
  -d '{"task_id": "<YOUR_TASK_ID>"}'
```

---

## Clean Up
To avoid incurring any AWS charges after you are done testing, destroy the infrastructure:
```bash
terraform destroy
```
*Type `yes` when prompted to confirm.*
