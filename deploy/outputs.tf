# TF Output: output of a certain variable or attribute on one of the resources
output "db_host" {
  value = aws_db_instance.main.address # internal network address of db server, allows connect to bastion
}

output "bastion_host" {
  value = aws_instance.bastion.public_dns # public dns name of bastion host
}

output "api_endpoint" {
  value = aws_lb.api.dns_name # outputs dns name to access app
}
