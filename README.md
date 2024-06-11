# Deploy Center (Docker)

## Description

This is a small personal project to deploy my LAMP stack applications using Docker.

It is still a work in progress, but the idea is to have a central script to deploy all my applications, with a simple and consistent structure.
My experience with Docker is still limited (~1 year), so I'm open to any suggestions or improvements (especially security-wise).

## Requirements

### On the target machine

#### Technologies

- Docker
- Docker Compose
- Portainer (optional but recommended) `docker run -d --name portainer -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer`

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
- Each project has its own directory, containing a `docker-compose.yml`, a `Dockerfile`, an `entrypoint.sh`, a `vhost.conf` and the specific ssh keys to clone the repository.
- Each environment has its own `.env` file in a subdirectory of the project directory.

To deploy an application, add your ssh keys at the targeted project root, set up the `.env` file in the project targeted environment directory, then run the `deploy-center.sh` script.

```bash
./deploy-center.sh
```

You will be prompted to choose the project to deploy, the environment, the target IP address and the user to connect to the target machine.

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