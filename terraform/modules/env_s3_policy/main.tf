data "aws_iam_policy_document" "env_file_read" {
  statement {
    sid       = "AllowEcsEnvFileAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.env_bucket_arn}/${var.env_file_name}"]

    principals {
      type        = "AWS"
      identifiers = [var.exec_role_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "env_file" {
  bucket     = var.env_bucket_id
  policy     = data.aws_iam_policy_document.env_file_read.json
}