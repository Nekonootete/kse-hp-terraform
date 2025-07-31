variable "environment"             { type = string }
variable "project_name"            { type = string }
variable "region"                  { type = string }
variable "vpc_cidr"                { type = string }
variable "public_subnet_cidrs"     { type = list(string) }
variable "private_subnet_cidrs"    { type = list(string) }
variable "public_subnet_azs"       { type = list(string) }
variable "private_subnet_azs"      { type = list(string) }
variable "app_ports"               { type = list(number) }
variable "db_name"                 { type = string }
variable "db_username"             { type = string }
variable "env_file_name"           { type = string }
variable "api_sub_domain"          { type = string }
variable "domain_name"             { type = string }
variable "service_cloud_map_next"  { type = string }
variable "service_cloud_map_rails" { type = string }

variable "image_tag" {
  type    = string
  default = "latest"
}