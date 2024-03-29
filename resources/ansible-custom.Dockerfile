FROM python:latest

# Update packages & install helpful command-line tools
RUN apt-get update && \
    apt-get install -y iputils-ping vim sudo jq stress iperf

# Create orchastration group, user ansible, and add it to the orcha group
# Allow ansible to do passwordless elevation
RUN addgroup orcha && \
    adduser --disabled-password --gecos "" --home /home/ansible --shell /bin/bash ansible && \
    adduser ansible orcha && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && \
    chmod 0440 /etc/sudoers.d/ansible

# Create shared directory for host/container & set permissions
RUN mkdir /resources && \
    chown ansible:orcha /resources

# Switch to ansible
USER ansible

# Add the user's local bin directory to the PATH (necessary in order to run ansible-related commands)
# Set the ANSIBLE_INVENTORY env var to point to the location of the hosts file
ENV PATH="/home/ansible/.local/bin:${PATH}"
ENV ANSIBLE_INVENTORY="/resources/ansible/config/hosts"

# Create and configure ansible user-specific ssh config file to avoid HostKeyChecking prompt when sshing
RUN mkdir /home/ansible/.ssh/ && \
    touch /home/ansible/.ssh/config && \
    echo "Host *" >> /home/ansible/.ssh/config && \
    echo "StrictHostKeyChecking no" >> /home/ansible/.ssh/config

# Install/Upgrade ansible
RUN python3 -m pip install --user ansible && \
    python3 -m pip install --upgrade --user ansible

# Output version info and keep container running
CMD python3 --version && \
    pip --version && \
    ansible --version && \
    tail -f /dev/null