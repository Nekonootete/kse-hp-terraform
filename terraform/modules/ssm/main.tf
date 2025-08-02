resource "aws_ssm_parameter" "this" {
  for_each = var.app_params

  name        = "/${ var.project_name }/${ var.environment }/${ each.key }"
  type        = "String"
  value       = each.value

  overwrite   = true
  tier        = "Standard"

  tags = {
    Service   = "${ var.project_name }-${ var.environment }"
    Env       = "${ var.environment }"
    Managed   = "terraform"
  }
}