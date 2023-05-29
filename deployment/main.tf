/*
That terraform project will deploy aws smart photo album
including following resources:
 * VPC
 * s3 buckets:
   - frontend
   - photo storage
 * API gateway
 * elk service
 * lambda function:
  - image indexing
  - search photo
*/

/*
Todo:
* s3 lifecycle configuration:
  - specify
  - define
*/

# Create a VPC
resource "aws_vpc" "album_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = var.default_tags
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.album_vpc.id
  cidr_block = "10.0.1.0/24"
  tags       = var.default_tags
}
# Create S3 bucket

resource "aws_s3_bucket" "album_frontend" {
  bucket_prefix = "sobolev_family_album_frontend_"

  tags = var.default_tags
}

resource "aws_s3_bucket_website_configuration" "album_frontend" {
  bucket = aws_s3_bucket.album_frontend.id
  index_document {
    suffix = "index.html"
  }
  tags = var.default_tags
}

resource "aws_s3_bucket" "album_mediastorage" {
  bucket_prefix = "sobolev_family_album_media_storage_"
  tags          = var.default_tags
}

resource "aws_s3_bucket_public_access_block" "album_mediastorage" {
  bucket = aws_s3_bucket.album_mediastorage.id
}

# Define lambdas
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.id
}

resource "aws_lambda_function" "index-photos" {
  function_name    = "LF1-index-photos"
  role             = aws_iam_role.iam_for_lambda.arn
  filename         = var.LF1_payload_name
  source_code_hash = data.archive_file.lambda-index-photos.output_base64sha256

  runtime = "python3.10"
  handler = "lambda_handler"

  vpc_config {
    subnet_ids = [
      data.aws_subnets.selected.ids[0],
      data.aws_subnets.selected.ids[1],
    ]
    security_group_ids = [aws_security_group.elasticsearch_sg.id]
  }
}

resource "aws_lambda_function" "search-photos" {
  function_name    = "LF2-search-photos"
  role             = aws_iam_role.iam_for_lambda.arn
  filename         = var.LF2_payload_name
  source_code_hash = data.archive_file.lambda-search-photos.output_base64sha256

  runtime = "python3.10"
  handler = "lambda_handler"
  vpc_config {
    subnet_ids = [
      data.aws_subnets.selected.ids[0],
      data.aws_subnets.selected.ids[1],
    ]
    security_group_ids = [aws_security_group.elasticsearch_sg.id]
  }
}

#define s3 notification
resource "aws_s3_bucket_notification" "upload_photo" {
  bucket = aws_s3_bucket.album_mediastorage.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.index-photos.arn
    events = ["s3:ObjectCreated:.*"]
  }
}

# define security group
resource "aws_security_group" "elasticsearch_sg" {
  name   = "album_sg-${var.elk_domain}"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = [
      data.aws_vpc.selected.cidr_block
    ]
  }

}

# define elk
resource "aws_elasticsearch_domain" "album_elasticsearch" {
  domain_name = var.elk_domain

  cluster_config {
    instance_type = "s3.small.search"
  }

  vpc_options {
    subnet_ids = [
      data.aws_subnets.selected.ids[0],
      data.aws_subnets.selected.ids[1],
    ]
  }
  security_group_ids = [aws_security_group.elasticsearch_sg.id]

}

#Define API gateway
resource "aws_apigatewayv2_api" "album_httpapi" {
  name          = "smart_album_httpapi"
  protocol_type = "HTTP"
}
