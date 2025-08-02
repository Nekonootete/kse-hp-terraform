resource "random_password" "master" {
  length           = 16
  override_special = true
}

resource "aws_ssm_parameter" "this" {
  name      = "/${ var.project_name }/${ var.environment }/${ var.resource_name }/master_password"
  type      = "SecureString"
  value     = random_password.master.result
  overwrite = true
}
