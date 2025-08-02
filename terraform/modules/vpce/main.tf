resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = {
    Name = "s3-endpoint-${var.project_name}-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.sg_ecr_vpce_ids
  private_dns_enabled = true

  tags = {
    Name = "ecr_api-${var.project_name}-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.sg_ecr_vpce_ids
  private_dns_enabled = true

  tags = {
    Name = "ecr_dkr-${var.project_name}-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "cwlogs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.sg_cwlogs_vpce_ids
  private_dns_enabled = true

  tags = {
    Name = "cwlogs-${var.project_name}-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.sg_sm_vpce_ids
  private_dns_enabled = true

  tags = {
    Name = "sm-${var.project_name}-${var.environment}"
  }
}