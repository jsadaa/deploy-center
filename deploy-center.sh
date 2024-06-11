#!/bin/bash

# Quit if any command fails
set -e

# Select the project to deploy
echo "Which project do you want to deploy?"
select project in $(ls -d */); do
    if [ -n "$project" ]; then
        break
    else
        echo "Invalid selection"
    fi
done

# Move to the project directory
cd "$project"

# Select the environment to deploy
echo "Which environment do you want to deploy?"
select environment in $(ls -d */); do
    if [ -n "$environment" ]; then
        break
    else
        echo "Invalid selection"
    fi
done

# Remove trailing slashes
project=${project%/}
environment=${environment%/}

# Ask for the server IP address
echo "Enter the IP address of the server where you want to deploy the project:"
read server_ip

# Ask for the username of the server
echo "Enter the username of the server:"
read username

# Create the project deploy folder on the server
echo "Creating project deploy folder on server..."
ssh -tt "$username@$server_ip" "mkdir -p /home/$username/$project-$environment"

# Copy the project files to the server
echo "Copying project files to server..."
find . -type f | xargs -I {} scp {} "$username@$server_ip:/home/$username/$project-$environment"

# Deploy the project (initial deployment or update)
echo "Deploying project..."
ssh -tt "$username@$server_ip" << EOF
cd /home/$username/$project-$environment
if [ -z \$(docker compose ps -q app) ]; then
  echo "Initial deployment: building the application"
  docker compose up --build
else
  echo "Updating the application"
  docker compose exec -e UPDATE_MODE=true app /usr/local/bin/entrypoint.sh
fi
EOF
