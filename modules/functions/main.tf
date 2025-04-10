resource "aws_lambda_function" "process_dynamodb" {
  function_name    = "ProcessDynamoDB"
  runtime          = var.lambda_runtime
  role             = var.lambda_role_arn
  handler          = "process_dynamodb.lambda_handler"
  filename         = var.process_dynamodb_zip
  source_code_hash = filebase64sha256(var.process_dynamodb_zip)
}

resource "aws_lambda_function" "process_s3" {
  function_name    = "ProcessS3"
  runtime          = var.lambda_runtime
  role             = var.lambda_role_arn
  handler          = "process_s3.lambda_handler"
  filename         = var.process_s3_zip
  source_code_hash = filebase64sha256(var.process_s3_zip)
  publish          = true
}

resource "aws_lambda_function" "start_glue" {
  function_name = "StartGlueJob"
  runtime       = var.lambda_runtime
  role          = var.lambda_role_arn
  handler       = "start_glue.lambda_handler"
  filename      = var.start_glue_zip
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_dynamodb.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_execute_arn
}

resource "aws_lambda_permission" "apigw_lambda_glue" {
  statement_id  = "AllowAPIGatewayInvokeGlue"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_glue.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_execute_arn
}

resource "aws_lambda_permission" "apigw_lambda_s3" {
  statement_id  = "AllowAPIGatewayInvokeS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_s3.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_execute_arn
}
