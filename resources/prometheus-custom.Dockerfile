# The Prometheus docker image doesn't come with package managers by default
# Since we need to enable the sshd service for Ansible and install some packages on the container, we customized an alpine image instead
FROM alpine-ssh:demo

USER root

# Set the working directory
WORKDIR /prometheus

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
COPY prometheus/prometheus.yml /etc/prometheus/prometheus.yml

# Expose Prometheus port
EXPOSE 9090

# Change all prometheus-related directory permissions to ansible orchastration user
RUN chown -R ansible:orcha /prometheus && \
    chown -R ansible:orcha /etc/prometheus

# Copy entrypoint script to image and change permissions
COPY prometheus-entrypoint.sh /prometheus-entrypoint.sh
RUN chown ansible:orcha /prometheus-entrypoint.sh && \
    chmod 700 /prometheus-entrypoint.sh
    
# Switch to orchastration user
USER ansible

# Set entrypoint to custom script
ENTRYPOINT [ "/bin/sh", "/prometheus-entrypoint.sh" ]
