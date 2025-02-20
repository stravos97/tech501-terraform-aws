output "app_instance_public_ip" {
  description = "Public IP address of the app instance"
  value       = aws_instance.app_instance.public_ip
}

output "app_instance_private_ip" {
  description = "Private IP address of the app instance"
  value       = aws_instance.app_instance.private_ip
}

output "db_instance_public_ip" {
  description = "Public IP address of the db instance"
  value       = aws_instance.db_instance.public_ip
}

output "db_instance_private_ip" {
  description = "Private IP address of the db instance"
  value       = aws_instance.db_instance.private_ip
}
