# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1" # Specify your desired AWS region
}

# This block tells Terraform to look up the default VPC in your current AWS region (in this case, eu-west-1). Once Terraform finds it, you can reference its ID with data.aws_vpc.default.id—for example, when assigning the security group to your instance.
data "aws_vpc" "default" {
  default = true
}


resource "aws_instance" "app_instance" {
  # which AMI ID
  ami = var.instance_ami_id

  # Attach the SSH key pair
  key_name = var.ssh_key_name

  # which type of instance
  instance_type = var.instance_type

  # that we want a public ip
  associate_public_ip_address = var.enable_public_ip

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # name the service/instance
  tags = {
    Name = var.instance_name
  }
}



# # Create an EC2 instance
# resource "aws_instance" "web_server" {
#   # Amazon Linux 2 AMI (HVM) - Kernel 5.10
#   ami           = "ami-0735c191cf914754d"
#   instance_type = "t2.micro" # Free tier eligible instance type
#   subnet_id     = aws_subnet.public.id

#   # Add tags for better resource management
#   tags = {
#     Name        = "web-server"
#     Environment = "development"
#   }

#   # EC2 instance volume configuration
#   root_block_device {
#     volume_size = 8     # Size in GB
#     volume_type = "gp2" # General Purpose SSD
#   }
# }
