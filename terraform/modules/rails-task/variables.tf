variable "family"             { type = string }
variable "cpu"                { type = string }
variable "memory"             { type = string }
variable "image_uri"          { type = string }
variable "container_port"     { type = number }
variable "project_name"       { type = string }
variable "region"             { type = string }
variable "env_file_name"      { type = string }
variable "env_bucket_arn"     { type = string }
variable "execution_role_arn" { type = string }
variable "task_role_arn"      { type = string }
variable "awslogs_group"      { type = string }

variable "rails_master_key" {
  type = string
  default = ""
}