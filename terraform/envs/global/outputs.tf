output "zone_id"               { value = aws_route53_zone.primary.zone_id }
output "name_servers"          { value = aws_route53_zone.primary.name_servers }
output "acm_certificate_arn"   { value = aws_acm_certificate.alb.arn }
output "acm_validation_status" { value = aws_acm_certificate_validation.alb.certificate_arn != "" ? "validated" : "pending" }
