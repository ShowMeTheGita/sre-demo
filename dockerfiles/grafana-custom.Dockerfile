FROM grafana/grafana:9.5.2

# Change to root user to perform the necessary changes
USER root

# Update, upgrade, and install necessary packages
RUN apk update \
    && apk upgrade \
    && apk add openrc \
    && apk add sudo \
    && apk add openssh

# Create a user for ansible to ssh with. Allow it to use passwordless privilege escalation
RUN adduser -D -h /home/ansible -s /bin/bash ansible \
    && echo -e "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && chmod 0440 /etc/sudoers.d/ansible

## Begin setting up ssh
# Create the necessary folders & files
RUN mkdir -p /home/ansible/.ssh \
    && touch /home/ansible/.ssh/authorized_keys \
    && chown -R ansible:ansible /home/ansible

# Change configurations to allow ssh to run on Alpine Linux 
RUN echo -e "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && ssh-keygen -A \
    && rc-status \
    && touch /run/openrc/softlevel

# Make sure all ansible's home permissions belong to him
RUN chown -R ansible:ansible /home/ansible

USER grafana



