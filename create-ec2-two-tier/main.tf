# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1" # Specify your desired AWS region
}

# This block tells Terraform to look up the default VPC in your current AWS region (in this case, eu-west-1). Once Terraform finds it, you can reference its ID with data.aws_vpc.default.id—for example, when assigning the security group to your instance.
data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "db_instance" {
  ami                         = var.instance_ami_id
  key_name                    = var.ssh_key_name
  instance_type              = var.instance_type
  associate_public_ip_address = var.enable_public_ip
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  user_data                   = file("${path.module}/scripts/db_userdata.sh")
  
  tags = {
    Name = var.db_instance_name
  }

  # Wait for MongoDB to be fully configured and running
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }

    inline = [
      # Wait for cloud-init with timeout
      "echo 'Waiting for cloud-init to complete...'",
      "for i in {1..30}; do if sudo cloud-init status --wait; then break; fi; echo \"Waiting for cloud-init... (Attempt $i/30)\"; sleep 10; done",
      
      # Check MongoDB installation and startup
      "echo 'Checking MongoDB installation and startup...'",
      "for i in {1..30}; do if sudo systemctl is-active mongod >/dev/null 2>&1 && sudo mongosh --eval 'db.runCommand(\"ping\").ok' --quiet >/dev/null 2>&1; then echo 'MongoDB is ready!'; break; fi; echo \"Waiting for MongoDB... (Attempt $i/30)\"; sleep 10; done",
      
      # Verify MongoDB is actually running
      "if ! sudo systemctl is-active mongod >/dev/null 2>&1; then echo 'MongoDB failed to start' && exit 1; fi",
      "if ! sudo mongosh --eval 'db.runCommand(\"ping\").ok' --quiet >/dev/null 2>&1; then echo 'MongoDB is not responding' && exit 1; fi",
      
      # Show final status
      "echo 'MongoDB final status:'",
      "sudo systemctl status mongod --no-pager",
      "echo 'MongoDB logs:'",
      "sudo tail -n 20 /var/log/mongodb/mongod.log || true"
    ]
  }
}

resource "aws_instance" "app_instance" {
  ami                         = var.instance_ami_id
  key_name                    = var.ssh_key_name
  instance_type              = var.instance_type
  associate_public_ip_address = var.enable_public_ip
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  user_data                   = templatefile("${path.module}/scripts/app_userdata.sh", {
    db_private_ip = aws_instance.db_instance.private_ip
  })
  depends_on                  = [aws_instance.db_instance]
  
  tags = {
    Name = var.app_instance_name
  }

  # Wait for app setup to complete
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }

    inline = [
      # Wait for cloud-init with timeout
      "echo 'Waiting for cloud-init to complete...'",
      "for i in {1..30}; do if sudo cloud-init status --wait; then break; fi; echo \"Waiting for cloud-init... (Attempt $i/30)\"; sleep 10; done",
      
      # Check Node.js app status
      "echo 'Checking app status...'",
      "sudo systemctl status nginx --no-pager || true",
      "echo 'Checking PM2 processes...'",
      "/usr/lib/node_modules/pm2/bin/pm2 list || true",
      
      # Verify app is running with retries
      "echo 'Testing app connection...'",
      "for i in {1..12}; do if curl -s http://localhost:3000 >/dev/null; then echo 'App is ready!'; exit 0; fi; echo \"Waiting for app... (Attempt $i/12)\"; sleep 10; done",
      "echo 'App failed to start' && exit 1"
    ]
  }
}
