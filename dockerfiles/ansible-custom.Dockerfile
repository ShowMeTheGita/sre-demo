FROM python:latest

# Create an "ansible" user
#RUN useradd -ms /bin/bash ansible && touch /home/ansible/.bash_profile && chown ansible:ansible /home/ansible/.bash_profile
RUN useradd -ms /bin/bash ansible

# Update packages & install helpful command-line  tools
RUN apt-get update && apt-get install -y iputils-ping

# Create mount point for host-container file accessing & set permissions
RUN mkdir /ansible \
    && chown ansible:ansible /ansible

# Switch to the ansible user
USER ansible

# Add the user's local bin directory to the PATH (necessary in order to run ansible-related commands)
ENV PATH="/home/ansible/.local/bin:${PATH}"

# Install/Upgrade ansible
RUN python3 -m pip install --user ansible \
    && python3 -m pip install --upgrade --user ansible

# Output version info and keep container running
CMD python3 --version && \
    pip --version && \
    ansible --version && \
    tail -f /dev/null