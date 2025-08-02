output "dns_name"               { value = aws_lb.alb.dns_name }
output "zone_id"                { value = aws_lb.alb.zone_id }
output "https_arn"              { value = aws_lb_listener.https.arn }
output "next_target_group_arn"  { value = aws_lb_target_group.next.arn }
output "rails_target_group_arn" { value = aws_lb_target_group.rails.arn }