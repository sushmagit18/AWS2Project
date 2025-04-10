variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "data_bucket_name" {
  description = "Name of the S3 bucket for Glue scripts and general services"
  type        = string
  default     = "sushma-data-storage-0909"
}

variable "upload_bucket_name" {
  description = "Name of the S3 bucket used exclusively for file uploads"
  type        = string
  default     = "sushma-upload-storage-0909"
}

variable "process_dynamodb_zip" {
  description = "Filename for the process_dynamodb Lambda zip file"
  type        = string
  default     = "process_dynamodb.zip"
}

variable "process_s3_zip" {
  description = "Filename for the process_s3 Lambda zip file"
  type        = string
  default     = "process_s3.zip"
}

variable "start_glue_zip" {
  description = "Filename for the start_glue Lambda zip file"
  type        = string
  default     = "start_glue.zip"
}

variable "lambda_runtime" {
  description = "Runtime environment for Lambda functions"
  type        = string
  default     = "python3.8"
}

variable "glue_job_name" {
  description = "Name of the AWS Glue job"
  type        = string
  default     = "HelloWorldJob"
}

variable "glue_script_location" {
  description = "Relative path in the data bucket for the Glue job script"
  type        = string
  default     = "scripts/glue_script.py"
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "API"
}

variable "api_stage" {
  description = "Deployment stage for API Gateway"
  type        = string
  default     = "prod"
}
