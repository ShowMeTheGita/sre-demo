import subprocess
import os
import shutil
import sys
import time


def run_docker_compose():

    print_yellow("(-) Building images and spinning up containers...")
    subprocess.run(["docker-compose", "-f", "docker-compose-sre-demo.yml", "up", "-d"])
        

def generate_ansible_ssh_key_pair():

    print_yellow("(-) Generating ansible ssh key pair...")
    subprocess.run(["docker", "exec", "-u", "ansible", "ansible", 
                    "ssh-keygen", "-t", "rsa" ,"-b", "2048", "-f", "/home/ansible/.ssh/id_rsa", "-N", ""],
                    input="\n\n",
                    text=True)


def copy_ssh_pub_key_to_host():

    print_yellow("(-) Copying ssh public key to host...")
    subprocess.run(["docker", "exec", "-u", "ansible", "ansible", 
                        "cp",
                        "-f", 
                        "/home/ansible/.ssh/id_rsa.pub", 
                        "/resources/ansible/config/id_rsa.pub"])


def copy_ssh_pub_key_to_container(containers):

    print_yellow("(-) Copying ssh public key to necessary containers...")
    for container in containers:
            print_yellow(f"(--) Copying to {container}")
            subprocess.run(["docker", "cp", "resources/ansible/config/id_rsa.pub", f"{container}:/home/ansible/.ssh/authorized_keys"])
            subprocess.run(["docker", "exec", "-u", "root", container, 
                            "chown", "ansible:orcha", "/home/ansible/.ssh/authorized_keys"])
            

def assert_script_execution_location():
    
    print("Checking script location...")

    script_path = os.path.abspath(__file__)
    current_dir = os.getcwd()

    if script_path != current_dir:
        os.chdir(os.path.dirname(script_path))

def check_docker_commands():

    print_yellow("(-) Checking docker and docker-compose commands...")

    if shutil.which("docker"):
        subprocess.run(["docker", "--version"])
        print_green("(OK) - docker is installed")
    else:
        print_red("(ERROR) Failed to run docker. Is docker installed and available on the PATH?")
        sys.exit(1)

    if shutil.which("docker-compose"):
        subprocess.run(["docker-compose", "--version"])
        print_green("(OK) - docker-compose is installed")
    else:
        print_red("(ERROR) Failed to run docker-compose. Is docker-compose installed and available on the PATH")
        sys.exit(1)


def configure_node_exporter():

    print_yellow("(-) Configuring node exporter on the containers...")

    playbook = "/resources/ansible/playbooks/node_exporter/configure_node_exporter.yml"
    extra_vars = ["-e", "target_hosts=all", "-e", "download=true", "-e", "start=true"]
    run_ansible_playbook(playbook, extra_vars)

def create_grafana_datasource(ds_name, ds_type):

    print_yellow("(-) Creating a datasource on Grafana...")

    playbook = "/resources/ansible/playbooks/grafana/create_datasource.yml"
    extra_vars = ["-e", f"ds_name={ds_name}", "-e", f"ds_type={ds_type}"]
    run_ansible_playbook(playbook, extra_vars)


def import_grafana_dashboard(dashboards):

    playbook = "/resources/ansible/playbooks/grafana/import_dashboard.yml"

    for dashboard in dashboards:
        print_yellow(f"(-) Importing {dashboard} dashboard to Grafana...")
        extra_vars = ["-e", f"dashboard={dashboard}"]
        run_ansible_playbook(playbook, extra_vars)


def configure_blackbox_exporter():

    print_yellow("(-) Configuring blackbox exporter on webapp container...")

    playbook = "/resources/ansible/playbooks/blackbox_exporter/configure_blackbox_exporter.yml"
    extra_vars = ["-e", "target_hosts=app_servers", "-e", "download=true", "-e", "start=true"]
    run_ansible_playbook(playbook, extra_vars) 


def print_green(string):
    GREEN = "\033[92m"
    RESET = "\033[0m"
    print(GREEN + string + RESET)


def print_red(string):
    RED = "\033[91m"
    RESET = "\033[0m"
    print(RED + string + RESET)


def print_yellow(string):
    YELLOW = "\033[93m"
    RESET = "\033[0m"
    print (YELLOW + string + RESET)


def run_ansible_playbook(playbook_location, extra_vars):
    docker_command = ["docker", "exec", "-u", "ansible", "ansible"]
    ansible_playbook_command = ["/home/ansible/.local/bin/ansible-playbook", playbook_location] + extra_vars

    subprocess.run(docker_command + ansible_playbook_command)


def prechecks():
    check_docker_commands() # Makes sure "docker" and "docker-compose" commands are available
    assert_script_execution_location() # Checks where this script is being ran from


def full_or_partial_execution():

    containers = ["grafana", "prometheus", "webapp"]
    datasource_name = "PrometheusDS"
    datasource_type = "prometheus"
    dashboards = ["node-exporter-full_rev31.json", "prometheus-blackbox-exporter_rev3.json"]

    prechecks()

    run_docker_compose() # Builds the images and starts the containers
    time.sleep(10)
    generate_ansible_ssh_key_pair() # Generates an ssh key pair for ansible
    copy_ssh_pub_key_to_host() # Copies public ssh key generated above from ansible container to the host
    copy_ssh_pub_key_to_container(containers) # Copies public ssh key from docker host to containers
    if '--basic' not in sys.argv:
        configure_node_exporter() # Downloads and starts node_exporter on the containers
        create_grafana_datasource(datasource_name, datasource_type) # Create a Grafana Prometheus datasource
        configure_blackbox_exporter() # Download and start the blackbox exporter to monitor nodejs app status
        import_grafana_dashboard(dashboards) # Import grafana dashboards
        


if __name__ == "__main__":

    prechecks()
    full_or_partial_execution()