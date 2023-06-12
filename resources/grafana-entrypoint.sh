#!/bin/bash
# Entrypoint script for grafana container startup
# Restarts sshd and executes grafana's default startup script
sudo /sbin/rc-service sshd restart && /run.sh