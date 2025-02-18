# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# EC2 Instance Configuration
variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "jenkins-server"
}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
  default     = "t3.small"  # For Java app with MySQL
}

variable "ubuntu_ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID"
  type        = string
  default     = "ami-0905a3c97561e0b69"  # Ubuntu 22.04 LTS AMI ID for eu-west-1
}

# Security Configuration
variable "ssh_key_name" {
  description = "The name of the EC2 key pair to use"
  type        = string
  default     = "Haashim Laptop"
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "jenkins-security-group"
}

# Access Control
variable "ssh_allowed_cidr" {
  description = "The CIDR block to allow SSH access"
  type        = string
  default     = "0.0.0.0/0"  # Should be restricted to your IP in production
}

variable "public_access_cidr" {
  description = "The CIDR block to allow public access"
  type        = string
  default     = "0.0.0.0/0"
}

# Protocol Configuration
variable "protocol" {
  description = "The protocol to use for security group rules"
  type        = string
  default     = "tcp"
}
