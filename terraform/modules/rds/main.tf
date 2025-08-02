terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "rds-subnet-${var.project_name}-${var.environment}"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "this" {
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  identifier             = "rds-${var.project_name}-${var.environment}"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password_value
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  skip_final_snapshot    = var.skip_final_snap_shot
}