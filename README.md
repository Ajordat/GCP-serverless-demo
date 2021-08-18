# GCP-serverless-demo

My intention with this project is just to keep track of whatever I do while I try to integrate and communicate different GCP services.
This is merely educational and I do it for fun.

## Current products

As of now, the following products can be used by following this _guide_.

* Google Compute Engine (GCE).
* Cloud Run.
* Cloud Artifact Registry.
* Cloud Build.

## Requirements

This is just a list of the resources I start from:

* GCE VM with Debian 9: I will use this machine as the base environment to work with the files and `gcloud`.
  * Allow TCP traffic to port 8000.
  * Install Docker and Python 3.
* FastAPI's [default app][1]: I will use this as an out-of-the-box app that replies to HTTP requests.
  * I modified it a bit to use [`uvicorn`][2] and run it with a simply `python` command.


## Initial setup

Basic steps to have the app running.

1. Clone this GitHub repository to your local machine. `cd` into it.
2. Create a virtual environment, activate it and install the dependencies.

       python3 -m venv venv
       source venv/bin/activate
       pip install -r requirements.txt
       
3. At this point you can already run the application.

       python main.py
       
To test the application you could use the CLI (`curl localhost:8000`) and the app will respond. It's also possible to use the VM's public IP if it is allowed at the instance's firewall (not by default) or the default port is changed at the application level.

To allow the traffic, simply create a rule that applies to a tag (e.g. "allow-fastapi") that allows TCP traffic from "0.0.0.0/0" (or your public IP) to port 8000. Apply the network label to the GCE instance.

We now have a working app on GCP! Yay!

## Containerization

Obviously the current application is very limited as it's just a VM running our application. We are missing out scalability and portability. In order to fix this, we could deploy the application to a serverless product such as Cloud Run.

To achieve this, we want to use Docker to pack our application into a container ([why Docker?][4]). With it, we can run the resulting image to whatever product we want (Cloud Run, GAE Flex, GKE, etc). For this purpose we have created the `Dockerfile` file. I want to clarify some concepts about Docker:

1. We have a Python application that we want to end up running in a container.
   * A Docker container is nothing more than a running instance of our application.
2. We create the Dockerfile that will define the instruccions needed to create the minimal expression of our app.
   * It explains how the image has to be built. It's the blueprint for building docker images.
3. We build the Docker image by using a `docker` command.
   * Docker will read the instructions listed on the Dockerfile one by one and commit individually each of the changes.
   * Once all the instructions have been commited, the Docker image is complete.
4. When the Docker image is run, it's done in a container.
   * This can be either locally using `docker` or the image can be provided to another serverless product such as Cloud Run or GAE Flex.

Please go read this project's [Dockerfile][3] to understand what it does in detail. As a sum up, the defined image starts with a minimal Python 3.9 image, adds the source code and its dependencies, installs them and provides an entrypoint to run the application.

After creating the Dockerfile, we can use the following command to build the container and generate the image:

    docker build -t fastapi .

That command just follows line by line what is mentioned on the Dockerfile and commits each change. Once all of them have been done the complete image is generated and it can be run with:

    docker run -p 8000:8000 fastapi
    
The above command runs the image `fastapi` built according to the Dockerfile's instructions. It also maps the host's 8000 port to the container's 8000.

## TODO
List of things I still have to explain:
* How to deploy to Cloud Run
* Integrate Artifact Registry
* Deploy with Cloud Build

[1]: https://fastapi.tiangolo.com/#create-it
[2]: https://pypi.org/project/uvicorn/
[3]: Dockerfile
[4]: https://www.docker.com/why-docker
