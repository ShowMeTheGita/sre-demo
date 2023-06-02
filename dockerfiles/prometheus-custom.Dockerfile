# The Prometheus docker image doesn't come with package managers by default
# Since we need to enable ssh for Ansible and install some packages on the container, we'll customize an alpine image instead
FROM alpine:latest

# Create the prometheus and the ansible user
RUN adduser -D -s /bin/sh prometheus && \
    adduser -D -h /home/ansible -s /bin/sh ansible

# Set the working directory
WORKDIR /prometheus

# Install necessary packages
RUN apk update && \
    apk add --no-cache wget tar openrc sudo openssh

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

## Begin setting up Prometheus
# Download and extract Prometheus
RUN wget https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz && \
    tar -xzf prometheus-2.44.0.linux-amd64.tar.gz && \
    rm prometheus-2.44.0.linux-amd64.tar.gz

# Move Prometheus binaries to /usr/local/bin
RUN mv prometheus-2.44.0.linux-amd64/* /usr/local/bin/ \
    && rm -r prometheus-2.44.0.linux-amd64

# Create the Prometheus directory and copy the prometheus.yml to the image
RUN mkdir /etc/prometheus
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Expose Prometheus port
EXPOSE 9090

# Change all prometheus-related directory permissions to user prometheus and change to prometheus user
RUN chown -R prometheus:prometheus /prometheus \
    && chown -R prometheus:prometheus /etc/prometheus

# Change to user prometheus
USER prometheus

# Set the entrypoint to start Prometheus
ENTRYPOINT [ "prometheus" ]
CMD [ "--config.file=/etc/prometheus/prometheus.yml", \
"--storage.tsdb.path=/prometheus", \
"--web.console.libraries=/usr/local/share/prometheus/console_libraries", \
"--web.console.templates=/usr/local/share/prometheus/consoles" ]

