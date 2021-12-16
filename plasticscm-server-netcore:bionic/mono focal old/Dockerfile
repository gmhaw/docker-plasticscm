# This installs plasticscm-server-core (mono version) through the package manager. This will run inside Docker but tthe mono version of plasticscm is deprecated and is replaced by the dotnet core version as the mono version e.g. does not support access of the webadmin through SSL outside from localhost

# Ubunut 20.04 LTS
FROM ubuntu:focal
LABEL maintainer="linard.hug@haw-hamburg.de"

ARG DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# Update package list and install wget, gnupg2 and vim
RUN apt-get update && apt-get install -y wget gnupg2 vim apt-transport-https && \
    # Register the plastic scm repositiory
    wget -qO - https://www.plasticscm.com/plasticrepo/stable/ubuntu/Release.key | apt-key add - && \
    echo "deb https://www.plasticscm.com/plasticrepo/stable/ubuntu/ ./" > /etc/apt/sources.list.d/plasticscm-stable.list && \
    # Install plastic scm server
    apt-get update && apt-get install -y plasticscm-server-core && \
    # Immediatly stop the server
    plasticsd stop && \
    # Clean up temporary files
    rm -rf /var/log/* && \
    rm -rf /var/lib/apt/lists/*

# TCP port
EXPOSE 8087
# SSL port
EXPOSE 8088

VOLUME /conf
VOLUME /db/sqlite
VOLUME /logs

COPY run.sh /run.sh
