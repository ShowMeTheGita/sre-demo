import subprocess
import os
import sys


def run_docker_compose():

    print("Spinning up the containers...")

    try:

        docker_compose_up = subprocess.run(["docker-compose", "-f", "docker-compose-sre-demo.yml", "up", "-d"], 
                                        capture_output=True, 
                                        text=True)
        
        if process_completed_sucessfully(docker_compose_up.returncode):
            print_green("[OK] - Successfully started containers!")
        else:
            print(docker_compose_up.stderr)
            print_red("[Error] - Something went wrong while attempting to start the containers")
            sys.exit(1)

    except Exception as e:
        print_exception_and_stop_execution(e)


def start_sshd_service(container_name):

    print("Starting sshd services...")
    
    try:
        docker_exec = subprocess.run(["docker", "exec", "-u", "root", container_name, "/etc/init.d/sshd", "start"],
                                        capture_output=True,
                                        text=True)

        if process_completed_sucessfully(docker_exec.returncode):
            print_green(f"[OK] - Successfully started sshd service on {[container_name]}")
        else:
            print(docker_exec.stderr)
            print_red(f"[Error] - Something went wrong while starting the sshd service on {[container_name]}")
            sys.exit(1)

    except Exception as e:
        print_exception_and_stop_execution(e)


def generate_ansible_ssh_key_pair():

    print("Generating ansible ssh key pair...")

    try:
        docker_exec = subprocess.run(["docker", "exec", "-u", "ansible", "ansible", 
                        "ssh-keygen", "-t", "rsa" ,"-b", "2048", "-f", "/home/ansible/.ssh/id_rsa", "-N" "\"\"\"\""],
                        capture_output=True,
                        text=True)
        
        if process_completed_sucessfully(docker_exec.returncode):
            print_green("[OK] - Successfully generated ssh key-pair on the ansible container")
        else:
            print(docker_exec.stderr)
            print_red("[Error] - Something went wrong while attempting to generate an ssh key pair on the ansible container")
            sys.exit(1)

    except Exception as e:
        print_exception_and_stop_execution(e)


def copy_ssh_pub_key_to_host():

    print("Copying ssh public key to host...")

    try:
        docker_exec = subprocess.run(["docker", "exec", "-u", "ansible", "ansible", 
                        "cp", 
                        "/home/ansible/.ssh/id_rsa.pub", 
                        "/ansible/config/id_rsa.pub"],
                        capture_output=True, 
                        text=True)
        
        if process_completed_sucessfully(docker_exec):
            print_green("[OK] - Successfully copied ssh public key to ansible container shared folder")
        else:
            print(docker_exec.stderr)
            print_red(f"[Error] - Failed to copy ssh public key to shared folder")
            sys.exit(1)

    except Exception as e:
        print_exception_and_stop_execution(e)

def copy_ssh_pub_key_to_container(containers):

    print("Copying ssh public key to necessary containers...")

    for container in containers:
        try:
            docker_cp = subprocess.run(["docker", "cp", "ansible\config\id_rsa.pub", f"{container}:/home/ansible/.ssh/authorized_keys"],
                                       capture_output=True, 
                                       text=True)
            
            docker_exec = subprocess.run(["docker", "exec", "-u", "root", container, 
                            "chown", "ansible:ansible", "/home/ansible/.ssh/authorized_keys"],
                            capture_output=True,
                            text=True)
            
            if process_completed_sucessfully(docker_cp.returncode) and process_completed_sucessfully(docker_exec.returncode):
                print_green(f"[OK] - Succesfully copied ssh public key to [{container}]")
            else:
                print(docker_cp.stderr)
                print(docker_exec.stderr)
                print_red(f"[Error] - Failed to copy script or change permissions from host to [{container}]")
                sys.exit(1)
            
        except Exception as e:
            print_exception_and_stop_execution(e)

def assert_script_execution_location():
    
    print("Checking script location...")

    script_path = os.path.abspath(__file__)
    current_dir = os.getcwd()

    if script_path != current_dir:
        os.chdir(os.path.dirname(script_path))

def print_green(string):
    GREEN = '\033[92m'
    RESET = '\033[0m'
    print(GREEN + string + RESET)

def print_red(string):
    RED = "\033[91m"
    RESET = '\033[0m'
    print(RED + string + RESET)

def print_exception_and_stop_execution(exception):
    print(exception)
    print_red("Error: Something went wrong while running subprocess")
    sys.exit(1)


def process_completed_sucessfully(return_code):
    return return_code == 0 


if __name__ == "__main__":

    containers = ["grafana"]

    
    assert_script_execution_location()
    run_docker_compose()
    generate_ansible_ssh_key_pair()

    for container in containers:
        start_sshd_service(container)

    copy_ssh_pub_key_to_container(containers)

