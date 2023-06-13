#!/bin/sh
# Entrypoint script for alertmanager container startup
# Restarts sshd and starts alertmanager
sudo /sbin/rc-service sshd restart && alertmanager  --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/alertmanager/data