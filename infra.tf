provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.aws_region
}

resource "aws_s3_bucket" "english-bucket" {
  bucket = var.en_bucket_name
}

resource "aws_s3_bucket" "spanish-bucket" {
  bucket = var.es_bucket_name
}

resource "aws_s3_bucket" "portuguese-bucket" {
  bucket = var.pt_bucket_name
}

resource "aws_s3_object" "en_html_upload" {
  bucket       = aws_s3_bucket.english-bucket.bucket
  key          = "index.html"
  source       = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Appcontent/index.html"
  content_type = "text/html"
}

/* resource "aws_s3_object" "en_css_upload" {
  bucket       = aws_s3_bucket.english-bucket.bucket
  key          = "index.css"
  source       = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Appcontent/index.css"
  content_type = "text/css"
} */

resource "aws_s3_object" "es_html_upload" {
  bucket       = aws_s3_bucket.spanish-bucket.bucket
  key          = "index.html"
  source       = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Appcontent/index.html"
  content_type = "text/html"
}

/* resource "aws_s3_object" "es_css_upload" {
  bucket       = aws_s3_bucket.spanish-bucket.bucket
  key          = "index.css"
  source       = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Appcontent/index.css"
  content_type = "text/css"
} */

resource "aws_s3_object" "pt_html_upload" {
  bucket       = aws_s3_bucket.portuguese-bucket.bucket
  key          = "index.html"
  source       = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Appcontent/index.html"
  content_type = "text/html"
}

/* resource "aws_s3_object" "pt_css_upload" {
  bucket       = aws_s3_bucket.portuguese-bucket.bucket
  key          = "index.css"
  source       = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Appcontent/pt/index.css"
  content_type = "text/css"
} */

resource "aws_cloudfront_origin_access_control" "OriginRequest" {
  name                              = "s3-cloudfront-oac"
  description                       = "Access to S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "CDN_s3_dist" {
  origin {
    domain_name              = aws_s3_bucket.english-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.OriginRequest.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Accept-Language"]

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.terraform_lambda_func.qualified_arn
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 1
    max_ttl                = 1
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
resource "aws_s3_bucket_policy" "english-policy" {
  bucket = aws_s3_bucket.english-bucket.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access_english.json
}

data "aws_iam_policy_document" "cloudfront_oac_access_english" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.english-bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.CDN_s3_dist.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "spanish-policy" {
  bucket = aws_s3_bucket.spanish-bucket.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access_spanish.json
}

data "aws_iam_policy_document" "cloudfront_oac_access_spanish" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.spanish-bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.CDN_s3_dist.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "portuguese-policy" {
  bucket = aws_s3_bucket.portuguese-bucket.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access_portuguese.json
}

data "aws_iam_policy_document" "cloudfront_oac_access_portuguese" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.portuguese-bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.CDN_s3_dist.arn]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "Detection_Lambda_Function_Role"
  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        },
        "Effect": "Allow",
        "Sid": ""
    }
    ]
    }
    EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for lambda role"
  policy      = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
    }
    ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_file = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Lambda_Function/lambdafunc.py"
  output_path = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Lambda_Function/lambdafunc.zip"
}

/* resource "aws_lambda_permission" "allow_cloudfront" {
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:InvokeFunction"
  function_name = "origin-function"  # Check this matches exactly
  principal     = "cloudfront.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.CDN_s3_dist.arn
} */

resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "/Users/admin/Documents/Projects AWS/ContentTranslationPipeline/Lambda_Function/lambdafunc.zip"
  function_name = "ContentTranslationpipeline"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambdafunc.handler"
  runtime       = "python3.12"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  publish       = true
}