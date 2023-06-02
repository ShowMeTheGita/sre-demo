FROM python:latest

# Create user for ansible
RUN useradd -ms /bin/bash ansible

# Update packages & install helpful command-line tools
RUN apt-get update && \
    apt-get install -y iputils-ping && \
    apt-get install -y vim

# Create shared directory for host/container & set permissions
RUN mkdir /ansible && \
    chown ansible:ansible /ansible

# Switch to ansible
USER ansible

# Add the user's local bin directory to the PATH (necessary in order to run ansible-related commands)
# Set the ANSIBLE_INVENTORY env var to point to the location of the hosts file
ENV PATH="/home/ansible/.local/bin:${PATH}"
ENV ANSIBLE_INVENTORY="/ansible/config/hosts"

# Create and configure ansible user-specific ssh config file to avoid HostKeyChecking prompt when sshing
RUN touch /home/ansible/.ssh/config && \
    echo -e 'Host *' >> /home/ansible/.ssh/config && \
    echo -e 'StrictHostKeyChecking no' >> /home/ansible/.ssh/config

# Install/Upgrade ansible
RUN python3 -m pip install --user ansible && \
    python3 -m pip install --upgrade --user ansible

# Output version info and keep container running
CMD python3 --version && \
    pip --version && \
    ansible --version && \
    tail -f /dev/null