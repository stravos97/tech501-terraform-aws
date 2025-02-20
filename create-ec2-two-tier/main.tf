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
  
  tags = {
    Name = var.db_instance_name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    set -e

    # Usage: ./sparta.sh
    # This script installs and configures MongoDB on Ubuntu 22.04.
    # It also configures needrestart to automatically restart services without prompts.
    # The script is designed to be idempotent, so steps already executed are skipped.


    echo "----------------------------------------------"
    echo "Configuring needrestart for non-interactive mode..."
    # Only update the configuration if it doesn't already have auto mode enabled.
    if grep -q '^NEEDRESTART_MODE="a"' /etc/needrestart/needrestart.conf; then
      echo "needrestart is already configured for auto mode."
    else
      sed -i 's/^#\?NEEDRESTART_MODE=.*/NEEDRESTART_MODE="a"/' /etc/needrestart/needrestart.conf
      echo "needrestart configuration updated."
    fi
    export NEEDRESTART_SILENT=1
    export NEEDRESTART_MODE=a

    echo "Running system upgrade in non-interactive mode..."
    DEBIAN_FRONTEND=noninteractive apt-get \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
      upgrade -y > /dev/null 2>&1

    echo "=============================================="
    echo "Setting up Database Tier (MongoDB)..."
    echo "=============================================="

    echo "Updating package lists..."
    apt-get update -qq > /dev/null 2>&1

    echo "Upgrading system packages..."
    apt-get upgrade -y -qq > /dev/null 2>&1

    echo "Installing gnupg and curl (if not already installed)..."
    for pkg in gnupg curl; do
      if dpkg -l | grep -qw "$pkg"; then
        echo "$pkg is already installed."
      else
        apt-get install -y "$pkg" > /dev/null 2>&1
        echo "$pkg installed."
      fi
    done

    echo "Importing MongoDB public key (if not already imported)..."
    if [ -f /usr/share/keyrings/mongodb-server-7.0.gpg ]; then
      echo "MongoDB public key already exists."
    else
      curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
      echo "MongoDB public key imported."
    fi

    echo "Adding MongoDB repository (if not already added)..."
    if [ -f /etc/apt/sources.list.d/mongodb-org-7.0.list ]; then
      echo "MongoDB repository already exists."
    else
      echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
        | tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null 2>&1
      echo "MongoDB repository added."
    fi

    echo "Updating package lists after adding MongoDB repository..."
    apt-get update -qq > /dev/null 2>&1

    echo "Installing MongoDB packages (if not already installed)..."
    if command -v mongod >/dev/null 2>&1; then
      echo "MongoDB packages are already installed."
    else
      apt-get install -y mongodb-org=7.0.6 mongodb-org-database=7.0.6 mongodb-org-server=7.0.6 \
                        mongodb-mongosh mongodb-org-mongos=7.0.6 mongodb-org-tools=7.0.6 > /dev/null 2>&1
      echo "MongoDB packages installed."
    fi

    echo "Configuring MongoDB to bind to all IP addresses (if not already configured)..."
    if grep -q "bindIp: 0.0.0.0" /etc/mongod.conf; then
      echo "MongoDB already configured to bind to all IP addresses."
    else
      sed -i.bak 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
      echo "MongoDB bindIp configuration updated."
    fi

    echo "Starting MongoDB service (if not already running)..."
    if systemctl is-active --quiet mongod; then
      echo "MongoDB service is already running."
    else
      systemctl start mongod > /dev/null 2>&1
      echo "MongoDB service started."
    fi

    echo "Enabling MongoDB service (if not already enabled)..."
    if systemctl is-enabled --quiet mongod; then
      echo "MongoDB service is already enabled."
    else
      systemctl enable mongod > /dev/null 2>&1
      echo "MongoDB service enabled."
    fi

    echo "Fetching MongoDB service status..."
    systemctl status mongod --no-pager

    echo "----------------------------------------------"
    echo "Verifying MongoDB installation..."
    if command -v mongod >/dev/null 2>&1; then
      echo "MongoDB installed successfully!"
      echo "MongoDB version info:"
      mongod --version | head -n 1
    else
      echo "Error: mongod command not found. Installation may have failed."
    fi

    echo "----------------------------------------------"
    BIND_IP=$(grep -E '^\s*bindIp:\s*' /etc/mongod.conf | awk '{print $2}')
    echo "Current MongoDB bindIp: $BIND_IP"
    echo "----------------------------------------------"
    echo "MongoDB installation and configuration complete."


    EOF
  )
}

  # Add 5-minute delay after DB instance creation
resource "time_sleep" "wait_5_mins" {
  depends_on = [aws_instance.db_instance]
  create_duration = "300s"
}

resource "aws_instance" "app_instance" {
  ami                         = var.instance_ami_id
  key_name                    = var.ssh_key_name
  instance_type              = var.instance_type
  associate_public_ip_address = var.enable_public_ip
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  depends_on                  = [aws_instance.db_instance]
  
  tags = {
    Name = var.app_instance_name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Usage: ./sparta.sh
    # This script installs and configures the App Tier (Nginx, Node.js, and PM2) on Ubuntu 22.04.
    # It also configures needrestart to automatically restart services without prompts.
    # The script is idempotent so that previously completed steps are skipped.

    # Ensure the script is run as root
    if [ "$EUID" -ne 0 ]; then
      echo "Please run as root (or with sudo)."
      exit 1
    fi

    echo "----------------------------------------------"
    echo "Configuring needrestart for non-interactive mode..."
    # Only update if the configuration doesn't already have NEEDRESTART_MODE="a"
    if grep -q '^NEEDRESTART_MODE="a"' /etc/needrestart/needrestart.conf; then
      echo "needrestart is already set to non-interactive mode."
    else
      sed -i 's/^#\?NEEDRESTART_MODE=.*/NEEDRESTART_MODE="a"/' /etc/needrestart/needrestart.conf
      echo "needrestart configuration updated."
    fi
    export NEEDRESTART_SILENT=1
    export NEEDRESTART_MODE=a

    echo "=============================================="
    echo "Setting up App Tier (Nginx, Node.js, PM2)..."
    echo "=============================================="

    echo "Updating system packages..."
    apt-get update -qq > /dev/null 2>&1
    apt-get upgrade -y -qq > /dev/null 2>&1

    echo "Installing nginx (if not already installed)..."
    if dpkg -l | grep -qw nginx; then
      echo "nginx is already installed."
    else
      DEBIAN_FRONTEND=noninteractive apt install -y nginx > /dev/null 2>&1
      echo "nginx installed."
    fi

    echo "Enabling and starting nginx (if not already active)..."
    if systemctl is-active --quiet nginx; then
      echo "nginx service is already running."
    else
      systemctl start nginx > /dev/null 2>&1
      echo "nginx service started."
    fi

    if systemctl is-enabled --quiet nginx; then
      echo "nginx service is already enabled."
    else
      systemctl enable nginx > /dev/null 2>&1
      echo "nginx service enabled."
    fi

    echo "Installing Node.js and npm (if not already installed)..."
    if command -v node >/dev/null 2>&1; then
      echo "Node.js is already installed."
    else
      DEBIAN_FRONTEND=noninteractive bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -" > /dev/null 2>&1
      DEBIAN_FRONTEND=noninteractive apt install -y nodejs > /dev/null 2>&1
      echo "Node.js installed."
    fi

    echo "Installing PM2 globally (if not already installed)..."
    if command -v pm2 >/dev/null 2>&1; then
      echo "PM2 is already installed."
    else
      npm install -g pm2 > /dev/null 2>&1
      echo "PM2 installed."
    fi

    echo "Cloning Node.js app repository (if not already cloned)..."
    if [ -d "/repo/.git" ]; then
      echo "Repository already cloned."
    else
      git clone https://github.com/stravos97/node-sparta-test-app.git /repo > /dev/null 2>&1
      echo "Repository cloned to /repo."
    fi

    echo "Configuring Nginx reverse proxy..."
    # Check if the default config already has the desired proxy_pass setting.
    if grep -q "proxy_pass http://127.0.0.1:3000;" /etc/nginx/sites-available/default; then
      echo "Nginx reverse proxy is already configured."
    else
      sed -i 's|try_files.*|proxy_pass http://127.0.0.1:3000;|' /etc/nginx/sites-available/default
      echo "Nginx reverse proxy configured."
    fi

    echo "Reloading nginx configuration..."
    systemctl reload nginx > /dev/null 2>&1

    export DB_HOST=mongodb://${aws_instance.db_instance.private_ip}:27017/posts
    echo "DB_HOST=$DB_HOST" >> /etc/environment

    echo "Changing directory to the app repository..."
    if [ -d "/repo/app" ]; then
      cd /repo/app
    else
      echo "Error: /repo/app directory not found."
      exit 1
    fi

    npm install > /dev/null 2>&1

    echo "Starting the Node.js app with PM2..."
    # Check if PM2 already has a process running for app.js (using a process name "app" for idempotence)
    if pm2 describe app > /dev/null 2>&1; then
      echo "Node.js app is already running in PM2."
    else
      pm2 start app.js --name app > /dev/null 2>&1
      echo "Node.js app started with PM2."
    fi

    echo "=============================================="
    echo "Final Configuration and Service Statuses"
    echo "=============================================="

    echo "Current 'proxy_pass' configuration in Nginx:"
    grep "proxy_pass" /etc/nginx/sites-available/default

    echo "----------------------------------------------"
    echo "Nginx service status:"
    systemctl status nginx --no-pager

    echo "----------------------------------------------"
    echo "PM2 process list:"
    pm2 list

    EOF
  )
}
