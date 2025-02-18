# Create a security group for Jenkins server
resource "aws_security_group" "jenkins_sg" {
  name        = var.security_group_name
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.jenkins_vpc.id

  # Allow SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = var.protocol
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # Allow HTTP access
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = var.protocol
    cidr_blocks = [var.public_access_cidr]
  }

  # Allow Jenkins web interface
  ingress {
    description = "Jenkins web interface"
    from_port   = 8080
    to_port     = 8080
    protocol    = var.protocol
    cidr_blocks = [var.public_access_cidr]
  }

  # Allow Node.js application
  ingress {
    description = "Node.js application"
    from_port   = 3000
    to_port     = 3000
    protocol    = var.protocol
    cidr_blocks = [var.public_access_cidr]
  }

  # Allow Java application
  ingress {
    description = "Java application"
    from_port   = 8090
    to_port     = 8090
    protocol    = var.protocol
    cidr_blocks = [var.public_access_cidr]
  }

  # Allow MySQL
  ingress {
    description = "MySQL database"
    from_port   = 3306
    to_port     = 3306
    protocol    = var.protocol
    cidr_blocks = [var.public_access_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_access_cidr]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}
