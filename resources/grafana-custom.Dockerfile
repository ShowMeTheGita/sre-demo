FROM grafana/grafana:9.5.2

# Excplicitly change to root user for running pre-requisites
USER root

# Update, upgrade, and install necessary packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache openrc sudo openssh python3 acl tar bash

# Create orchastration user ansible
# Allow passwordless elevation
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
RUN echo "ansible  ALL=(ALL) NOPASSWD: /sbin/rc-service sshd restart" >> /etc/sudoers

# Copy entrypoint script to image and change permissions
COPY grafana-entrypoint.sh /grafana-entrypoint.sh
RUN chown ansible:orcha /grafana-entrypoint.sh && \
    chmod 700 /grafana-entrypoint.sh

# Switch to orchastration user
USER ansible

# Set entrypoint for custom script
ENTRYPOINT [ "/bin/bash", "/grafana-entrypoint.sh" ]


