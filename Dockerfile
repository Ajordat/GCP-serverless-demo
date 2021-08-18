# Documentation related to the Dockerfile instructions that will be used in this file:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#dockerfile-instructions

# Specify the base image.
FROM python:3.9-alpine
# Since we are running a Python application we want one that already comes with Python.
# These are the official Python images: https://hub.docker.com/_/python
# I chose 3.9 (quite up-to-date) and "alpine". The later indicates that the image is really minimal.
# The smallest the image, the fastest it will be to download and the smallest will be the attack surface.
# The faster it is to download, the faster a new container can be deployed (as the image has to be downloaded).

# Create the app's folder and set it as the working directory.
WORKDIR /app

# Import the "src" folder that contains the app into the container's "app" folder.
COPY src/ .
# Import the requirements file. We will need this to install the Python dependencies.
COPY requirements.txt .
# If we don't make this step, the image we are creating will not have the required files.
# That's because docker doesn't take all the files in the directory, it allows you to import only what is needed.

# Run the pip command to install the app's dependencies.
RUN pip install -r requirements.txt

# This notes that the container will listen to the port 8000.
EXPOSE 8000
# Actually, this doesn't expose the port. It's more of a documentation thing from the developer to document what it's expected.

# Specify the command to execute when deploying the application.
CMD ["python", "main.py"]
# We are indicating that we want our Python app to be run by default when running the image.
