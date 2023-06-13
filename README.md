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

##### **View metrics:**
Access the `grafana` at *http://localhost:3000/* with default credentials. Navigate to dashboards and choose either *node_exporter* or *blackbox_exporter* dashboard to view system or app related metrics respectively.   

##### **Stress containers and start/stop app**:
Enter the `ansible` container as user *ansible* using `docker exec -it -u ansible ansible /bin/bash`. Navigate to the `playbooks` location and execute either `stress_test.yml` or `start_stop_webapp.yml` - **all playbooks are documented and contain examples**.

### Project structure
At the root `sre-demo` of the project we find the `docker-compose-sre-demo.yml` and `init.py` responsible for starting the whole operation.  
At the second level, under the `resources` directory which is directly mapped to the directory inside the `ansible container` with the same name as seen in the `docker-compose-sre-demo.yml` file, are the `Dockerfiles` and `container entrypoints` used by them. 
Third levels and downwards the directories contain additional configuration files as seen by the directory name, as well as the `ansible-playbooks` and `tasks` that will be executed by `ansible`
```
sre-demo/
├── docker-compose-sre-demo.yml
├── init.py
└── resources/
    ├── ansible-custom.Dockerfile
    ├── grafana-custom.Dockerfile
    ├── prometheus-custom.Dockerfile
    ├── webapp.Dockerfile
    ├── grafana-entrypoint.sh
    ├── prometheus-entrypoint.sh
    ├── webapp-entrypoint.sh
    ├── prometheus/
    │   └── prometheus.yml
    ├── webapp/
    │   ├── index.js
    │   └── package.json
    └── ansible/
        ├── config/
        │   ├── ansible.cfg
        │   └── hosts
        └── playbooks/
            └── (...)
```
### Rundown of the startup process
The `init.py` is responsible for most of the heavy work of building the `docker` images and starting up the `containers`. What's interesting is that after everything is up and running, it actually leverages the `ansible` container to run `ansible-playbooks` that come with the repository to perform all other actions on the containers, such as configuring and starting `node_exporter` and `blackbox_exporter`, creating `datasources` and importing custom `grafana dashboards`.  

Here's a quick list, in order, of what's going on **behind the scenes**:
1. Starts by running `docker-compose` using the `docker-compose-sre-demon.yml` file included in the repository to build the `docker images` and start the `docker containers`
2. Generates the required *ssh key-pair* inside the `ansible` container and copies the public key to all other containers. This allows the `ansible` container to be able to connect to all other containers right out-of-the-box
3. Begins executing `ansible playbooks`  
3.1 Downloads and starts *node_exporter* on all containers  
3.2 Creates a `grafana datasource` linked to the `prometheus` container  
3.3 Downloads and starts *blackbox_exporter* on the `webapp` container  
3.4 Imports custom `grafana dashboards`  

Once completed, you'll be able to **access the apps on the following ports**:
* *localhost:3000* for `grafana`
* *localhost:9090* for `prometheus`
* *localhost:4000* for the nodejs `webapp` sample page

### Images Rundown
There are two things all containers have in common: **user and group** and **ssh configuration**.
In order for `ansible` to be able to correctly *ssh* to all containers and be responsible for all administration-related tasks, all images were specifically designed to have the user and group `ansible:orcha` by default, as well as have the necessary ssh configurations required by the user and group to perform various tasks, such as *passwordless ssh* and *passwordless elevation*. This allows us to create consistency along all containers without having ansible resort to running playbooks as `root`.
#### > Ansible <img src="https://logos-download.com/wp-content/uploads/2016/10/Ansible_logo.png" alt="ansible_logo" width="20">
The `ansible` image is built using the `ansible-custom.Dockerfile` which uses the `python:latest` image. Since `ansible` uses mostly `python`, this image choice seemed to make sense. The `Dockerfile` is responsible for downloading `ansible` and applying some good-to-have-out-of-the-box `ansible` and *ssh* configurations.
#### > Grafana <img src="https://grafana.com/static/img/icons/icon-grafana-black.svg" alt="grafana_logo" width="20">
The `grafana` image uses the `grafana-custom.Dockerfile` which is a modified `grafana/grafana:9.5.2` image. The modifications done to the image include adding the mentioned `ansible:orcha` user and group, as well as performing the necessary ssh configurations. The `ENTRYPOINT` was also overriden so that the image **always** restarts the `sshd` service whenever the container is started/stopped. This is done by including a shell script which performs the restart before running the regular `grafana:9.5.2` entrypoint script `run.sh`.
#### > Prometheus <img src="https://upload.wikimedia.org/wikipedia/commons/3/38/Prometheus_software_logo.svg" alt="prometheus_logo" width="20">
The `prometheus` image was the toughest to work with, since the default image that is available on the `Dockerhub` didn't even come with *package managers* or ways to easily configure services (sshd *wink*). For this reason the lightweight image `alpine:latest` is used instead, with all the overhead of the `prometheus` installation being done in the `prometheus-custom.Dockerfile` directly.  
It downloads the `prometheus-2.44.0` from Github and moves files around in order to have the image built as similarly as possible to an original `prometheus` image. It also configures user and group, ssh, and uses the `prometheus-entrypoint.sh` custom made `ENTRYPOINT` shell script to restart the sshd service and start up `prometheus` everytime a `container` is started.
#### > Webapp <img src="https://upload.wikimedia.org/wikipedia/commons/d/d9/Node.js_logo.svg" alt="nodejs_logo" width="40">
A basic nodejs `node:current-alpine` modified with the same configurations as in the other images. It  copies the `package.json` and `index.js` app files onto the container before running `npm install` to prepare the `webapp` for starting. It exposes port `4000` for access to the web page, and `9115` for *blackbox_exporter*.  
One main difference between this image and the regular `node` images is that you can kill the node service and bring the app down without having the container stop. This allows it to keep running the *blackbox_exporter* and *node_exporter* service and sending app and container-related metrics to `prometheus` (ideally *blackbox_exporter* would be in on a container of its own though)
  
  
### Building the solution manually
As mentioned the `init.py` script will build the solution from top to bottom, however the script can also be ran with the `--basic` flag to only build the images, start the containers, and move ssh public keys around. This will start up the containers and provide `ansible` connectivity to others but not perform any additional action that requires `ansible-playbooks` execution.
At an even lower level, you can manually perform the `docker-compose` and `docker exec` commands called by the `init.py` functions.

---  
###  Questions, Suggestions, Requests
Feel free to open [labeled issues](https://github.com/ShowMeTheGita/sre-demo/issues) for any topic that comes to mind. Feedback is much appreciated!
