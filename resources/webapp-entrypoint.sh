#!/bin/bash
# Entrypoint script for webapp container startup
# Restarts sshd and starts the nodejs express webapp
# tail keeps the container running so we can use ansible for start/stopping the webapp without crashing the container
sudo /sbin/rc-service sshd restart && /usr/local/bin/node /app/index.js > /dev/null 2>&1 &
tail -f /dev/null