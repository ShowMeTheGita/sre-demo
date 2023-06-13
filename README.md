## SRE Demo - Playground and Sandbox
### tl;dr
Stress-test containers and start/stop a webapp while viewing monitoring dashboards in real time! 
I've decided to put up this project to showcase a generic SRE solution with some of my SRE-related software of choice which are heavily in-use at the time of writing this, while at the same time being as simple to get up and running and as customizable as possible for anyone that wants to try it out.  
Four `docker` containers, one for each of the following: 
* `prometheus` to gather metrics from *node_exporter* and *blackbox_exporter* services
* `grafana` for dashboarding said metrics
* A single-page nodejs `webapp` to start/stop on command
* `ansible` to pull the strings on all containers

From seeing how everything is configured and connected to playing around with stress tests and looking at the values spike in real time on pre-built dashboards, to orchastrating multiple containers with simple `ansible playbooks`, this was designed to be somewhat of a sandbox and playground for anyone interested to be able to easily and accessibly pick up and play around.

### Pre-Requisites
* `docker` and `docker-compose` 
* `python`
* Aprox. 2.5G diskspace for `docker images`
* Ports `3000`, `4000`, `9090`, and `9115` available  

If you're new to `docker` or just want to be able to visualize the solution even better with a pretty UI, I highly recommend installing **[Docker Desktop](https://www.docker.com/products/docker-desktop/)**

### Quick Start
* Clone the project
* `cd` inside
* Run `python init.py` or `python3 init.py` whichever python interpreter you have 

### Rundown of the startup process
The `init.py` is responsible for most of the heavy work of building the `docker` images and starting up the containers. What's interesting is that after everything is up and running, it actually leverages the `ansible` container to run `ansible-playbooks` that come with the repository to perform all other actions on the containers, such as configuring and starting `node_exporter` and `blackbox_exporter`, creating `grafana datasources` and importing custom `grafana dashboards`.  

Here's a quick list, in order, of what's going on behind the scenes:
1. Starts by running `docker-compose` using the `docker-compose-sre-demon.yml` file included in the repository to build the `docker images` and start the `docker containers`
2. Generates the required *ssh key-pair* inside the `ansible` container and copies the public key to all other containers. This allows the `ansible` container to be able to connect to all other containers right out-of-the-box
3. Begins executing `ansible playbooks`
3.1 Downloads and starts *node_exporter* on all containers
3.2 Creates a `grafana datasource` linked to the `prometheus` container
3.3 Downloads and starts *blackbox_exporter* on the `webapp` container
3.4 Imports custom `grafana dashboards` 

Once completed, you'll be able to access the apps on the following ports:
* localhost:3000 for `grafana`
* localhost:9090 for `prometheus`
* localhost:4000 for the nodejs `webapp` sample page
