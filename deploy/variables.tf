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

variable "ecr_image_api" {
  description = "ECR image for API"
  default     = "178537739852.dkr.ecr.us-east-1.amazonaws.com/recipe-app-api-devops:latest" # pull from latest tag
}

variable "ecr_image_proxy" {
  description = "ECR image for proxy"
  default     = "178537739852.dkr.ecr.us-east-1.amazonaws.com/recipe-app-api-proxy:latest"
}

variable "django_secret_key" {
  description = "Secret key for Django app"
}

variable "dns_zone_name" {
  description = "Custom domain name."
  default     = "ikehunter.cloud"
}

variable "subdomain" {
  description = "Subdomain per environment."
  type        = map(string)
  default = {
    production = "api"
    staging    = "api.staging"
    dev        = "api.dev"
  }
}
