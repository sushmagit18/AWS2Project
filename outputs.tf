output "api_url" {
  description = "Base URL for the API Gateway deployment"
  value       = aws_api_gateway_deployment.deployment.invoke_url
}

output "glue_job_name" {
  description = "Name of the Glue job"
  value       = aws_glue_job.glue_job.name
}

output "s3_api_url" {
  description = "API endpoint URL for S3 service (listing and uploads)"
  value       = "${aws_api_gateway_deployment.deployment.invoke_url}/s3"
}

output "data_bucket_name" {
  description = "Name of the S3 bucket for Glue scripts and general services"
  value       = aws_s3_bucket.data_bucket.bucket
}

output "upload_bucket_name" {
  description = "Name of the S3 bucket used exclusively for file uploads via ProcessS3"
  value       = aws_s3_bucket.upload_bucket.bucket
}

output "upload_api_url" {
  description = "API endpoint URL for S3 upload service (POST method to obtain a pre-signed URL)"
  value       = "${aws_api_gateway_deployment.deployment.invoke_url}/s3"
}

