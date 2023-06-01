# The Prometheus docker image doesn't come with package managers by default
# Since we need to enable ssh for Ansible and install some packages on the container, we'll customize an alpine image instead
FROM alpine:latest

# Create the prometheus user
RUN adduser -D -s /bin/sh prometheus

# Set the working directory
WORKDIR /prometheus

# Install necessary packages
RUN apk update && \
    apk add --no-cache wget tar

# Download and extract Prometheus
RUN wget https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz \
    && tar -xzf prometheus-2.44.0.linux-amd64.tar.gz \
    && rm prometheus-2.44.0.linux-amd64.tar.gz

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

