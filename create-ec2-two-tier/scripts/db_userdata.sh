#!/bin/bash
set -e

# Redirect all output to log file
exec 1> >(tee -a /var/log/db_setup.log)
exec 2> >(tee -a /var/log/db_setup.log >&2)

# Log start time
echo "DB Setup Script Started at: $(date)"

# Usage: ./sparta.sh
# This script installs and configures MongoDB on Ubuntu 22.04.
# It also configures needrestart to automatically restart services without prompts.
# The script is designed to be idempotent, so steps already executed are skipped.

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or with sudo)."
  exit 1
fi

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

# Log end time
echo "DB Setup Script Completed at: $(date)"

# Final verification
echo "Verifying MongoDB is running and responsive..."
if systemctl is-active --quiet mongod && mongosh --eval 'db.runCommand("ping").ok' --quiet; then
    echo "MongoDB is running and responding to requests"
else
    echo "WARNING: MongoDB may not be running properly"
fi
