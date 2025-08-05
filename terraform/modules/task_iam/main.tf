data "aws_iam_policy_document" "exec_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "exec_rails_secret_access" {
  statement {
    sid      = "AllowGetSecretValue"
    actions  = ["secretsmanager:GetSecretValue"]
    resources = [var.rails_master_key_arn]
  }
}

data "aws_iam_policy_document" "env_bucket_read" {
  statement {
    sid       = "AllowEnvFileRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.env_bucket_arn}/${var.env_file_name}"]
  }
}

data "aws_iam_policy_document" "app_bucket_read" {
  statement {
    sid       = "AllowAppS3Read"
    effect    = "Allow"
    actions   = ["s3:GetObject","s3:ListBucket"]
    resources = [var.app_bucket_arn, "${var.app_bucket_arn}/*"]
  }
}

data "aws_iam_policy_document" "ecs_exec_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "exec" {
  name               = "task-exec-${var.project_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.exec_assume.json
}

resource "aws_iam_role" "task" {
  name               = "task-role-${var.project_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.exec_assume.json
}

resource "aws_iam_policy" "exec_rails_secret_access_policy" {
  name   = "exec-rails-secret-${var.project_name}-${var.environment}"
  policy = data.aws_iam_policy_document.exec_rails_secret_access.json
}

resource "aws_iam_policy" "env_bucket_read" {
  name   = "env-s3-read-${var.project_name}-${var.environment}"
  policy = data.aws_iam_policy_document.env_bucket_read.json
}

resource "aws_iam_policy" "app_bucket_read" {
  name   = "app-s3-read-${var.project_name}-${var.environment}"
  policy = data.aws_iam_policy_document.app_bucket_read.json
}

resource "aws_iam_policy" "ecs_exec_ssm" {
  name   = "ecs_exec_ssm-${var.project_name}-${var.environment}"
  policy = data.aws_iam_policy_document.ecs_exec_ssm.json
}

resource "aws_iam_role_policy_attachment" "exec_policy" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "exec_rails_secret_access_attach" {
  role       = aws_iam_role.exec.name
  policy_arn = aws_iam_policy.exec_rails_secret_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "exec_env_bucket_attach" {
  role       = aws_iam_role.exec.name
  policy_arn = aws_iam_policy.env_bucket_read.arn
}

resource "aws_iam_role_policy_attachment" "task_app_bucket_attach" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.app_bucket_read.arn
}

resource "aws_iam_role_policy_attachment" "task_ecs_exec_ssm_attach" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.ecs_exec_ssm.arn
}