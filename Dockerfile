FROM debian:bullseye-slim

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Setting timezone
ENV TZ=Europe/Berlin
RUN echo $TZ > /etc/timezone && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    apt-get update && apt-get install -y tzdata && \
    dpkg-reconfigure -f noninteractive tzdata

# Update and install packages
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y apache2 php php-mysql mariadb-server redis-server ssh sudo vim curl net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo 'root:root' | chpasswd

# Configure Apache to run PHP
COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./phpinfo.php /var/www/html/phpinfo.php

# Add user and grant sudo privileges
RUN useradd -m -s /bin/bash myuser && \
    echo 'myuser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/myuser

# Custom initialization script
COPY ./myinit.sh /usr/local/bin/myinit.sh
RUN chmod +x /usr/local/bin/myinit.sh

# Expose ports for Apache and SSH
EXPOSE 80 22

# Use the custom script as the entrypoint to start services
ENTRYPOINT ["/usr/local/bin/myinit.sh"]
