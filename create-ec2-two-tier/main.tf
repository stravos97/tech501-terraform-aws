# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1" # Specify your desired AWS region
}

# This block tells Terraform to look up the default VPC in your current AWS region (in this case, eu-west-1). Once Terraform finds it, you can reference its ID with data.aws_vpc.default.id—for example, when assigning the security group to your instance.
data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "app_instance" {
  ami                         = var.instance_ami_id
  key_name                    = var.ssh_key_name
  instance_type              = var.instance_type
  associate_public_ip_address = var.enable_public_ip
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  
  tags = {
    Name = var.app_instance_name
  }
}

resource "aws_instance" "db_instance" {
  ami                         = var.instance_ami_id
  key_name                    = var.ssh_key_name
  instance_type              = var.instance_type
  associate_public_ip_address = var.enable_public_ip
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  
  tags = {
    Name = var.db_instance_name
  }
}
