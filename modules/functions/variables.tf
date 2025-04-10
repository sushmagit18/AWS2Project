variable "lambda_runtime" {
  description = "Runtime environment for Lambda functions"
  type        = string
}

variable "process_dynamodb_zip" {
  description = "Filename for the process_dynamodb Lambda zip file"
  type        = string
}

variable "process_s3_zip" {
  description = "Filename for the process_s3 Lambda zip file"
  type        = string
}

variable "start_glue_zip" {
  description = "Filename for the start_glue Lambda zip file"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM Role ARN for Lambda functions"
  type        = string
}

variable "api_gateway_execute_arn" {
  description = "API Gateway execute ARN (with wildcards) for lambda permissions"
  type        = string
}
