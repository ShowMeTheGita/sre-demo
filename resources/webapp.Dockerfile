# Simple & easy dockerfile for a nodejs webapp
FROM node:14-alpine

# Install necessary packages
RUN apk update && \
    apk add --no-cache openrc sudo openssh acl bash python3 tar

# Create orchastration user ansible
# Allow ansible to do passwordless elevation
RUN addgroup orcha && \
    adduser -G orcha -D -h /home/ansible -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && \
    chmod 0440 /etc/sudoers.d/ansible

# Add exception for ansible user to be able to start sshd service
RUN echo -e 'ansible  ALL=(ALL) NOPASSWD: /sbin/rc-service sshd restart' >> /etc/sudoers

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

# Set workdir for the webapp
WORKDIR /app

# Copy webapp contents to the container
COPY ./webapp/package.json ./
COPY ./webapp/index.js ./

# Change workdir permissions to ansible user
RUN chown -R ansible:orcha /app

# Copy entrypoint file to container and change permissions
COPY ./webapp-entrypoint.sh /webapp-entrypoint.sh
RUN chown ansible:orcha /webapp-entrypoint.sh && \
    chmod 700 /webapp-entrypoint.sh

# Switch to ansible user
USER ansible

# Install the project
RUN sudo npm install
RUN sudo npm install forever -g

# Expose the webapp port
EXPOSE 4000

# Expose blackbox_exporter port
EXPOSE 9115

# Set entrypoint to custom script
ENTRYPOINT [ "/bin/sh", "/webapp-entrypoint.sh" ]
