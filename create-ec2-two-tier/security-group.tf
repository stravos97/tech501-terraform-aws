# Create a new security group
resource "aws_security_group" "app_sg" {
  name        = var.security_group_name
  vpc_id      = data.aws_vpc.default.id

  # Inbound rule: allow SSH access
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = var.protocol
    cidr_blocks = [var.ssh_allowed_cidr]  # Restrict SSH access to your specific IP
  }

  # Inbound rule: allow HTTP access
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = var.protocol
    cidr_blocks = [var.public_access_cidr]
  }

  # Inbound rule: allow Node.js app traffic on port 3000
  #   If you want to only allow outbound Node traffic, it should be a matching ingress rule, not an egress rule.
  #   If you only allow this, you won't be able to connect to the internet
  ingress {
    description = "Allow inbound Node.js traffic"
    from_port   = 3000
    to_port     = 3000
    protocol    = var.protocol
    cidr_blocks = [var.public_access_cidr] # Open for external connections
  }

  # Inbound rule: allow MongoDB traffic
  ingress {
    description = "Allow MongoDB traffic"
    from_port   = 27017
    to_port     = 27017
    protocol    = var.protocol
    cidr_blocks = [var.public_access_cidr] # Allow MongoDB connections
  }


  # Outbound rule: allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_access_cidr]
  }
}
