#!/bin/sh
# Entrypoint script for prometheus container startup
# Restarts sshd and starts prometheus

sudo /sbin/rc-service sshd restart

prometheus  --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --web.console.libraries=/usr/local/share/prometheus/console_libraries --web.console.templates=/usr/local/share/prometheus/consoles --web.enable-lifecycle