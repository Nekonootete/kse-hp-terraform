resource "aws_secretsmanager_secret" "rails_master_key" {
  name = "${project_name}/rails/production-master-key"
}

resource "aws_secretsmanager_secret_version" "rails_master_key" {
  secret_id     = aws_secretsmanager_secret.rails_master_key.id
  secret_binary = filebase64("${path.module}/config/credentials/production.key")
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = templatefile(
    "${path.module}/container.json.tftpl",
    {
      family           = var.family
      image_uri        = var.image_uri
      container_port   = var.container_port
      env_file_name    = var.env_file_name
      env_bucket_arn   = var.env_bucket_arn
      awslogs-group    = var.awslogs-group
      region           = var.region
      rails_master_key = aws_secretsmanager_secret.rails_master_key.arn
    }
  )
}