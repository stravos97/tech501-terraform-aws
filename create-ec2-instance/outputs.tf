output "app_instance_public_ip" {
  description = "Public IP address of the app EC2 instance"
  value       = aws_instance.app_instance.public_ip
}

output "db_instance_public_ip" {
  description = "Public IP address of the database EC2 instance"
  value       = aws_instance.db_instance.public_ip
}
