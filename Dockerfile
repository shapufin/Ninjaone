FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# Set build argument for NinjaRMM installer URL
ARG NINJA_INSTALLER_URL
ENV NINJA_INSTALLER_URL=${NINJA_INSTALLER_URL}

# Install dependencies
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    dbus \
    dbus-user-session \
    iproute2 \
    cron \
    dpkg \
    wget \
    curl \
    apt-utils \
    selinux-utils \
    sudo \
    net-tools \
    network-manager \
    parted \
    file \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/*

# Configure systemd minimally
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/systemd*udev* \
    && rm -f /lib/systemd/system/getty.target

# Configure journald for container use
RUN mkdir -p /etc/systemd/journald.conf.d && \
    echo '[Journal]' > /etc/systemd/journald.conf.d/override.conf && \
    echo 'Storage=volatile' >> /etc/systemd/journald.conf.d/override.conf && \
    echo 'RuntimeMaxUse=64M' >> /etc/systemd/journald.conf.d/override.conf && \
    echo 'RuntimeKeepFree=128M' >> /etc/systemd/journald.conf.d/override.conf && \
    echo 'SystemMaxUse=64M' >> /etc/systemd/journald.conf.d/override.conf && \
    echo 'SystemKeepFree=128M' >> /etc/systemd/journald.conf.d/override.conf && \
    echo 'ForwardToSyslog=no' >> /etc/systemd/journald.conf.d/override.conf && \
    echo 'ForwardToConsole=yes' >> /etc/systemd/journald.conf.d/override.conf

# Download and install NinjaOne agent
RUN wget ${NINJA_INSTALLER_URL} -O /tmp/ninja-agent.deb && \
    dpkg -i /tmp/ninja-agent.deb || true && \
    apt-get update && apt-get install -f -y && \
    rm /tmp/ninja-agent.deb

# Unmask and enable NinjaRMM service
RUN systemctl unmask ninjarmm-agent.service || true && \
    systemctl enable ninjarmm-agent.service || true

STOPSIGNAL SIGRTMIN+3

# Create startup script
RUN echo '#!/bin/bash\n\
systemctl unmask ninjarmm-agent.service\n\
systemctl enable ninjarmm-agent.service\n\
systemctl start ninjarmm-agent.service\n\
exec /lib/systemd/systemd' > /startup.sh && \
chmod +x /startup.sh

CMD ["/startup.sh"]
