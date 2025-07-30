variable "environment"        { type = string }
variable "project_name"       { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "sg_db_id"           { type = string }
variable "db_name"            { type = string }
variable "db_username"        { type = string }