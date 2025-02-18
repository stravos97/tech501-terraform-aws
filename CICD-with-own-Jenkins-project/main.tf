# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

# Create network infrastructure
module "network" {
  source = "./modules/network"
}

# Create Jenkins server
module "compute" {
  source = "./modules/compute"

  # Network configuration
  jenkins_subnet_id = module.network.jenkins_subnet_id
  app_subnet_id     = module.network.app_subnet_id
  db_subnet_id      = module.network.db_subnet_id

  # Security group configuration
  jenkins_sg_id = aws_security_group.jenkins_sg.id
  app_sg_id     = aws_security_group.app_sg.id
  db_sg_id      = aws_security_group.db_sg.id

  # SSH key configuration
  key_name = var.ssh_key_name

  # Database private IP (needed for app configuration)
  depends_on    = [module.network]
  db_private_ip = module.compute.db_private_ip
}

# Output values
output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = module.compute.jenkins_public_ip
}

output "app_public_ip" {
  description = "Public IP of application server"
  value       = module.compute.app_public_ip
}

output "db_private_ip" {
  description = "Private IP of database server"
  value       = module.compute.db_private_ip
}

output "jenkins_password_command" {
  description = "Command to retrieve Jenkins initial admin password"
  value       = module.compute.jenkins_password_command
}

output "app_url" {
  description = "URL for the Node.js application"
  value       = "http://${module.compute.app_public_ip}"
}

output "jenkins_url" {
  description = "URL for Jenkins web interface"
  value       = "http://${module.compute.jenkins_public_ip}:8080"
}
