# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

# Create VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "jenkins-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "jenkins-igw"
  }
}

# Create public subnet
resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "jenkins-subnet"
  }
}

# Create route table
resource "aws_route_table" "jenkins_rt" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }

  tags = {
    Name = "jenkins-rt"
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "jenkins_rta" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_rt.id
}

# Create Jenkins server instance
resource "aws_instance" "jenkins_server" {
  ami           = var.ubuntu_ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.jenkins_subnet.id
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              sudo apt-get update
              sudo apt-get upgrade -y

              # Install Java 17
              sudo apt-get install -y openjdk-17-jdk

              # Install Jenkins
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y jenkins

              # Start Jenkins
              sudo systemctl start jenkins
              sudo systemctl enable jenkins

              # Install Node.js 20
              curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
              sudo apt-get install -y nodejs

              # Install MySQL
              sudo apt-get install -y mysql-server
              sudo systemctl start mysql
              sudo systemctl enable mysql

              # Get Jenkins initial admin password
              echo "Jenkins initial admin password: " > /home/ubuntu/jenkins-password.txt
              sudo cat /var/lib/jenkins/secrets/initialAdminPassword >> /home/ubuntu/jenkins-password.txt
              EOF

  tags = {
    Name = var.instance_name
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  depends_on = [aws_internet_gateway.jenkins_igw]
}

# Output the public IP
output "jenkins_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

# Output the Jenkins initial admin password command
output "jenkins_password_command" {
  value = "ssh -i '${var.ssh_key_name}.pem' ubuntu@${aws_instance.jenkins_server.public_ip} 'cat jenkins-password.txt'"
}
