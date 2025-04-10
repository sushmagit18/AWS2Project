output "process_dynamodb_invoke_arn" {
  description = "Invoke ARN for the process_dynamodb Lambda function"
  value       = aws_lambda_function.process_dynamodb.invoke_arn
}

output "process_s3_invoke_arn" {
  description = "Invoke ARN for the process_s3 Lambda function"
  value       = aws_lambda_function.process_s3.invoke_arn
}

output "start_glue_invoke_arn" {
  description = "Invoke ARN for the start_glue Lambda function"
  value       = aws_lambda_function.start_glue.invoke_arn
}
