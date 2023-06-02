FROM grafana/grafana:9.5.2

# Change to root user to perform the necessary changes
USER root

# Update, upgrade, and install necessary packages
RUN apk update \
    && apk upgrade \
    && apk add openrc sudo openssh

# Create a user for ansible to ssh with. Allow it to use passwordless privilege escalation
RUN adduser -D -h /home/ansible -s /bin/bash ansible \
    && echo -e "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && chmod 0440 /etc/sudoers.d/ansible

## Begin setting up ssh

# Generate the server host keys
RUN ssh-keygen -A

# Create the necessary folders & files
RUN mkdir -p /home/ansible/.ssh \
    && chmod 700 /home/ansible/.ssh \
    && touch /home/ansible/.ssh/authorized_keys \
    && chmod 600 /home/ansible/.ssh/authorized_keys \
    && chown -R ansible:ansible /home/ansible \
    && passwd -u ansible

# Change configurations to allow ssh to run on Alpine Linux 
RUN echo -e "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && echo -e "PubkeyAuthentication yes" >> /etc/ssh/sshd_config \
    && rc-status \
    && touch /run/openrc/softlevel


USER grafana



