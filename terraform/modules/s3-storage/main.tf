resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.environment}"

  tags = {
    Name        = "assets-${var.environment}"
    Environment = var.environment
  }
}


resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "vpce_read" {
  statement {
    sid        = "AllowVPCEndpointAccess"
    effect     = "Allow"
    actions    = ["s3:GetObject","s3:ListBucket"]
    resources  = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    principals {
      type = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpce"
      values   = [var.vpc_endpoint_id]
    }
  }
}

data "aws_iam_policy_document" "cf_read" {
  statement {
    sid       = "AllowCloudFront"
    effect     = "Allow"
    actions   = ["s3:GetObject"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cf" {
  bucket      = aws_s3_bucket.this.id
  depends_on  = [aws_s3_bucket_public_access_block.this]
  policy      = jsonencode({
    Version   = "2012-10-17"
    Statement = concat(
      jsondecode(data.aws_iam_policy_document.vpce_read.json).Statement,
      jsondecode(data.aws_iam_policy_document.cf_read.json).Statement
    )
  })
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.project_name}-${var.environment}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled = true

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.this.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.this.id}"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}