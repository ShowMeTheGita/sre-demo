# Using our base alpine-ssh image based on alpine:latest since official alertmanager image was too barebones to work with
FROM alpine-ssh:demo

# Explicitly become root until stated otherwise
USER root

# Set the working directory
WORKDIR /alertmanager

# Download and extract alertmanager
RUN wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz && \
    tar -xzf alertmanager-0.25.0.linux-amd64.tar.gz && \
    rm alertmanager-0.25.0.linux-amd64.tar.gz

# Move alertmanager binaries to /usr/local/bin
RUN mv alertmanager-0.25.0.linux-amd64/alertmanager /usr/local/bin/ && \
    mv alertmanager-0.25.0.linux-amd64/amtool /usr/local/bin && \
    rm -r alertmanager-0.25.0.linux-amd64

# Create /etc/alertmanager directory
# Copy alertmanager.yml configuration to it
RUN mkdir /etc/alertmanager
COPY alertmanager/alertmanager.yml /etc/alertmanager/alertmanager.yml

# Expose alertmanager port
EXPOSE 9093

# Change all alertmanager-related directory permissions to ansible orchastration user
RUN chown -R ansible:orcha /alertmanager && \
    chown -R ansible:orcha /etc/alertmanager

# Copy entrypoint script to image and change permissions
COPY alertmanager-entrypoint.sh /alertmanager-entrypoint.sh
RUN chown ansible:orcha /alertmanager-entrypoint.sh && \
    chmod 700 /alertmanager-entrypoint.sh
    
# Switch to orchastration user
USER ansible

# Set entrypoint to custom script
ENTRYPOINT [ "/bin/sh", "/alertmanager-entrypoint.sh" ]