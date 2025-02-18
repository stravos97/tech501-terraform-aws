output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "jenkins_subnet_id" {
  description = "ID of the Jenkins subnet (first public subnet)"
  value       = aws_subnet.public_subnets[0].id
}

output "app_subnet_id" {
  description = "ID of the application subnet (second public subnet)"
  value       = aws_subnet.public_subnets[1].id
}

output "db_subnet_id" {
  description = "ID of the database subnet (third public subnet)"
  value       = aws_subnet.public_subnets[2].id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = var.public_subnet_cidrs
}

output "db_subnet_cidr" {
  description = "CIDR block of the database subnet"
  value       = var.public_subnet_cidrs[2]
}
