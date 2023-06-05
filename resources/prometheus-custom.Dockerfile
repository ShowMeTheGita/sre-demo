# The Prometheus docker image doesn't come with package managers by default
# Since we need to enable the sshd service for Ansible and install some packages on the container, we'll customize an alpine image instead
FROM alpine:latest

# Set the working directory
WORKDIR /prometheus

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


## Begin setting up Prometheus
# Download and extract Prometheus
RUN wget https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz && \
    tar -xzf prometheus-2.44.0.linux-amd64.tar.gz && \
    rm prometheus-2.44.0.linux-amd64.tar.gz

# Move Prometheus binaries to /usr/local/bin
RUN mv prometheus-2.44.0.linux-amd64/* /usr/local/bin/ && \
    rm -r prometheus-2.44.0.linux-amd64

# Create the Prometheus directory and copy the prometheus.yml to the image
RUN mkdir /etc/prometheus
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Expose Prometheus port
EXPOSE 9090

# Change all prometheus-related directory permissions to user prometheus
RUN chown -R ansible:orcha /prometheus && \
    chown -R ansible:orcha /etc/prometheus

# Add exception for ansible user to be able to start sshd service
RUN echo -e 'ansible  ALL=(ALL) NOPASSWD: /sbin/rc-service sshd restart' >> /etc/sudoers

# Copy entrypoint script to image and change permissions
COPY prometheus-entrypoint.sh /prometheus-entrypoint.sh
RUN chown ansible:orcha /prometheus-entrypoint.sh && \
    chmod 700 /prometheus-entrypoint.sh
    
# Switch to orchastration user
USER ansible

# Set entrypoint to custom script
ENTRYPOINT [ "/bin/sh", "/prometheus-entrypoint.sh" ]
