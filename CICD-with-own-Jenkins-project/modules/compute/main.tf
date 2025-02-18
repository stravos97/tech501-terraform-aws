# Jenkins Server
resource "aws_instance" "jenkins" {
  ami           = var.ubuntu_ami_id
  instance_type = "t3.small"
  subnet_id     = var.jenkins_subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = [var.jenkins_sg_id]

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

              # Wait for Jenkins to initialize (90 seconds)
              sleep 90

              # Wait for password file to be created
              while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; do
                sleep 10
                echo "Waiting for Jenkins password file..."
              done

              # Create password file with clear indicator
              echo "Jenkins is ready! Initial admin password: " > /home/ubuntu/jenkins-password.txt
              sudo cat /var/lib/jenkins/secrets/initialAdminPassword >> /home/ubuntu/jenkins-password.txt
              
              # Set correct permissions
              sudo chown ubuntu:ubuntu /home/ubuntu/jenkins-password.txt
              EOF

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  tags = {
    Name = "jenkins-server"
  }
}

# Application Server
resource "aws_instance" "app" {
  ami           = var.ubuntu_ami_id
  instance_type = "t3.micro"
  subnet_id     = var.app_subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = [var.app_sg_id]

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              sudo apt-get update
              sudo apt-get upgrade -y

              # Install required packages
              sudo apt-get install -y nginx git

              # Install Node.js 20
              sudo DEBIAN_FRONTEND=noninteractive bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
              sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
              sudo apt-get install -y npm

              # Configure NGINX reverse proxy
              sudo tee /etc/nginx/sites-available/default <<'EOL'
              server {
                  listen 80;
                  server_name _;

                  location / {
                      proxy_pass http://localhost:3000;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade \$http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host \$host;
                      proxy_cache_bypass \$http_upgrade;
                  }
              }
              EOL

              sudo systemctl restart nginx

              # Install PM2
              sudo npm install -g pm2

              # Set environment variable for MongoDB connection
              echo "export DB_HOST=mongodb://${var.db_private_ip}:27017/posts" >> /home/ubuntu/.bashrc
              source /home/ubuntu/.bashrc

              # Clone and deploy application
              git clone https://github.com/stravos97/node-sparta-test-app /repo
              
              # Check if clone was successful
              if [ ! -d "/repo/app" ]; then
                  echo "Failed to clone repository"
                  exit 1
              fi

              # Install dependencies and start app
              cd /repo/app
              if ! npm install; then
                  echo "Failed to install dependencies"
                  exit 1
              fi

              # Start application with PM2
              pm2 status
              pm2 start app.js

              # Save PM2 process list
              pm2 save

              # Setup PM2 to start on boot
              sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
              sudo systemctl start pm2-ubuntu
              EOF

  tags = {
    Name = "app-server"
  }
}

# Database Server
resource "aws_instance" "db" {
  ami           = var.ubuntu_ami_id
  instance_type = "t3.micro"
  subnet_id     = var.db_subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = [var.db_sg_id]

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              sudo apt-get update
              sudo apt-get upgrade -y

              # Import MongoDB public key
              curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
                sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
                --dearmor

              # Add MongoDB repository
              echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
                sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

              # Update package list
              sudo apt-get update

              # Install MongoDB
              sudo apt-get install -y mongodb-org

              # Configure MongoDB to listen on all interfaces
              sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

              # Start MongoDB
              sudo systemctl start mongod
              sudo systemctl enable mongod
              EOF

  tags = {
    Name = "db-server"
  }
}
