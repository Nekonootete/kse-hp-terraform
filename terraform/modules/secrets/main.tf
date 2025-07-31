resource "aws_secretsmanager_secret" "rails_master_key" {
  name = "${ var.project_name }/rails/production-master-key"
}

resource "aws_secretsmanager_secret_version" "rails_master_key" {
  secret_id     = aws_secretsmanager_secret.rails_master_key.id
  secret_string = file("${path.module}/../../envs/stg/config/credentials/production.key")
}
