resource "random_id" "bucket_suffix" {
  byte_length = 2
}

# ------------------ S3 Bucket ------------------

# resource "aws_s3_bucket" "frontend" {
#   bucket = "aws-sentiment-frontend-${random_id.bucket_suffix.hex}"
#   acl    = "public-read"

#   website {
#     index_document = "index.html"
#     error_document = "index.html"
#   }

#   tags = {
#     Name = "FrontendBucket"
#   }
# }

resource "aws_s3_bucket" "frontend" {
  bucket = "aws-sentiment-frontend-${random_id.bucket_suffix.hex}"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  tags = {
    Name = "FrontendBucket"
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}


# ------------------ IAM Role for Lambda ------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_comprehend_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/ComprehendFullAccess"
}

# ------------------ DynamoDB Table ------------------
resource "aws_dynamodb_table" "sentiment_table" {
  name           = "SentimentResults"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# ------------------ Lambda Function ------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda_package.zip"
}

resource "aws_lambda_function" "sentiment_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.sentiment_table.name
    }
  }
}
