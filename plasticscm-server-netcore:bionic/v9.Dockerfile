# This installs plasticscm-server-netcore manually and not through the package manager.
# This allows us to run 'plasticd' manually and not through systemd as this is not available inside Docker.

# Ubunut 18.04 LTS
FROM ubuntu:bionic
LABEL maintainer="linard.hug@haw-hamburg.de"

ARG DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# Update package list and install required tools
RUN apt-get update && apt-get install -y wget gnupg2 vim apt-transport-https \
    # Install all dependecies
    libc6 libgcc1 libgssapi-krb5-2 libstdc++6 zlib1g sudo liblttng-ust0 libssl1.1 libkrb5-3 libicu60 && \
    # Clean up temporary files
    rm -rf /var/log/* && \
    rm -rf /var/lib/apt/lists/*

ARG VERSION

    # Register the plastic scm repositiory
RUN wget -qO - "https://www.plasticscm.com/plasticrepo/stable/ubuntu/Release.key" | apt-key add - && \
    echo "deb https://www.plasticscm.com/plasticrepo/stable/ubuntu/ ./" > /etc/apt/sources.list.d/plasticscm-stable.list && \
    # Install plastic scm server manually
    wget -qO "/plasticscm.tar.gz" "https://s3.eu-west-2.amazonaws.com/plastic-releases/releases/$VERSION/plasticscm/linux/PlasticSCM-$VERSION-linux-x64-server-netcore.tar.gz" && \
    mkdir -p "/opt/plasticscm5/" && \
    tar -xf "/plasticscm.tar.gz" -C "/opt/plasticscm5/" && \
    chmod u+x "/opt/plasticscm5/server/plasticd" && \
    # Clean up temporary files
    rm "/plasticscm.tar.gz" && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/apt/lists/*

# TCP port
EXPOSE 8087
# SSL port
EXPOSE 8088
# Webadmin TCP port (localhost only)
EXPOSE 7178
# Webadmin SSL port
EXPOSE 7179

VOLUME /db/jet
VOLUME /logs
# Contains the configurations that will be linked to the server through plastic.sh
VOLUME /conf

COPY "./jet.conf" "/opt/plasticscm5/server/jet.conf"

COPY "./plastic.sh" "/plastic.sh"
ENTRYPOINT [ "/plastic.sh" ]
