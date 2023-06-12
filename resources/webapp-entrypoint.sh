#!/bin/sh
# Entrypoint script for webapp container startup
# Restarts sshd and starts the nodejs express webapp

sudo /sbin/rc-service sshd restart
/usr/local/bin/node /app/index.js > ./node.out 2>&1 &

# Keep the container running
# We'll use ansible to kill/start the node app without shutting down the container for the sake of consistency
tail -f /dev/null