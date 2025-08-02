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
    NEXT_ECR_URL              = module.next_ecr.repository_url
    RAILS_ECR_URL             = module.rails_ecr.repository_url
    CLUSTER_NAME              = module.cluster.cluster_name
    NEXT_TASK_DEF             = module.next_task.task_definition_arn
    RAILS_TASK_DEF            = module.rails_task.task_definition_arn
    NEXT_FIRST_SERVICE_NAME   = module.next_first_service.name
    NEXT_SECOND_SERVICE_NAME  = module.next_second_service.name
    RAILS_FIRST_SERVICE_NAME  = module.rails_first_service.name
    RAILS_SECOND_SERVICE_NAME = module.rails_second_service.name
    NEXT_CONTAINER_NAME       = module.next_task.container_name
    RAILS_CONTAINER_NAME      = module.rails_task.container_name
    RAILS_SERVICE_CLOUD_MAP   = var.rails_service_cloud_map
    PRIVATE_DNS_NAME          = module.private_dns.name
  }
}

module "ssm" {
  source       = "../../modules/ssm"
  project_name = var.project_name
  environment  = var.environment
  app_params   = local.app_params
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
  private_subnet_ids      = module.network.private_subnet_ids
  private_route_table_ids = [module.network.private_route_table_id]
  sg_ecr_vpce_ids         = [module.security.sg_ecr_vpce_id]
  sg_cwlogs_vpce_ids      = [module.security.sg_cwlogs_vpce_id]
  sg_sm_vpce_ids          = [module.security.sg_sm_vpce_id]
}

module "alb" {
  source                = "../../modules/alb"
  environment           = var.environment
  project_name          = var.project_name
  port_next             = var.app_ports[0]
  port_rails            = var.app_ports[1]
  cdn_fqdn              = var.cdn_fqdn
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.sg_alb_id
  acm_cert_arn          = data.terraform_remote_state.global.outputs.acm_certificate_arn
}

module "stg_route53" {
  source       = "../../modules/route53"
  fqdn         = var.fqdn
  zone_id      = data.terraform_remote_state.global.outputs.zone_id
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "stg_cdn_route53" {
  source       = "../../modules/route53"
  fqdn         = var.cdn_fqdn
  zone_id      = data.terraform_remote_state.global.outputs.zone_id
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "db_password" {
  source        = "../../modules/password_ssm"
  project_name  = var.project_name
  environment   = var.environment
  resource_name = "rds"
}

module "db" {
  source               = "../../modules/rds"
  environment          = var.environment
  project_name         = var.project_name
  db_name              = var.db_name
  db_username          = var.db_username
  skip_final_snap_shot = true
  private_subnet_ids   = module.network.private_subnet_ids
  db_sg_id             = module.security.db_sg_id
  db_password_value    = module.db_password.value
}

module "app_bucket" {
  source          = "../../modules/app_s3"
  environment     = var.environment
  project_name    = var.project_name
  vpc_endpoint_id = module.vpce.s3_vpc_endpoint_id
}

module "env_bucket" {
  source        = "../../modules/env_s3"
  environment   = var.environment
  project_name  = var.project_name
  env_file_name = var.env_file_name
}

module "cloudfront" {
  source                           = "../../modules/cloudfront"
  environment                      = var.environment
  project_name                     = var.project_name
  domain_name                      = var.domain_name
  fqdn                             = var.fqdn
  cdn_fqdn                         = var.cdn_fqdn
  alb_dns_name                     = module.alb.dns_name
  app_bucket_domain_name           = module.app_bucket.bucket_domain_name
  app_bucket_regional_domain_name  = module.app_bucket.bucket_regional_domain_name
}

module "app_bucket_policy" {
  source              = "../../modules/s3_policy"
  app_bucket_id       = module.app_bucket.id
  app_bucket_arn      = module.app_bucket.arn
  vpc_endpoint_id     = module.vpce.s3_vpc_endpoint_id
}

module "next_ecr" {
  source          = "../../modules/ecr"
  repository_name = "next-${var.project_name}-${var.environment}"
}

module "rails_ecr" {
  source          = "../../modules/ecr"
  repository_name = "rails-${var.project_name}-${var.environment}"
}

module "cluster" {
  source       = "../../modules/cluster"
  environment  = var.environment
  project_name = var.project_name
}

module "rails_master_key" {
  source    = "../../modules/secrets"
  name      = var.project_name
  file_path = "${path.root}/config/credentials/production.key"
}

module "task_iam" {
  source               = "../../modules/task_iam"
  environment          = var.environment
  project_name         = var.project_name
  env_file_name        = var.env_file_name
  app_bucket_arn       = module.app_bucket.arn
  env_bucket_id        = module.env_bucket.id
  env_bucket_arn       = module.env_bucket.arn
  rails_master_key_arn = module.rails_master_key.arn
}

module "env_bucket_policy" {
  source        = "../../modules/env_s3_policy"
  env_file_name = var.env_file_name
  env_bucket_id = module.env_bucket.id
  env_bucket_arn = module.env_bucket.arn
}

module "next_log_group" {
  source         = "../../modules/cloudwatch"
  name = "/ecs/${var.project_name}-${var.environment}-next"
}

module "rails_log_group" {
  source         = "../../modules/cloudwatch"
  name = "/ecs/${var.project_name}-${var.environment}-rails"
}

module "next_task" {
  source             = "../../modules/task"
  family             = "${var.project_name}-${var.environment}-next"
  cpu                = "512"
  memory             = "1024"
  image_uri          = "${module.next_ecr.repository_url}:${var.image_tag}"
  container_port     = 3000
  region             = var.region
  env_file_name      = var.env_file_name
  env_bucket_arn     = module.env_bucket.arn
  exec_role_arn      = module.task_iam.exec_role_arn
  task_role_arn      = module.task_iam.task_role_arn
  log_group_name     = module.next_log_group.name
}

module "rails_task" {
  source               = "../../modules/rails_task"
  family               = "${var.project_name}-${var.environment}-rails"
  cpu                  = "256"
  memory               = "512"
  image_uri            = "${module.rails_ecr.repository_url}:${var.image_tag}"
  container_port       = 3001
  project_name         = var.project_name
  region               = var.region
  env_file_name        = var.env_file_name
  env_bucket_arn       = module.env_bucket.arn
  exec_role_arn        = module.task_iam.exec_role_arn
  task_role_arn        = module.task_iam.task_role_arn
  log_group_name       = module.rails_log_group.name
  rails_master_key_arn = module.rails_master_key.arn
}

module "private_dns" {
  source            = "../../modules/private_dns"
  vpc_id            = module.network.vpc_id
  fqdn              = "pri.${var.domain_name}"
}

module "next_first_service" {
  source              = "../../modules/service"
  environment         = var.environment
  project_name        = var.project_name
  service_cloud_map   = var.next_service_cloud_map
  subnet_ids          = [module.network.private_subnet_ids[0]]
  sg_id               = module.security.next_sg_id
  cluster_id          = module.cluster.id
  target_group_arn    = module.alb.next_target_group_arn
  task_definition_arn = module.next_task.task_definition_arn
  container_name      = module.next_task.container_name
  container_port      = var.app_ports[0]
  private_dns_id      = module.private_dns.private_dns_id
  desired_count       = 1
}

module "next_second_service" {
  source              = "../../modules/service"
  environment         = var.environment
  project_name        = var.project_name
  service_cloud_map   = var.next_service_cloud_map
  subnet_ids          = [module.network.private_subnet_ids[1]]
  sg_id               = module.security.next_sg_id
  cluster_id          = module.cluster.id
  target_group_arn    = module.alb.next_target_group_arn
  task_definition_arn = module.next_task.task_definition_arn
  container_name      = module.next_task.container_name
  container_port      = var.app_ports[0]
  private_dns_id      = module.private_dns.private_dns_id
  desired_count       = 1
}

module "rails_first_service" {
  source              = "../../modules/service"
  environment         = var.environment
  project_name        = var.project_name
  service_cloud_map   = var.rails_service_cloud_map
  subnet_ids          = [module.network.private_subnet_ids[0]]
  sg_id               = module.security.rails_sg_id
  cluster_id          = module.cluster.id
  target_group_arn    = module.alb.rails_target_group_arn
  task_definition_arn = module.rails_task.task_definition_arn
  container_name      = module.rails_task.container_name
  container_port      = var.app_ports[1]
  private_dns_id      = module.private_dns.private_dns_id
  desired_count       = 1
}

module "rails_second_service" {
  source              = "../../modules/service"
  environment         = var.environment
  project_name        = var.project_name
  service_cloud_map   = var.rails_service_cloud_map
  subnet_ids          = [module.network.private_subnet_ids[1]]
  sg_id               = module.security.rails_sg_id
  cluster_id          = module.cluster.id
  target_group_arn    = module.alb.rails_target_group_arn
  task_definition_arn = module.rails_task.task_definition_arn
  container_name      = module.rails_task.container_name
  container_port      = var.app_ports[1]
  private_dns_id      = module.private_dns.private_dns_id
  desired_count       = 1
}
