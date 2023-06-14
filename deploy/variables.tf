variable "prefix" {
  default = "raad" # recipe app api devops
}

variable "project" {
  default = "recipe-app-api-devops"
}

variable "contact" {
  default = "web@ikehunter.dev"
}

variable "db_username" {
  description = "Username for the RDS postgres instance"
}

variable "db_password" {
  description = "Password for the RDS postgres instance"
}

variable "bastion_key_name" {
  default = "recipe-app-api-devops-bastion" # same name as set up in aws console ec2 key pairs
}