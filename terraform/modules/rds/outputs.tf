output "db_endpoint"       { value = aws_db_instance.this.address }
output "rds_ssm_name"      { value = aws_ssm_parameter.db_password.name }
output "db_identifier"     { value = aws_db_instance.this.id }