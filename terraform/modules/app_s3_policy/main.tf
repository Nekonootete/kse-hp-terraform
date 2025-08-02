data "aws_iam_policy_document" "vpce_read" {
  statement {
    sid        = "AllowVPCEndpointAccess"
    effect     = "Allow"
    actions    = ["s3:GetObject","s3:ListBucket"]
    resources  = [var.app_bucket_arn, "${var.app_bucket_arn}/*"]

    principals {
      type = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpce"
      values   = [var.s3_vpce_id]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket      = var.app_bucket_id
  policy      = jsonencode({
    Version   = "2012-10-17"
    Statement = concat(
      jsondecode(data.aws_iam_policy_document.vpce_read.json).Statement
    )
  })
}

