variable "environment"          { type = string }
variable "project_name"         { type = string }
variable "db_name"              { type = string }
variable "db_username"          { type = string }
variable "skip_final_snap_shot" { type = bool }
variable "private_subnet_ids"   { type = list(string) }
variable "db_sg_id"             { type = string }

variable "db_password_value"          {
  type = string
  sensitive = true
}