output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP of Jenkins server"
  value       = aws_instance.jenkins.private_ip
}

output "app_public_ip" {
  description = "Public IP of application server"
  value       = aws_instance.app.public_ip
}

output "app_private_ip" {
  description = "Private IP of application server"
  value       = aws_instance.app.private_ip
}

output "db_private_ip" {
  description = "Private IP of database server"
  value       = aws_instance.db.private_ip
}

output "jenkins_instance_id" {
  description = "Instance ID of Jenkins server"
  value       = aws_instance.jenkins.id
}

output "app_instance_id" {
  description = "Instance ID of application server"
  value       = aws_instance.app.id
}

output "db_instance_id" {
  description = "Instance ID of database server"
  value       = aws_instance.db.id
}

output "jenkins_password_command" {
  description = "Command to retrieve Jenkins initial admin password"
  value       = "ssh -i '${var.key_name}.pem' ubuntu@${aws_instance.jenkins.public_ip} 'cat jenkins-password.txt'"
}
