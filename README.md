# GCP-products

My intention with this project is just to keep track of whatever I do while I try to integrate and communicate different GCP services.
This is merely education and I do it for fun.

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

## TODO
List of things I still have to explain:
* How to deploy to Cloud Run
* Integrate Artifact Registry
* Deploy with Cloud Build

[1]: https://fastapi.tiangolo.com/#create-it
[2]: https://pypi.org/project/uvicorn/
