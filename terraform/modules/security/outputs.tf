output "sg_alb_id"         { value = aws_security_group.alb.id }
output "sg_next_id"        { value = aws_security_group.next.id }
output "sg_rails_id"       { value = aws_security_group.rails.id }
output "sg_db_id"          { value = aws_security_group.db.id }
output "sg_ecr_vpce_id"    { value = aws_security_group.ecr_vpce.id }
output "sg_cwlogs_vpce_id" { value = aws_security_group.cwlogs_vpce.id }