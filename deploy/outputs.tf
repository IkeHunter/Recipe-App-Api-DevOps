# TF Output: output of a certain variable or attribute on one of the resources
output "db_host" {
  value = aws_db_instance.main.address # internal network address of db server, allows connect to bastion
}