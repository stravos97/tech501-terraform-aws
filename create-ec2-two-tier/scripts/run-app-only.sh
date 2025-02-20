#!/bin/bash
# run-app-only.sh
# Purpose: Get the Node.js app running (without installing all system dependencies)
# This script is designed to be used with AMIs that already have the application and its dependencies installed

# Ensure we capture errors
set -e

echo "Starting application deployment from AMI..."

# Optional: Set DB_HOST for the database connection.
# Uncomment and update <DB_VM_IP> with the actual database IP
# export DB_HOST="mongodb://<DB_VM_IP>:27017/posts"

echo "Checking PM2 status..."
pm2 status

echo "Changing directory to the app folder..."
if [ -d "/repo/app" ]; then
    cd /repo/app
    echo "Successfully changed to app directory"
else
    echo "Error: Application directory not found at /repo/app"
    echo "Please ensure this AMI was properly prepared with the application files"
    exit 1
fi

echo "Installing/Updating npm dependencies..."
npm install --quiet

echo "Starting the Node.js app with PM2..."
if pm2 describe app > /dev/null 2>&1; then
    echo "Restarting existing PM2 process..."
    pm2 restart app
else
    echo "Starting new PM2 process..."
    pm2 start app.js --name app
fi

echo "Saving PM2 process list..."
pm2 save

echo "Checking application status..."
pm2 list

echo "Application deployment complete!"
echo "Note: Ensure DB_HOST environment variable is set if database connection is required"
