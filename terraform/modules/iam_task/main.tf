data "aws_iam_policy_document" "exec_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "exec" {
  name               = "task-exec-${var.project_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.exec_assume.json
}

resource "aws_iam_role_policy_attachment" "exec_policy" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "exec_secret_access" {
  statement {
    sid      = "AllowGetSecretValue"
    actions  = ["secretsmanager:GetSecretValue"]
    resources = [var.rails_master_key]
  }
}

data "aws_iam_policy_document" "env_s3_read" {
  statement {
    sid       = "AllowEnvFileRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.env_bucket_arn}/${var.env_file_name}"]
  }
}

resource "aws_iam_policy" "exec_secret_policy" {
  name   = "exec-secret-${var.project_name}-${var.environment}"
  policy = data.aws_iam_policy_document.exec_secret_access.json
}

resource "aws_iam_policy" "env_s3_read" {
  name   = "env-s3-read-${var.project_name}-${var.environment}"
  policy = data.aws_iam_policy_document.env_s3_read.json
}

resource "aws_iam_role_policy_attachment" "exec_secret_attach" {
  role       = aws_iam_role.exec.name
  policy_arn = aws_iam_policy.exec_secret_policy.arn
}

resource "aws_iam_role_policy_attachment" "exec_env_attach" {
  role       = aws_iam_role.exec.name
  policy_arn = aws_iam_policy.env_s3_read.arn
}

data "aws_iam_policy_document" "env_file_read" {
  statement {
    sid       = "AllowEcsEnvFileAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.env_bucket_arn}/${var.env_file_name}"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.exec.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "env_file" {
  bucket     = var.env_bucket_id
  policy     = data.aws_iam_policy_document.env_file_read.json
}

resource "aws_iam_role" "task" {
  name               = "task-role-${var.project_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.exec_assume.json
}

data "aws_iam_policy_document" "stor_s3_read" {
  statement {
    sid       = "AllowAppS3Read"
    effect    = "Allow"
    actions   = ["s3:GetObject","s3:ListBucket"]
    resources = [var.stor_bucket_arn, "${var.stor_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "stor_s3_read" {
  name   = "stor-s3-read-${var.project_name}-${var.environment}"
  policy = data.aws_iam_policy_document.stor_s3_read.json
}

resource "aws_iam_role_policy_attachment" "stor_attach" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.stor_s3_read.arn
}