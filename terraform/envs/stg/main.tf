terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "kse-hp-tfstate"
    key    = "global/terraform.tfstate"
    region = var.region
  }
}

locals {
  app_params = {
    NEXT_ECR_URL            = module.ecr_next.repository_url
    RAILS_ECR_URL           = module.ecr_rails.repository_url
    CLUSTER_NAME            = module.cluster.cluster_name
    NEXT_TASK_DEF           = module.task_next.task_definition_arn
    RAILS_TASK_DEF          = module.task_rails.task_definition_arn
    NEXT_SERVICE_NAME       = module.service_next.service_name
    RAILS_SERVICE_NAME      = module.service_rails.service_name
    NEXT_CONTAINER_NAME     = module.task_next.container_name
    RAILS_CONTAINER_NAME    = module.task_rails.container_name
    SERVICE_CLOUD_MAP_RAILS = var.service_cloud_map_rails
    PRIVATE_DNS_NAME        = module.private_dns.private_dns_name
  }
}

module "network" {
  source               = "../../modules/network"
  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_azs    = var.public_subnet_azs
  private_subnet_azs   = var.private_subnet_azs
}

module "security" {
  source       = "../../modules/security"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
}

module "vpce" {
  source                  = "../../modules/vpce"
  environment             = var.environment
  project_name            = var.project_name
  region                  = var.region
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = [module.network.private_subnet_ids[0]]
  private_route_table_ids = [module.network.private_route_table_id]
  sg_ecr_vpce_ids         = [module.security.sg_ecr_vpce_id]
  sg_cwlogs_vpce_ids      = [module.security.sg_cwlogs_vpce_id]
  sg_sm_vpce_ids          = [module.security.sg_sm_vpce_id]
}

module "rds" {
  source             = "../../modules/rds"
  environment        = var.environment
  project_name       = var.project_name
  db_name            = var.db_name
  db_username        = var.db_username
  private_subnet_ids = module.network.private_subnet_ids
  sg_db_id           = module.security.sg_db_id
}

module "s3_stor" {
  source          = "../../modules/s3_storage"
  environment     = var.environment
  project_name    = var.project_name
  vpc_endpoint_id = module.vpce.s3_vpc_endpoint_id
}

module "s3_env" {
  source        = "../../modules/s3_env"
  environment   = var.environment
  project_name  = var.project_name
  env_file_name = var.env_file_name
}

module "ecr_next" {
  source          = "../../modules/ecr"
  repository_name = "next-${var.project_name}-${var.environment}"
}

module "ecr_rails" {
  source          = "../../modules/ecr"
  repository_name = "rails-${var.project_name}-${var.environment}"
}

module "cluster" {
  source       = "../../modules/cluster"
  environment  = var.environment
  project_name = var.project_name
}

module "secrets" {
  source       = "../../modules/secrets"
  project_name = var.project_name
}

module "iam" {
  source           = "../../modules/iam_task"
  environment      = var.environment
  project_name     = var.project_name
  env_file_name    = var.env_file_name
  env_bucket_id    = module.s3_env.bucket_id
  env_bucket_arn   = module.s3_env.bucket_arn
  stor_bucket_arn  = module.s3_stor.bucket_arn
  rails_master_key = module.secrets.rails_master_key
}

module "alb" {
  source                = "../../modules/alb"
  environment           = var.environment
  project_name          = var.project_name
  port_next             = var.app_ports[0]
  port_rails            = var.app_ports[1]
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.sg_alb_id
  acm_cert_arn          = data.terraform_remote_state.global.outputs.acm_certificate_arn
}

module "route53_stg" {
  source       = "../../modules/route53"
  name         = var.environment
  zone_id      = data.terraform_remote_state.global.outputs.zone_id
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "route53_stg_api" {
  source       = "../../modules/route53"
  name         = var.api_sub_domain
  zone_id      = data.terraform_remote_state.global.outputs.zone_id
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "awslogs_group_next" {
  source         = "../../modules/awslogs"
  log_group_name = "/ecs/${var.project_name}-${var.environment}-next"
}

module "awslogs_group_rails" {
  source         = "../../modules/awslogs"
  log_group_name = "/ecs/${var.project_name}-${var.environment}-rails"
}

resource "aws_lb_listener_rule" "rails" {
  listener_arn = module.alb.alb_https_arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arn_rails
  }
  condition {
    host_header {
      values = [module.route53_stg_api.fqdn]
    }
  }
}

module "task_next" {
  source             = "../../modules/task"
  family             = "${var.project_name}-${var.environment}-next"
  cpu                = "512"
  memory             = "1024"
  image_uri          = "${module.ecr_next.repository_url}:${var.image_tag}"
  container_port     = 3000
  region             = var.region
  env_file_name      = var.env_file_name
  env_bucket_arn     = module.s3_env.bucket_arn
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  awslogs_group      = module.awslogs_group_next.awslogs_group
}

module "task_rails" {
  source             = "../../modules/task_rails"
  family             = "${var.project_name}-${var.environment}-rails"
  cpu                = "256"
  memory             = "512"
  image_uri          = "${module.ecr_rails.repository_url}:${var.image_tag}"
  container_port     = 3001
  project_name       = var.project_name
  region             = var.region
  env_file_name      = var.env_file_name
  env_bucket_arn     = module.s3_env.bucket_arn
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  awslogs_group      = module.awslogs_group_rails.awslogs_group
  rails_master_key   = module.secrets.rails_master_key
}

module "private_dns" {
  source            = "../../modules/private_dns"
  vpc_id            = module.network.vpc_id
  service_namespace = "pri.${var.domain_name}"
}

module "service_next" {
  source              = "../../modules/service"
  environment         = var.environment
  project_name        = var.project_name
  subnet_ids          = [module.network.private_subnet_ids[0]]
  sg_id               = module.security.sg_next_id
  cluster_id          = module.cluster.cluster_id
  target_group_arn    = module.alb.target_group_arn_next
  task_definition_arn = module.task_next.task_definition_arn
  container_name      = module.task_next.container_name
  container_port      = var.app_ports[0]
  private_dns_id      = module.private_dns.private_dns_id
  service_cloud_map   = var.service_cloud_map_next
  desired_count       = 1
}

module "service_rails" {
  source              = "../../modules/service"
  environment         = var.environment
  project_name        = var.project_name
  subnet_ids          = [module.network.private_subnet_ids[0]]
  sg_id               = module.security.sg_rails_id
  cluster_id          = module.cluster.cluster_id
  target_group_arn    = module.alb.target_group_arn_rails
  task_definition_arn = module.task_rails.task_definition_arn
  container_name      = module.task_rails.container_name
  container_port      = var.app_ports[1]
  private_dns_id      = module.private_dns.private_dns_id
  service_cloud_map   = var.service_cloud_map_rails
  desired_count       = 1
}

module "ssm" {
  source       = "../../modules/ssm"
  project_name = var.project_name
  environment  = var.environment
  app_params   = local.app_params
}