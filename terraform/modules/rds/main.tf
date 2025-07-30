terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

resource "random_password" "master" {
  length           = 16
  override_special = true
}

resource "aws_ssm_parameter" "db_password" {
  name      = "/${var.project_name}/${var.environment}/rds/master_password"
  type      = "SecureString"
  value     = random_password.master.result
  overwrite = true
}

resource "aws_db_subnet_group" "this" {
  name       = "rds-subnet-${var.environment}"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "this" {
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  identifier           = "rds-${var.environment}"
  db_name              = var.db_name
  username             = var.db_username
  password             = aws_ssm_parameter.db_password.value
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.sg_db_id]
  skip_final_snapshot  = true
}

