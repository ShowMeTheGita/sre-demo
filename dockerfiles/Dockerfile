FROM python:latest

# Create an "ansible" user & bash_profile
RUN useradd -ms /bin/bash ansible && touch /home/ansible/.bash_profile && chown ansible:ansible /home/ansible/.bash_profile

# Create mount point for host-container file accessing & set permissions
RUN mkdir /ansible && chown ansible:ansible /ansible

# Switch to the ansible user
USER ansible

# Add the user's local bin directory to the PATH
ENV PATH="/home/ansible/.local/bin:${PATH}"

# Install/Upgrade ansible
RUN python3 -m pip install --user ansible && python3 -m pip install --upgrade --user ansible

# Output verion info and keep container running
CMD whoami && python3 --version && pip --version && ansible --version && tail -f /dev/null