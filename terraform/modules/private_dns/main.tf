resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = var.name
  description = "Private DNS namespace for ECS services"
  vpc         = var.vpc_id
}
