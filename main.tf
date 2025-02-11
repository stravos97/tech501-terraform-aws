# create an ec2 instance
# where to create it- rovide a cloud Name
# which region to create it- ireland
# which service to use- ec2
# which ami id to use- ami-0c55b159cbfafe1f0
# which type of instance that we want a public import 
# aws_access_key
# aws_secret_key
# aws_profile
# name of the service instance - webserver
# tag the service instance - webserver

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1" # Specify your desired AWS region
}

# # Create a VPC for the EC2 instance
# resource "aws_vpc" "main" {
#     cidr_block = "10.0.0.0/16"

#     tags = {
#         Name = "main-vpc"
#     }
# }

resource "aws_instance" "app_instance" {
  # which AMI ID
  ami = "ami-0c1c30571d2dae5c9"

  # which type of instance
  instance_type = "t3.micro"

  # that we want a public ip
  associate_public_ip_address = true

  # name the service/instance
  tags = {
    Name = "tech501-haashim-app"
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
