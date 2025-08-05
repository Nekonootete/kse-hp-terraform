output "alb_sg_id"          { value = aws_security_group.alb.id }
output "next_sg_id"         { value = aws_security_group.next.id }
output "rails_sg_id"        { value = aws_security_group.rails.id }
output "db_sg_id"           { value = aws_security_group.db.id }
output "ecr_vpce_sg_id"     { value = aws_security_group.ecr_vpce.id }
output "cwlogs_vpce_sg_id"  { value = aws_security_group.cwlogs_vpce.id }
output "sm_vpce_sg_id"      { value = aws_security_group.sm_vpce.id }
output "ssmm_vpce_sg_id"    { value = aws_security_group.ssmm_vpce.id }