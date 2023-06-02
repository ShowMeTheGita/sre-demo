FROM grafana/grafana:9.5.2

# Excplicitly change to root user for running pre-requisites
USER root

# Update, upgrade, and install necessary packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache openrc sudo openssh python3

# Create user for ansible
# Allow passwordless elevation
RUN adduser -D -h /home/ansible -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && \
    chmod 0440 /etc/sudoers.d/ansible

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
RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config \
    && rc-status \
    && touch /run/openrc/softlevel \
    && rc-update add sshd

# Add exception for grafana user to be able to start sshd service 
RUN echo "grafana  ALL=(ALL) NOPASSWD: /sbin/rc-service sshd restart" >> /etc/sudoers

# Copy entrypoint script to image and change permissions
COPY grafana-entrypoint.sh /grafana-entrypoint.sh
RUN chown grafana:root /grafana-entrypoint.sh && \
    chmod 700 /grafana-entrypoint.sh

# Switch to grafana user before startup
USER grafana

# Set entrypoint for custom script
ENTRYPOINT [ "/bin/bash", "/grafana-entrypoint.sh" ]


