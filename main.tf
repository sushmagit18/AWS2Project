

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "glue.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
        ],
        Resource = aws_dynamodb_table.records_table.arn
      }
    ]
  })
}

# Attach AWSLambdaBasicExecutionRole
resource "aws_iam_policy_attachment" "lambda_basic_policy" {
  name       = "lambda_basic_policy"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// Bucket used for Glue scripts and general services
resource "aws_s3_bucket" "data_bucket" {
  bucket = var.data_bucket_name
}

// Bucket used exclusively for file uploads via the process_s3 Lambda
resource "aws_s3_bucket" "upload_bucket" {
  bucket = var.upload_bucket_name
}

# DynamoDB Table
resource "aws_dynamodb_table" "records_table" {
  name         = "DBRecords"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "API Gateway for my AWS workflow"
}

resource "aws_api_gateway_resource" "records" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "records"
}

resource "aws_api_gateway_method" "get_records" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.records.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_records" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.records.id
  http_method             = aws_api_gateway_method.get_records.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.functions.process_dynamodb_invoke_arn
}

resource "aws_api_gateway_resource" "glue" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "glue"
}

resource "aws_api_gateway_method" "post_glue" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.glue.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_glue" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.glue.id
  http_method             = aws_api_gateway_method.post_glue.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.functions.start_glue_invoke_arn
}

// New S3 Resource
resource "aws_api_gateway_resource" "s3" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "s3"
}

// GET Method on /s3
resource "aws_api_gateway_method" "get_s3" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.s3.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "s3_get" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.s3.id
  http_method             = aws_api_gateway_method.get_s3.http_method
  type                    = "AWS"
  integration_http_method = "GET"
  uri                     = "arn:aws:apigateway:${var.region}:s3:path/${var.data_bucket_name}"
  request_parameters = {
    "integration.request.querystring.list-type" = "'2'"
  }
  credentials = aws_iam_role.apigw_s3_role.arn
}

# Method Response for 200 OK on GET /s3
resource "aws_api_gateway_method_response" "get_s3_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.s3.id
  http_method = aws_api_gateway_method.get_s3.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

# Integration Response for 200 OK on GET /s3
resource "aws_api_gateway_integration_response" "get_s3_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.s3.id
  http_method = aws_api_gateway_method.get_s3.http_method
  status_code = aws_api_gateway_method_response.get_s3_response.status_code
  response_templates = {
    "application/json" = ""
  }
  depends_on = [aws_api_gateway_integration.s3_get]
}

# POST method on /s3 to obtain a pre-signed URL for file upload
resource "aws_api_gateway_method" "post_s3" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.s3.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_s3" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.s3.id
  http_method             = aws_api_gateway_method.post_s3.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.functions.process_s3_invoke_arn
}

// IAM Role for API Gateway to access S3
resource "aws_iam_role" "apigw_s3_role" {
  name = "apigw_s3_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Inline policy for the API Gateway S3 role
resource "aws_iam_role_policy" "apigw_s3_role_policy" {
  name = "apigw_s3_role_policy"
  role = aws_iam_role.apigw_s3_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:ListBucket"],
      Resource = [aws_s3_bucket.data_bucket.arn]
    }]
  })
}

resource "aws_s3_bucket_policy" "data_bucket_policy" {
  bucket = aws_s3_bucket.data_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowAPIGatewayList",
      Effect    = "Allow",
      Principal = { AWS = aws_iam_role.apigw_s3_role.arn },
      Action    = "s3:ListBucket",
      Resource  = aws_s3_bucket.data_bucket.arn
    }]
  })
}

# Deploy API (Ensure API Gateway has methods before deploying)
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode({
      records_integration = aws_api_gateway_integration.lambda_records.uri,
      glue_integration    = aws_api_gateway_integration.lambda_glue.uri,
      s3_integration      = aws_api_gateway_integration.lambda_s3.uri
    }))
  }
  depends_on = [
    aws_api_gateway_integration.lambda_records,
    aws_api_gateway_integration.lambda_glue,
    aws_api_gateway_integration.lambda_s3
  ]
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.api_stage
}

# AWS Glue Job
resource "aws_glue_job" "glue_job" {
  name     = var.glue_job_name
  role_arn = aws_iam_role.lambda_role.arn
  command {
    script_location = "s3://${var.data_bucket_name}/${var.glue_script_location}"
    name            = "glueetl"
  }
}

# IAM policy for Lambda to start the Glue job
resource "aws_iam_role_policy" "lambda_glue_policy" {
  name = "lambda-glue-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJob",
        ],
        Resource = aws_glue_job.glue_job.arn
      }
    ]
  })
}


# Lambda permission for process_dynamodb (managed in module)
# Lambda permission for start_glue (managed in module)
# Lambda permission for process_s3 (managed in module)

# Module call for Lambda functions and permissions
module "functions" {
  source                  = "./modules/functions"
  lambda_runtime          = var.lambda_runtime
  process_dynamodb_zip    = var.process_dynamodb_zip
  process_s3_zip          = var.process_s3_zip
  start_glue_zip          = var.start_glue_zip
  lambda_role_arn         = aws_iam_role.lambda_role.arn
  api_gateway_execute_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
