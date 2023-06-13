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