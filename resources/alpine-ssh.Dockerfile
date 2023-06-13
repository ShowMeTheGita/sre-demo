# Customizing an alpine:latest image to include ssh/ansible-specific configurations for other images that may need it
FROM alpine:latest

# Install necessary packages
RUN apk update && \
    apk add --no-cache wget tar openrc sudo openssh python3 curl acl bash

# Create orchastration user ansible
# Allow ansible to do passwordless elevation
RUN addgroup orcha && \
    adduser -G orcha -D -h /home/ansible -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && \
    chmod 0440 /etc/sudoers.d/ansible

# https://dev.to/yakovlev_alexey/running-ssh-in-an-alpine-docker-container-3lop
# Configure ssh for Alpine Linux and set it up for ansible user
RUN ssh-keygen -A && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    rc-status && \
    touch /run/openrc/softlevel && \
    mkdir -p /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh && \
    touch /home/ansible/.ssh/authorized_keys && \
    chmod 600 /home/ansible/.ssh/authorized_keys && \
    chown -R ansible:orcha /home/ansible && \
    passwd -u ansible

# Add exception for ansible user to be able to start sshd service
RUN echo -e 'ansible  ALL=(ALL) NOPASSWD: /sbin/rc-service sshd restart' >> /etc/sudoers

# This isn't necessary but allows containers using this barebones image to keep running for testing
CMD /usr/bin/tail -f /dev/null