# ./Dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Base desktop + xrdp + supervisor + helpers
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates apt-transport-https gnupg software-properties-common \
    dbus-x11 x11-xserver-utils \
    xfce4 xfce4-goodies xfce4-terminal \
    xrdp xorgxrdp \
    supervisor sudo netcat-openbsd \
  && rm -rf /var/lib/apt/lists/*

# Install Firefox as a deb (avoid snap in containers)
RUN add-apt-repository -y ppa:mozillateam/ppa \
  && printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501\n' \
     > /etc/apt/preferences.d/mozillateamppa \
  && apt-get update && apt-get install -y --no-install-recommends firefox \
  && rm -rf /var/lib/apt/lists/*

# Default to XFCE for xrdp sessions for any new user
RUN echo "startxfce4" > /etc/skel/.xsession

# XRDP tweaks: listen on 3389 (default). Create run dir to avoid boot warnings.
RUN install -d -m 0755 /var/run/xrdp

# Supervisord config (runs xrdp-sesman and xrdp)
RUN mkdir -p /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/xrdp.conf

# Entrypoint: make user on first run and set password from env
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3389
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
