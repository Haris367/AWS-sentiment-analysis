output "s3_bucket_website_url" {
  value = aws_s3_bucket.frontend.website_endpoint
}

output "lambda_function_name" {
  value = aws_lambda_function.sentiment_lambda.function_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.sentiment_table.name
}