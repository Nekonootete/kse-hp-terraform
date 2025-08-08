resource "aws_route53_record" "this" {
  zone_id = var.zone_id
  name    = length(split(".", var.fqdn)) == 2 ? "" : split(".", var.fqdn)[0]
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
