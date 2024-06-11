# Use the official PHP image
FROM php:8.3-apache

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# Define the arguments
ARG APP_ENV
ARG APP_PORT
ARG BRANCH
ARG DB_DATABASE
ARG PROJECT
ARG GITHUB_REPOSITORY

# Define the environment variables
ENV APP_ENV="$APP_ENV"
ENV APP_PORT="$APP_PORT"
ENV BRANCH="$BRANCH"
ENV DB_DATABASE="$DB_DATABASE"
ENV PROJECT="$PROJECT"
ENV GITHUB_REPOSITORY="$GITHUB_REPOSITORY"
ENV UPDATE_MODE="false"

# Update the package list and install required packages
RUN apt-get update && \
    apt-get install -y git unzip libzip-dev nano curl wget && \
    apt-get clean && \
    docker-php-ext-install pdo_mysql zip mysqli pdo && \
    rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Copy the Apache vhost file
COPY vhost.conf /etc/apache2/sites-available/$PROJECT.conf

# Disable the default Apache vhost
RUN a2dissite 000-default

# Enable the new Apache vhost
RUN a2ensite $PROJECT

# Configure the Apache vhost document root
RUN sed -i "s|DocumentRoot /var/www/html|DocumentRoot /var/www/$PROJECT/current/public|" /etc/apache2/sites-available/$PROJECT.conf

# Create the ssh directory
RUN mkdir /root/.ssh

# Copy the ssh key
COPY id_rsa /root/.ssh/id_rsa

# Change the permissions of the ssh key
RUN chmod 600 /root/.ssh/id_rsa

# Add the github.com key to known_hosts
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Define the working directory
WORKDIR /var/www/$PROJECT

# Expose the port
EXPOSE 80

# Run the entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]
