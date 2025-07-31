output "aws_region"      { value = var.region }
output "rds_endpoint"    { value = module.rds.db_endpoint }
output "db_name"         { value = var.db_name }
output "db_username"     { value = var.db_username }
output "rds_ssm_name"    { value = module.rds.rds_ssm_name }
output "stor_bucket_id"  { value = module.s3_stor.bucket_id }
output "env_bucket_id"   { value = module.s3_env.bucket_id }