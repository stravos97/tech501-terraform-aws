# EC2 Instance Configuration
variable "app_instance_name" {
  description = "Name for the app instance"
  type        = string
  default     = "tech501-haashim-sparta-app-vm"
}

variable "db_instance_name" {
  description = "Name for the database instance"
  type        = string
  default     = "tech501-haashim-sparta-db-vm"
}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
  default     = "t3.micro"
}

variable "instance_ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
  default     = "ami-0c1c30571d2dae5c9"
}

variable "enable_public_ip" {
  description = "Associate a public IP address with the instance"
  type        = bool
  default     = true
}

# Security Configuration
variable "ssh_key_name" {
  description = "The name of the EC2 key pair to use"
  type        = string
  default     = "Haashim Laptop"
}

variable "security_group_name" {
  description = "The name of the security group to use"
  type        = string
  default     = "tech501-haashim-sg"
}

variable "protocol" {
  description = "The protocol to use for the security group rule"
  type        = string
  default     = "tcp"
}

# Access Control
variable "ssh_allowed_cidr" {
  description = "The CIDR block to allow SSH access"
  type        = string
  default     = "63.135.76.255/32"
}

variable "public_access_cidr" {
  description = "The CIDR block to allow all traffic"
  type        = string
  default     = "0.0.0.0/0"
}

variable "private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
  default     = "/Users/haashimalvi/.ssh/id_rsa"
}
