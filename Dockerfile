# Dockerfile: Ubuntu 24.04 + XFCE + XRDP + Firefox/Chrome + LastPass + uBlock Origin
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Base desktop + xrdp + supervisor + helpers
# hadolint ignore=DL3008,DL4006
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates apt-transport-https gnupg curl wget software-properties-common \
    dbus-x11 x11-xserver-utils \
    xfce4 xfce4-goodies xfce4-terminal \
    xrdp xorgxrdp \
    supervisor sudo netcat-openbsd \
  && rm -rf /var/lib/apt/lists/*

# Update all packages
# hadolint ignore=DL3005
RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y \
  && rm -rf /var/lib/apt/lists/*

# Install Firefox as a deb (avoid snap in containers)
# hadolint ignore=DL3008,DL4006
RUN add-apt-repository -y ppa:mozillateam/ppa \
  && printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501\n' \
     > /etc/apt/preferences.d/mozillateamppa \
  && apt-get update && apt-get install -y --no-install-recommends firefox \
  && rm -rf /var/lib/apt/lists/*

# --- Google Chrome (stable) ---
# hadolint ignore=DL3008,DL4006
RUN install -d /usr/share/keyrings && \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-linux.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y --no-install-recommends google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Create Chrome desktop shortcut with sandbox, GPU, and performance flags
# hadolint ignore=SC2015
RUN install -d /usr/share/applications && \
    sed 's|Exec=/usr/bin/google-chrome-stable|Exec=/usr/bin/google-chrome-stable --no-sandbox --disable-gpu --disable-smooth-scrolling --disable-gpu-compositing --autoplay-policy=user-gesture-required|g' \
      /usr/share/applications/google-chrome.desktop > /usr/share/applications/google-chrome-nosandbox.desktop || true

# --- Firefox autoconfig: system-wide performance defaults ---
COPY autoconfig.js /usr/lib/firefox/defaults/pref/autoconfig.js
COPY mozilla.cfg /usr/lib/firefox/mozilla.cfg

# --- XFCE desktop defaults: no compositor, Adwaita theme ---
COPY xfce4-defaults/ /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/

# Default to XFCE for xrdp sessions for any new user
RUN echo "startxfce4" > /etc/skel/.xsession

# XRDP tweaks: enable caching, compression, fastpath, and limit colour depth
# hadolint ignore=DL3059
RUN install -d -m 0755 /var/run/xrdp && \
    sed -i \
      -e 's/^bitmap_cache=.*/bitmap_cache=yes/' \
      -e 's/^bitmap_compression=.*/bitmap_compression=yes/' \
      -e 's/^bulk_compression=.*/bulk_compression=yes/' \
      -e 's/^use_fastpath=.*/use_fastpath=both/' \
      -e 's/^max_bpp=.*/max_bpp=16/' \
      /etc/xrdp/xrdp.ini

# Ensure /dev/shm exists and is writable for Chromium browsers
RUN mkdir -p /dev/shm && chmod 1777 /dev/shm

# --- Preconfigure LastPass + uBlock Origin for all supported browsers ---
# Chrome: force-install via enterprise policy (Chrome Web Store)
# LastPass: hdokiejnpimakedhajhdlcegeplioahd
# uBlock Origin: cjpalhdlnbpafiamejdnhcphjbkeiagm
RUN mkdir -p /etc/opt/chrome/policies/managed && \
    printf '%s\n' \
    '{' \
    '  "ExtensionInstallForcelist": [' \
    '    "hdokiejnpimakedhajhdlcegeplioahd;https://clients2.google.com/service/update2/crx",' \
    '    "cjpalhdlnbpafiamejdnhcphjbkeiagm;https://clients2.google.com/service/update2/crx"' \
    '  ]' \
    '}' > /etc/opt/chrome/policies/managed/extensions.json

# Firefox: install extensions via enterprise policies from AMO
RUN mkdir -p /usr/lib/firefox/distribution && \
    printf '%s\n' \
    '{' \
    '  "policies": {' \
    '    "Extensions": {' \
    '      "Install": [' \
    '        "https://addons.mozilla.org/firefox/downloads/latest/lastpass-password-manager/latest.xpi",' \
    '        "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"' \
    '      ]' \
    '    }' \
    '  }' \
    '}' > /usr/lib/firefox/distribution/policies.json

# Supervisord config (runs xrdp-sesman and xrdp)
RUN mkdir -p /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/xrdp.conf

# Entrypoint: make user on first run and set password from env
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3389
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
