#!/bin/sh

# Quit if any command fails
set -e

# Create the project folder if it does not exist
mkdir -p /var/www/$PROJECT/releases

# Define the path of the new release
NEW_RELEASE_PATH="/var/www/$PROJECT/releases/$(date +"%Y%m%d%H%M%S")"

# Start the SSH agent and add the SSH private key
eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_rsa

# Clone the repository
echo "Cloning repository from $GITHUB_REPOSITORY to $NEW_RELEASE_PATH"
git clone -b "$BRANCH" "$GITHUB_REPOSITORY" "$NEW_RELEASE_PATH"

# Change the owner and permissions of the new release
chown -R www-data:www-data "$NEW_RELEASE_PATH"
chmod -R 755 "$NEW_RELEASE_PATH"

# Install the dependencies and build the application
cd "$NEW_RELEASE_PATH" && make install@$APP_ENV

# Remove the .git folder
rm -rf "$NEW_RELEASE_PATH/.git"

# Create a symbolic link to the new release
ln --symbolic --force --no-target-directory "$NEW_RELEASE_PATH" "/var/www/$PROJECT/current"

# Restart the server if the update mode is not enabled
if [ "$UPDATE_MODE" = "true" ]; then
  echo "Update mode: files have been updated without restarting the server."
else
  apache2-foreground
fi