terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Project     = var.project_name
    Environment = "global"
  }

  domains = distinct(concat([var.domain], var.san))

  dvo_by_domain = {
    for dvo in aws_acm_certificate.alb.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
}

resource "aws_route53_zone" "primary" {
  name    = var.domain
  comment = "${var.project_name} hosted zone"
  tags    = local.tags
}

resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain
  subject_alternative_names = var.san
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = local.tags
}

resource "aws_route53_record" "acm_validation" {
  for_each = toset(local.domains)

  zone_id         = aws_route53_zone.primary.zone_id
  name            = local.dvo_by_domain[each.key].name
  type            = local.dvo_by_domain[each.key].type
  records         = [local.dvo_by_domain[each.key].record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for r in values(aws_route53_record.acm_validation) : r.fqdn]
}
