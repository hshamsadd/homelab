# Start the Docker service

sudo systemctl start docker

# Enable Docker to start automatically at system boot

sudo systemctl enable docker

# Check Docker service status

sudo systemctl status docker

# Restart Docker service

sudo systemctl restart docker

# Stop the Docker service

sudo systemctl stop docker

# Disable Docker from starting automatically at system boot

sudo systemctl disable docker

# List currently running containers

docker ps

# List all containers (running + stopped)

docker ps -a

# Run a container (example: nginx)

docker run nginx

# Run a container in detached mode (background)

docker run -d nginx

# Run a container with a name and port mapping

docker run -d --name <container-name> -p 8080:80 nginx

# Start an existing stopped container

docker start <container>

# Stop a running container

docker stop <container>

# Stop multiple running containers

docker stop <container-1> <container-2> <container-3>

# Remove a container (must be stopped first)

docker rm <container>

# Force remove a container (stops it if running)

docker rm -f <container>

# Remove all stopped containers (asks for confirmation) does NOT remove running containers. You must stop or force remove them.

docker container prune

# Remove all stopped containers without confirmation

docker container prune -f

# List Docker images

docker images

# Remove an image

docker rmi <image>

# Remove multiple images

docker rmi <image-1> <image-2> <image-3>

# Force remove images (even if used by stopped containers)

docker rmi -f <image-1> <image-2> <image-3>

docker ps //
docker ps -a //
docker stop <container> // stop a running container
docker stop <container-1> <container-2> <container-3> // stop multiple running containers
docker rm <container> // remove a running container but first stop it
docker rm -f <container> // remove a running container withou stopping it

docker <container> prun
docker rmi <container>
docker rmi <container-1> <container-2> <container-3>

docker rmi -f <container-1> <container-2> <container-3>

# Start an existing stopped container

docker build -t mern-backend .

docker run -p 5000:5000 --name backend mern-backend

docker run -p 5000:5000 --name backend --env-file .env mern-backend

docker build -t mern-frontend .

docker run -p 5000:5000 --name frontend mern-frontend

docker run -p 5000:5000 --name frontend --env-file .env mern-frontend

docker compose tool to define container apps in a single yaml file

docker-compose.yml

docker compose engine talks to containers DB - Backend - Frontend

docker-compose up --build

docker-compose up --build -d

docker-compose down

docker-compose logs

docker-compose logs backend

# ==============================

# MERN Backend: Build & Run

# ==============================

# Build the backend Docker image and tag it as 'mern-backend'

docker build -t mern-backend .

# Run the backend container, map port 5000 on host to 5000 in container

docker run -p 5000:5000 --name backend mern-backend

# Run the backend container with environment variables from .env file

docker run -p 5000:5000 --name backend --env-file .env mern-backend

# ==============================

# MERN Frontend: Build & Run

# ==============================

# Build the frontend Docker image and tag it as 'mern-frontend'

docker build -t mern-frontend .

# Run the frontend container, map port 5000 on host to 5000 in container

docker run -p 5000:5000 --name frontend mern-frontend

# Run the frontend container with environment variables from .env file

docker run -p 5000:5000 --name frontend --env-file .env mern-frontend

# ==============================

# Docker Compose: Multi-container apps

# ==============================

# Docker Compose allows you to define multiple containers in a single YAML file (docker-compose.yml)

# Example containers: DB, Backend, Frontend

# Start all containers defined in docker-compose.yml and build images if needed

docker-compose up --build

# Start all containers in detached mode (runs in background) and build images if needed

docker-compose up --build -d

# Stop and remove all containers, networks, and default volumes created by docker-compose

docker-compose down

# View logs for all containers managed by docker-compose

docker-compose logs

# View logs for a specific service/container (e.g., backend)

docker-compose logs backend

🔑 Notes / Tips:

docker build -t <tag> . → builds an image from the current directory (.) and assigns a name.

docker run -p host:container → maps host port to container port.

--env-file .env → passes environment variables to container.

Docker Compose makes it easy to run multi-container apps with a single docker-compose.yml.

docker-compose up --build -d → common in production/testing to start everything in the background.

docker-compose down → cleans up containers, networks, and volumes created by Compose.

🚀 MERN Docker Cheat Sheet
1️⃣ Docker Service Management

# Start Docker service

sudo systemctl start docker

# Enable Docker to start at boot

sudo systemctl enable docker

# Stop Docker service

sudo systemctl stop docker

# Disable Docker at boot

sudo systemctl disable docker

# Check Docker service status

sudo systemctl status docker

2️⃣ Container Commands

# List running containers

docker ps

# List all containers (running + stopped)

docker ps -a

# Stop a running container

docker stop <container>

# Stop multiple running containers

docker stop <container-1> <container-2>

# Start a stopped container

docker start <container>

# Remove a stopped container

docker rm <container>

# Force remove a container (stops it if running)

docker rm -f <container>

# Remove all stopped containers

docker container prune # confirmation required
docker container prune -f # force without confirmation

3️⃣ Image Commands

# List Docker images

docker images

# Remove a single image

docker rmi <image>

# Remove multiple images

docker rmi <image1> <image2>

# Force remove images (even if used by containers)

docker rmi -f <image1> <image2>

4️⃣ Building & Running MERN Containers

# -----------------------

# Backend

# -----------------------

docker build -t mern-backend . # build backend image
docker run -p 5000:5000 --name backend mern-backend # run container
docker run -p 5000:5000 --name backend --env-file .env mern-backend # run with env

# -----------------------

# Frontend

# -----------------------

docker build -t mern-frontend . # build frontend image
docker run -p 5000:5000 --name frontend mern-frontend # run container
docker run -p 5000:5000 --name frontend --env-file .env mern-frontend # run with env

5️⃣ Docker Compose (Multi-container Apps)

# Start all services defined in docker-compose.yml and build images if needed

docker-compose up --build

# Start all services in detached mode (background)

docker-compose up --build -d

# Stop and remove all containers, networks, and default volumes

docker-compose down

# View logs for all containers

docker-compose logs

# View logs for a specific service (e.g., backend)

docker-compose logs backend

6️⃣ Cleanup Commands (Free Disk Space)

# Remove all stopped containers

docker container prune -f

# Remove dangling images (untagged)

docker image prune -f

# Remove all unused containers, networks, images, and volumes

docker system prune -f

docker compose down
docker compose up -d

Soyouthinkyoucandance?!
