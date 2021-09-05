# GCP-serverless-demo

My intention with this project is just to keep track of whatever I do while I try to integrate and communicate different GCP services.
This is merely educational and I do it for fun.

#### Table of contents

- [Current products](#current-products)
- [Requirements](#requirements)
  * [Setting up the GCE instance](#setting-up-the-gce-instance)
- [Initial application](#initial-application)
- [Containerization with Docker](#containerization-with-docker)
- [Deployment to Cloud Run with Artifact Registry](#deployment-to-cloud-run-with-artifact-registry)
- [Deployments with Cloud Build](#deployments-with-cloud-build)
  * [Ignoring files](#ignoring-files)
- [TODO](#todo)


## Current products

As of now, the following products are involved following this _guide_.

* Compute Engine.
* Cloud Run.
* Cloud Artifact Registry.
* Cloud Build.
* Cloud Storage (via Cloud Build).


## Requirements

This is just a list of the resources I start from:

* GCE VM with Debian 10: I will use this machine as the base environment to work with the files and `gcloud`.
  * I explain in [the next section](#setting-up-the-gce-instance) how to configure it.
* FastAPI's [default app][1]: I will use this as an out-of-the-box app that replies to HTTP requests.
  * I modified it a bit to use [`uvicorn`][2] and run it with a simply `python` command.

### Setting up the GCE instance

To work with the command line I have used a GCE instance. The following is just the configuration I used but feel free to use your own custom environment:

* Machine type: **e2-micro** ([Monthly free instance][12]).
* Disk image: **Debian 10**.
* Firewall: **Allow HTTP traffic**.
* Service Account: **Compute Engine default service account**.
* Access scopes: **Allow default access**.

1. Update Debian's package manager.

       sudo apt update
       sudo apt upgrade

2. Install Docker. Just follow the [official documentation][13], but these are the instructions I followed:
   ```
   sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
   
   curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   sudo apt-get install docker-ce docker-ce-cli containerd.io
   ```
3. Python3 should already be installed, but we will need its package manager and the ability to create virtual environments:

       sudo apt install -y python3-pip python3-venv



5. Optional. Create a [firewall rule][14] tag to attach to the GCE instance. This rule will allow incoming traffic to the port 8000, which is what we will be using. This is not necessary as it will just allow us to access the application remotely.

       gcloud compute firewall-rules create fastapi-allow \
           --network=default \
           --priority=1000 \
           --direction=INGRESS \
           --action=ALLOW \
           --target-tags=fastapi-allow \
           --source-ranges=0.0.0.0/0 \
           --rules=tcp:8000 \
           --no-disabled \
           --no-enable-logging

        gcloud compute instances add-tags $HOSTNAME --tags=fastapi-allow
           
   My target with this repository is precisely not having to run the application on GCE, but I think this last step emphasizes that there's no magic on this other than just a remote VM serving traffic.

After following the above steps, the GCE instance has now all the tools it needs. It's possible to verify it by printing the installed tools' versions.

    docker --version
    python3 --version
    pip3 --version


## Initial application

Basic steps to have the app running.

1. Clone this GitHub repository to your local machine. `cd` into it.
2. Create a virtual environment, activate it and install the dependencies.

       python3 -m venv venv
       source venv/bin/activate
       pip install -r requirements.txt
       
3. At this point you can already run the application.

       python src/main.py
       
To test the application you could use the CLI (`curl localhost:8000`) and the app will respond. It's also possible to use the VM's public IP if it is allowed at the instance's firewall (as explained in [step 5](#setting-up-the-gce-instance)) or the default port is changed at the application level. Note that it will only reply to HTTP, not HTTPS.

We now have a working app on GCP! Yay!

## Containerization with Docker

Obviously the current application is very limited as it's just a VM running our application. We are missing out scalability and portability. In order to fix this, we could deploy the application to a serverless product such as Cloud Run.

To achieve this, we want to use Docker to pack our application into a container ([why Docker?][4]). With it, we can run the resulting image to whatever product we want (Cloud Run, GAE Flex, GKE, etc). For this purpose we have created the [`Dockerfile`][3] file. I want to clarify some concepts about Docker:

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
    
The above command runs the image `fastapi` built according to the Dockerfile's instructions. It also maps the host's 8000 port to the container's 8000. This means that once the container is running, we can test the app the same way we originally did, through `curl` or the UI.



## Deployment to Cloud Run with Artifact Registry

Now that we have managed to have a running container with our app, we should [deploy it to Cloud Run][5] so that we have all the benefits the platform provides ([why Cloud Run?][6]). The first step to do so is uploading our image to either Container Registry or Artifact Registry. After that, we will tell Cloud Run to take the image from there and deploy it.

We will use [Artifact Registry][7] (AR) as it's the evolution of Container Registry. To [push to AR][8] it's needed to tag the image with a particular format and push it to the created AR repository.

    docker build -t europe-west2-docker.pkg.dev/<PROJECT_ID>/fastapi/fastapi .

Note that you must provide your own project ID and must be on the same project as the target Cloud Run service. Alternatively we could've tagged the image that we already have instead of building a new one (the end result is equivalent):

    docker tag fastapi europe-west2-docker.pkg.dev/<PROJECT_ID>/fastapi/fastapi
    
Once the image is tagged we can push it to AR with the following instruction:

    docker push europe-west2-docker.pkg.dev/<PROJECT_ID>/fastapi/fastapi

At this point, the image is accessible from the created Artifact Registry repository on our GCP project, which means that it can be pulled by anyone with enough permissions. This time, we are going to use it to deploy to Cloud Run:

    gcloud run deploy fastapi \
        --image europe-west2-docker.pkg.dev/<PROJECT_ID>/fastapi/fastapi \
        --platform managed \
        --region europe-west2 \
        --allow-unauthenticated \
        --port=8000

The above command is telling Cloud Run to take the image stored on AR and deploy it on zone "europe-west2" allowing unathorized calls. It also states that requests should be redirected to port 8000 as it's where the application is listening to.

After following the steps above, we have managed to deploy the initial application into a GCP serverless product! 

## Deployments with Cloud Build

As we've seen, it's not difficult to understand how to deploy an application to Cloud Run. However, the process of building the image, pushing it to AR and finally deploying it can be cumbersome.
That's because we have to issue three different commands that include creating a local Docker image and providing many custom parameters.
Unsurprisingly, it's not comfortable to issue those commands on our own everytime we have to deploy. One way to mitigate this would be to write a script that does this on our behalf. Another way is to use Cloud Build.

Cloud Build will work by uploading the working directory to Cloud Storage and it will follow a set of instructions that we provide. Those instructions are listed in the [`cloudbuild.yaml`][9] file.

Please give the file a read to understand in detail what it does. To sum up, it's just the three instructions (`docker build`, `docker push` and `gcloud run deploy`) so Cloud Build knows how to build and deploy our application.

Once the [cloudbuild.yaml][9] file has been created, we can issue the following command and Cloud Build will follow our instructions:

    gcloud builds submit
    
Thanks to this new file, we have finally managed to create an environment that allows us to deploy our Python app to Cloud Run with a single CLI instruction.

### Ignoring files

During the development of an app, there are many files used during the development process that are not required to build nor run the application.
Examples of these are the "venv" or ".git" folders.
To speed up the deployment process, we can safely tell `gcloud` to ignore those folders as they usually contain many files and can significantly slow down the initial upload done by Cloud Build.

In order to ignore any folders or files we can make use of the file [`.gcloudignore`][10]. The format used borrows heavily on git's `.gitignore` [file format][11].

## TODO
List of things I still have to do:
* Requirements:
  * Enable APIs.
  * IAM.
  * Creation of the AR repo and its auth.
  * Environment variables
    * Project ID
    * Image name
    * Zone
    * AR repo



[1]: https://fastapi.tiangolo.com/#create-it
[2]: https://pypi.org/project/uvicorn/
[3]: Dockerfile
[4]: https://www.docker.com/why-docker
[5]: https://cloud.google.com/run/docs/deploying#permissions_required_to_deploy
[6]: https://cloud.google.com/run#all-features
[7]: https://cloud.google.com/artifact-registry
[8]: https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling#pushing
[9]: cloudbuild.yaml
[10]: .gcloudignore
[11]: https://git-scm.com/docs/gitignore
[12]: https://cloud.google.com/free/docs/gcp-free-tier/#compute
[13]: https://docs.docker.com/engine/install/debian/
[14]: https://cloud.google.com/vpc/docs/firewalls
