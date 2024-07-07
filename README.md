# First Create a Bucket on AWS S3
Only do this if you have not done so as yet

## Creating a Bucket on S3
Create the bucket with an appropriate name
Edit the Permissions of the bucket
Add the following JSON to the CORS permissions:
json
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "PUT",
            "POST",
            "GET"
        ],
        "AllowedOrigins": [
            "http://localhost:8000"
        ],
        "ExposeHeaders": []
    }
]


Create an AMI user who only have access to this bucket
Then create API credentials for the user


# Third Intellect Docker Deployment (For Dev on Local)

This guide will help you deploy the a Django application using docker on a VPS for development purposes.

Check the docker-compose-dev.yml if all configuration is correct
Copy example.env to .env and set your configuration
Check that your django application will understand your .env

Then build the image:
bash
cd path/to/courtroll/courtroll-deployment
docker-compose -f docker-compose-dev.yml build web

Check in Docker if you can see the image under the image tab. It should have the Tag "latest" and Created a few seconds ago

After you have built the new image, you can bring up the services as follows:
bash
docker-compose -f docker-compose-dev.yml --env-file .env up -d

Please check if they are all running in docker. If not, check their logs for issues. A service not running correctly will keep on restarting.

If you make any changes to the docker-compose-dev.yml, then you need to restart the services as follows:
bash
docker-compose -f docker-compose-dev.yml down
docker-compose -f docker-compose-dev.yml --env-file .env up -d


If the changes in your docker-compose-dev.yml file involve updates to the Dockerfile or other build contexts, you might need to rebuild the images. Or if your Pipfile or Requirements.txt changed then you need to rebuild. Use the following command to rebuild:
bash
docker-compose -f docker-compose-dev.yml build --no-cache web


To rebuild all services
bash
docker-compose -f docker-compose-dev.yml build


Then, always do the following to make to switch to the new image
bash
docker-compose -f docker-compose-dev.yml down
docker-compose -f docker-compose-dev.yml --env-file .env up -d



# Zyneura Docker Deployment (For Test and Production VPS) - VERTICAL

This guide will help you deploy the Zyneura Django application using docker on a VPS for testing and production purposes.

First create a VPS with Docker.

We are going to setup the database and application as well as redis on the same server. This is for Vertical Scaling.

## Preparing the VPS

### First create an ssh key
```bash
ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519 -C "$(whoami)@$(hostname)-$(date +'%y%m%d')"
```

### Then add the SSH private key to the ssh-agent
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
nano ~/.bashrc
```

Add the following line to the end of the file:
```bash
eval "$(ssh-agent -s)"
```
Save the file and exit the text editor.

Copy the public key and create a deployment key in github
```bash
nano ~/.ssh/id_ed25519.pub
```

On GitHub.com, navigate to the main page of ***THIS repository***.

Under the repository name, click  Settings. If you cannot see the "Settings" tab, select the  dropdown menu, then click Settings.

In the sidebar, click Deploy Keys.

Click Add deploy key.

In the "Title" field, provide a title.

In the "Key" field, paste your public key.

Select Allow write access if you want this key to have write access to the repository. A deploy key with write access lets a deployment push to the repository.

Click Add key.

### Then clone this repo
```bash
git clone git@github.com:leonjvr/zyneura-install.git
```

### Now we need to setup .env from example.env
```bash
cp example.env .env
nano .env
```


### First create the file .env outside of the docker image anywhere secure on the server and add all the variables you have in the .env-example file.
Set the following permissions:
```bash
chmod 600 .env
```

###Change the attributes of the bash scripts
```bash
find . -type f -name "*.sh" -exec chmod +x {} \;
```
This command makes all .sh files in the specified folder executable.

### Create a docker network:
Create a Docker network named zyneura_network. This network will be used for communication between Docker containers.
```bash
docker network create zyneura_network
```

## Launch the postgresql database as a docker container:
Run the following command to start the PostgreSQL database in a Docker container. Make sure to replace .env with the actual path to your .env file.
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 6379/tcp
sudo ufw deny 2375/tcp #Docker port
sudo ufw deny 2376/tcp #Docker port
sudo ufw enable
sudo ufw reload

sudo apt install docker 
sudo apt install docker-compose
docker login -u tileonjvr
docker-compose -f docker-compose.yml --env-file .env up -d
sudo reboot
```
At the password prompt: dckr_pat_q3SX3wI4-bXLvQ22Q22Ql3_P4Yo

When docker asks for the login details, you need to provide the docker.com docker hub login for this repo.

**NOTE** Do not use "sudo snap install docker" as it will install Apparmor profiles that will make it difficult to upgrade docker images.

This command initializes the PostgreSQL container with the provided environment variables and configuration.

## To get into the container shell:
```bash
docker exec -it production_nginx bash
```

## If there is an error or an update with one of your containers, you can recreate it by:
```bash
docker-compose down
docker-compose up -d --build # If you made changes that requires a rebuild
docker-compose up -d # If you did not make changes but just want to start your container based on your docker-compose.yml
```

To stop a specific contianer:
```bash
docker-compose stop <service_name>
docker-compose rm <service_name>
docker-compose up -d <service_name>
```
Replace <service_name> with the name of the service as defined in your docker-compose.yml.


Tip Use Screen to make your session persistent:
```bash
screen
```

If you loose connection, then
```bash
screen -ls
screen -d -r <number> 
```


## Open the web container and run the following commands:
```bash

python manage.py makemigrations
python manage.py migrate

python manage.py createsuperuser --username <username> --email <email>

python manage.py collectstatic
```


### Test the postgresql database:
Run the test_postgresql.sh script to verify that the PostgreSQL database is running correctly.
```bash
./test_postgresql.sh
```
This script will check if the PostgreSQL container is up and running and test the database connection.

With these steps completed, your server should now have PostgreSQL and Redis containers running. You can proceed with setting up and running your Django application and Celery workers as needed.

## Running the Django Application

### Deploying the Docker Image

1. **Pull the Docker Image:**

   Pull the Docker image for your Django application from your private Docker Hub repository. Replace `<your-docker-hub-username>` with your actual Docker Hub username.

   ```bash
   $ docker pull tileonjvr/zyneura
   ```
   This command downloads the latest version of your Docker image.

2. **Run the Docker Container**
   
   Start the Django application as a Docker container using the following command. Make sure to replace .env with the actual path to your .env file.

   ```bash
   $ docker run -d --name zyneura_app --env-file /path/to/.env -p 8000:8000 --network zyneura_network <your-docker-hub-username>/zyneura
   ```
   -d runs the container in detached mode.
   --name zyneura_app assigns a name to the container.
   --env-file /path/to/.env specifies the environment variables file.
   -p 8000:8000 maps port 8000 from the container to the host.
   --network zyneura_network connects the container to the zyneura_network network.
   This command launches the Django application container.




# Zyneura Local Deployment Guide

This guide will help you deploy the Zyneura Django application on your local machine for development and testing purposes.

## Prerequisites

Before you start the installation process, make sure you have the following software installed on your machine:

- Python
- Pipenv
- PostgreSQL
- ffmpeg

If you do not have these installed, please install them first.

## Installation Steps With Script

1. **Clone the Repository:** Clone the Zyneura repository to your local machine.
2. **Run the installation script:** Run the following command: setup_zyneura_dev.bat

## Installation Steps Manually
1. **Clone the Repository:** Clone the Zyneura repository to your local machine.
   
2. **Set up the Virtual Environment:** Navigate to the project directory and run the following command to create a virtual environment using Pipenv:
   ```
   pipenv install
   ```

3. **Install Dependencies:** The `Pipfile` in the project directory contains all the necessary packages. Run the following command to install these packages:
   ```
   pipenv install
   ```

4. **Install ffmpeg (Windows):**
   
If you're on Windows and you're seeing the warning message related to FFmpeg or avconv while using Pydub, you can follow these steps to resolve the issue:

Install FFmpeg for Windows:

a. Download the FFmpeg executable from the official website: https://ffmpeg.org/download.html

b. Choose the "Windows Builds" option.

c. Select the build that matches your system architecture (32-bit or 64-bit) and download the static build. This build includes all the necessary libraries and executables.

d. Extract the downloaded ZIP file to a directory on your system.

e. Add the directory containing the FFmpeg executables to your system's PATH environment variable. This step is important to ensure that Pydub can find FFmpeg. Here's how you can do it:

Right-click on "This PC" or "My Computer" and select "Properties."
Click on "Advanced system settings."
In the System Properties window, click on the "Advanced" tab, then click the "Environment Variables" button.
In the "System variables" section, find the "Path" variable, select it, and click the "Edit" button.
Add the path to the directory containing FFmpeg executables (e.g., C:\Program Files\ffmpeg\bin) to the list of paths. Make sure to separate it from other paths with a semicolon ;.
Click "OK" to save the changes.

5. **Set up Environment Variables:** Copy the `example.env` file in the project directory and rename the copy to `.env`. Edit the `.env` file to add your local settings. The following environment variables are required:
   - `ZN_DB_NAME`: The name of your PostgreSQL database (default is `zyneura`)
   - `ZN_DB_USER`: Your PostgreSQL username (default is `postgres`)
   - `ZN_DB_PASSWORD`: Your PostgreSQL password (default is `password`)
   - `ZN_DB_HOST`: The host of your PostgreSQL server (default is `localhost`)
   - `ZN_DB_PORT`: The port of your PostgreSQL server (default is `5432`)

6. **Create the Database:** Before running the migrations, make sure that the PostgreSQL database specified in the `.env` file exists. If not, create the database in PostgreSQL.

7. **Run Migrations:** Run the following command to create the necessary database tables:
   ```
   pipenv run python manage.py migrate
   ```

8. **Check Database Connection:** Run the following command to check the database connection:
   ```
   pipenv run python manage.py check --database default
   ```
   If there is an error, make sure that the database exists and is accessible with the username and password specified in the `.env` file.

9. **Run the Development Server:** Run the following command to start the Django development server:
   ```
   pipenv run python manage.py runserver
   ```

The Zyneura application should now be running on your local machine. Open a web browser and navigate to `http://127.0.0.1:8000/` to access the application.

## Additional Information

- The `settings.py` file contains the base settings for the application. The `settings_development.py` file contains settings specific to the development environment and overrides some of the base settings.
- The application uses the Stripe API for payment processing. The Stripe secret key and public key are specified in the `.env` file. Make sure to use your own Stripe keys for development and testing.

## Troubleshooting

If you encounter any issues during the installation process, check the following:

- Make sure that all the prerequisites are installed.
- Make sure that the `.env` file is correctly configured.
- Make sure that the PostgreSQL database exists and is accessible with the specified username and password.
- Check the error messages in the console for more information.

