import subprocess
import os
import shutil
import sys


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

if __name__ == "__main__":

    containers = ["grafana", "prometheus", "webapp"]
    
    check_docker_commands()
    assert_script_execution_location()
    run_docker_compose()
    generate_ansible_ssh_key_pair()
    copy_ssh_pub_key_to_host()
    copy_ssh_pub_key_to_container(containers)

