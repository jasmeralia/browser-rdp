#!/usr/bin/env bash
set -euo pipefail

: "${USER_NAME:=user}"
: "${USER_ID:=1000}"
: "${GROUP_ID:=1000}"
: "${PASSWORD:?ERROR: PASSWORD env var must be set}"

# Create group/user if missing
if ! getent group "${USER_NAME}" >/dev/null 2>&1; then
  groupadd -g "${GROUP_ID}" "${USER_NAME}"
fi

if ! id -u "${USER_NAME}" >/dev/null 2>&1; then
  useradd -m -u "${USER_ID}" -g "${GROUP_ID}" -s /bin/bash "${USER_NAME}"
  usermod -aG sudo "${USER_NAME}" || true
fi

HOME_DIR="$(getent passwd "${USER_NAME}" | cut -d: -f6)"

# Ensure expected directories exist (safe on both fresh and existing mounts)
mkdir -p "${HOME_DIR}/Downloads" \
         "${HOME_DIR}/.mozilla" \
         "${HOME_DIR}/.config/google-chrome"

# Default XFCE session
if [ ! -f "${HOME_DIR}/.xsession" ]; then
  echo "startxfce4" > "${HOME_DIR}/.xsession"
fi

# Seed XFCE defaults only on first run (empty home mount)
XFCE_CONF="${HOME_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml"
if [ ! -d "${XFCE_CONF}" ]; then
  mkdir -p "${XFCE_CONF}"
  cp /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/*.xml "${XFCE_CONF}/"
fi

# Fix ownership on home dir and key subdirs (not recursive — fast on large mounts)
chown "${USER_NAME}:${USER_NAME}" "${HOME_DIR}"
chown -R "${USER_NAME}:${USER_NAME}" \
  "${HOME_DIR}/Downloads" \
  "${HOME_DIR}/.mozilla" \
  "${HOME_DIR}/.config" \
  "${HOME_DIR}/.xsession"

# Set password for XRDP login
echo "${USER_NAME}:${PASSWORD}" | chpasswd

exec "$@"
