data "aws_region" "current" {}

data "aws_vpc" "selected" {
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected]
  }
  tags = {
    Tier = "private"
  }
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


data "archive_file" "lambda-index-photos" {
  type        = "zip"
  source_file = "../Lambdas/LF1/LF1.py"
  output_path = var.LF1_payload_name
}

data "archive_file" "lambda-search-photos" {
  type        = "zip"
  source_file = "../Lambdas/LF2/LF2.py"
  output_path = var.LF2_payload_name
}