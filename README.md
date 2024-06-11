# Deploy Center (Docker)

## Description

This is a small personal project (initiated in school) to deploy my LAMP stack applications using Docker.

It is still a work in progress, but the idea is to have a central script to deploy all my personal PHP apps, with a simple and consistent structure.
My experience with Docker is still limited (~1 year), so I'm open to any suggestions or improvements (especially security-wise).

## Requirements

### On the target machine

#### Technologies

- Docker
- Docker Compose

#### Permissions

- The user must be able to run Docker commands without sudo.
- The user must be able to run Docker Compose commands without sudo.

To do this :

```bash
sudo usermod -aG docker $USER
```

Then, log out and log back in.

## Usage

The project is structured as follows:

- A `deploy-center.sh` at the root of the project, which is the main script to deploy the applications.
- Each project must have its own directory, containing a `docker-compose.yml`, a `Dockerfile`, an `entrypoint.sh`, a `vhost.conf`, and a `*.env` file for each environment.

To deploy an application, add your specific ssh keys to you ssh config (`~/.ssh/config`), like this :

```
Host my-target-machine
    HostName my-target-machine-ip-or-domain
    User my-target-machine-user
    IdentityFile ~/.ssh/my-target-machine-ssh-key
```

Then set up the `*.env (prod, staging, dev, .etc)` file in the project targeted environment directory, then run the `deploy-center.sh` script.

```bash
./deploy-center.sh
```

You will be prompted to choose the project to deploy, the environment, and the ssh identity to use.

### Environment variables

For now, the following environment variables are required for each project :

```dotenv
APP_ENV="The environment of the application"
APP_PORT="The port of the application"
BRANCH="The git branch to deploy"
DB_DATABASE="The database name"
GITHUB_REPOSITORY="The GitHub repository URL"
PROJECT="The project name"
```

## Concepts

The containers are created on the first deployment. If the containers already exist, only the `entrypoint.sh` script is executed.

The `entrypoint.sh` script is responsible for :

- Create the new release directory
- Git clone the new release
- Start project-specific `make` build commands
- Change the vhost symlink to the new release directory