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
