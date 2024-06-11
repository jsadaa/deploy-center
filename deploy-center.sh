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

# Parse all files finishing with .env, get all the environments (prod.env, dev.env, etc) and propose them to the user
echo "Which environment do you want to deploy?"
select environment in $(ls -d *.env); do
    if [ -n "$environment" ]; then
        break
    else
        echo "Invalid selection"
    fi
done

# Clean the project and environment variables
project=${project%/}
environment=${environment%.env}

# Get the available SSH aliases from .ssh/config
echo "Fetching available SSH aliases..."
ssh_aliases=$(grep -E "^Host " ~/.ssh/config | awk '{print $2}')

if [ -z "$ssh_aliases" ]; then
    echo "No SSH aliases found in ~/.ssh/config"
    exit 1
fi

# Propose the SSH aliases to the user
echo "Select the SSH alias for the server where you want to deploy the project:"
select ssh_alias in $ssh_aliases; do
    if [ -n "$ssh_alias" ]; then
        break
    else
        echo "Invalid selection"
    fi
done

# Extract the IdentityFile for the chosen alias
identity_file=$(awk "/^Host $ssh_alias\$/{flag=1; next} /^Host /{flag=0} flag && /IdentityFile/{print \$2}" ~/.ssh/config)

# Resolve the absolute path of the identity file
identity_file="${identity_file/#\~/$HOME}"

if [ -z "$identity_file" ]; then
    echo "No IdentityFile found for alias $ssh_alias in ~/.ssh/config"
    exit 1
fi

# Verify that the identity file exists
if [ ! -f "$identity_file" ]; then
    echo "IdentityFile $identity_file does not exist."
    exit 1
fi

# Get the username from the SSH alias (assuming the format user@host in the alias)
ssh_user=$(awk "/^Host $ssh_alias\$/{flag=1; next} /^Host /{flag=0} flag && /User/{print \$2}" ~/.ssh/config)
if [ -z "$ssh_user" ]; then
    ssh_user=$USER  # Fallback to the current user if not specified in the config
fi

# Create the project deploy folder on the server
echo "Creating project deploy folder on server..."
ssh -tt "$ssh_alias" "mkdir -p /home/$ssh_user/$project-$environment"

# Copy the specific environment file to the server
echo "Copying environment file to server..."
scp "$environment.env" "$ssh_alias:/home/$ssh_user/$project-$environment/.env"

# Copy the deployment files to the server
echo "Copying project files to server..."
find . -type f ! -name '*.env' | xargs -I {} scp {} "$ssh_alias:/home/$ssh_user/$project-$environment/"

# Copy the private key file to the server
echo "Copying the private key file to server..."
scp "$identity_file" "$ssh_alias:/home/$ssh_user/$project-$environment/id_rsa"

# Set the correct permissions for the private key file on the server
echo "Setting permissions for the private key file on server..."
ssh -tt "$ssh_alias" "chmod 600 /home/$ssh_user/$project-$environment/id_rsa"

# Deploy the project (initial deployment or update)
echo "Deploying project..."
ssh -tt "$ssh_alias" << EOF
cd /home/$ssh_user/$project-$environment
if [ -z \$(docker compose ps -q app) ]; then
  echo "Initial deployment: building the application"
  docker compose up --build
else
  echo "Updating the application"
  docker compose exec -e UPDATE_MODE=true app /usr/local/bin/entrypoint.sh
fi
EOF
