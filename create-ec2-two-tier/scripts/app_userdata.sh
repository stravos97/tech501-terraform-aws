#!/bin/bash
set -e

# Redirect all output to log file
exec 1> >(tee -a /var/log/app_setup.log)
exec 2> >(tee -a /var/log/app_setup.log >&2)

# Log start time
echo "App Setup Script Started at: $(date)"

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

# Set the DB_HOST environment variable globally
echo "DB_HOST=mongodb://${db_private_ip}:27017/posts" | sudo tee -a /etc/environment
source /etc/environment

echo "Set DB_HOST environment variable: $DB_HOST"

echo "Changing directory to the app repository..."
if [ -d "/repo/app" ]; then
  cd /repo/app
else
  echo "Error: /repo/app directory not found."
  exit 1
fi

npm install > /dev/null 2>&1

echo "Starting the Node.js app with PM2..."
# Use full path to PM2 and ensure DB_HOST is set
if /usr/lib/node_modules/pm2/bin/pm2 describe app > /dev/null 2>&1; then
  echo "Node.js app is already running in PM2."
else
  echo "Starting app with DB_HOST=$DB_HOST"
  source /etc/environment
  if DB_HOST="$DB_HOST" /usr/lib/node_modules/pm2/bin/pm2 start app.js --name app; then
    echo "Node.js app started successfully with PM2"
    /usr/lib/node_modules/pm2/bin/pm2 save
    echo "PM2 process saved"
    /usr/lib/node_modules/pm2/bin/pm2 startup
    echo "PM2 startup enabled"
  else
    echo "Failed to start Node.js app with PM2"
    exit 1
  fi
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
/usr/lib/node_modules/pm2/bin/pm2 list

# Log end time
echo "App Setup Script Completed at: $(date)"

echo "----------------------------------------------"
echo "Database connection string:"
echo "DB_HOST=$DB_HOST"
