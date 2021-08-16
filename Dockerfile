# Flaresolverr, OpenVPN and WireGuard, FlaresolverrVPN
FROM amd64/debian:sid-slim

ENV DEBIAN_FRONTEND noninteractive
ENV XDG_DATA_HOME="/config" \
XDG_CONFIG_HOME="/config"

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /blackhole /config/flaresolverr /etc/flaresolverr

RUN apt update

# Download Flaresolverr
RUN apt update \
    && apt upgrade -y \
    && apt-get install -y gconf-service libasound2 libatk1.0-0 libcairo2 libcups2 libfontconfig1 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libxss1 fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils chromium \
    && apt-get install unzip \
    && apt install -y  --no-install-recommends \
    ca-certificates \
    curl \
    && FLARESOLVERR_VERSION=$(curl -sX GET "https://api.github.com/repos/FlareSolverr/FlareSolverr/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -o /opt/flaresolverr-${FLARESOLVERR_VERSION}-linux-x64.zip -L "https://github.com/FlareSolverr/FlareSolverr/releases/download/${FLARESOLVERR_VERSION}/flaresolverr-${FLARESOLVERR_VERSION}-linux-x64.zip" \
    && unzip /opt/flaresolverr-${FLARESOLVERR_VERSION}-linux-x64.zip -d /opt \
    && rm -f /opt/flaresolverr-${FLARESOLVERR_VERSION}-linux-x64.zip \ 
    && apt purge -y \
    ca-certificates \
    curl \
    && apt-get clean \
    && apt autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Install WireGuard and other dependencies some of the scripts in the container rely on.
RUN echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list \
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable \
    && apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    dos2unix \
    inetutils-ping \
    ipcalc \
    iptables \
    jq \
    kmod \
    libicu63 \
    moreutils \
    net-tools \
    openresolv \
    openvpn \
    procps \
    wireguard-tools \
    && apt-get clean \
    && apt autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

RUN update-alternatives --set iptables /usr/sbin/iptables-legacy

VOLUME /blackhole /config

ADD openvpn/ /etc/openvpn/
ADD flaresolverr/ /etc/flaresolverr/

RUN chmod +x /etc/flaresolverr/*.sh /etc/openvpn/*.sh /opt/flaresolverr/flaresolverr

EXPOSE 8191

CMD ["/bin/bash", "/etc/openvpn/start.sh"]