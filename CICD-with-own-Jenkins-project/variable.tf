# SSH Configuration
variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  default     = "Haashim Laptop"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"  # Should be restricted to your IP in production
}

# Environment
variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "tech501"
}

# Region
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

# Instance Types
variable "jenkins_instance_type" {
  description = "Instance type for Jenkins server"
  type        = string
  default     = "t3.small"
}

variable "app_instance_type" {
  description = "Instance type for application server"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database server"
  type        = string
  default     = "t3.micro"
}

# Application Configuration
variable "app_port" {
  description = "Port for Node.js application"
  type        = number
  default     = 3000
}

variable "jenkins_port" {
  description = "Port for Jenkins web interface"
  type        = number
  default     = 8080
}

variable "mongodb_port" {
  description = "Port for MongoDB"
  type        = number
  default     = 27017
}

# Tags
variable "project_tags" {
  description = "Tags for the project resources"
  type        = map(string)
  default = {
    Project     = "tech501"
    Environment = "development"
    Terraform   = "true"
  }
}
