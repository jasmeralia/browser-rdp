# Browser RDP Desktop

A containerized Ubuntu 24.04 desktop with XFCE, XRDP, and preinstalled browsers (Firefox, Chrome) plus LastPass and uBlock Origin extensions, optimized for responsive remote access.

## Features

- **Desktop:** XFCE4 with terminal and goodies
- **Remote Access:** XRDP server (port 3389)
- **Browsers:** Firefox (deb), Google Chrome (latest stable)
- **Extensions:** LastPass and uBlock Origin preinstalled for both browsers
- **Persistence:** Single home-directory mount preserves all profiles and settings
- **User Setup:** Customizable user, group, and password via environment variables
- **Supervision:** Managed by supervisord for reliability

## Performance Optimizations

The image ships with several optimizations baked in, so the RDP session stays responsive when browsing content-heavy sites:

| Layer | What's tuned | Effect |
|---|---|---|
| **XRDP** | bitmap cache/compression, bulk compression, fastpath, 16-bit colour | Less data over the wire, lower latency |
| **XFCE** | Compositor off, vblank off, Adwaita theme | No transparency/shadow rendering overhead |
| **Firefox** | Autoplay blocked, GIF animation off, WebRender off, frame rate capped at 15 fps, smooth scroll off, AV1/VP9 disabled | Dramatically less CPU/GPU work per page |
| **Chrome** | `--disable-smooth-scrolling --disable-gpu-compositing --autoplay-policy=user-gesture-required` | Same idea, Chromium side |
| **uBlock Origin** | Force-installed in both browsers | Blocks ads, trackers, and heavy third-party scripts |

Firefox settings are applied via system-level autoconfig (`/usr/lib/firefox/mozilla.cfg`) so they work regardless of which profile is active and never conflict with mount contents.

## Profile Preservation

The compose file mounts a single host directory as the entire home directory:

```yaml
volumes:
  - /path/to/home:/home/${USER_NAME}
```

On container start the entrypoint uses "create only if missing" logic:

- **Fresh (empty) mount:** Creates `Downloads`, `.mozilla`, `.config/google-chrome`, `.xsession`, and seeds XFCE defaults (compositor off, etc.)
- **Existing mount:** All directories and configs are left untouched — nothing is overwritten

To reset XFCE defaults after customizing, delete the xfconf directory and restart the container:
```sh
rm -rf /path/to/home/.config/xfce4/xfconf
docker restart browser-rdp
```

### Migrating from per-subdirectory mounts

If you previously mounted individual directories (`Downloads`, `.mozilla`, `.config/google-chrome`), move their contents into a single home directory:

```sh
mkdir -p /path/to/home/.config
mv /old/Downloads   /path/to/home/Downloads
mv /old/mozilla     /path/to/home/.mozilla
mv /old/google-chrome /path/to/home/.config/google-chrome
```

Then update your `docker-compose.yml` to use the single mount.

## Usage

1. **Build and run with Docker Compose:**
   ```sh
   docker-compose up -d
   ```
2. **Connect via RDP:** Use any RDP client to connect to `localhost:3389`.
3. **Credentials:** Set `PASSWORD`, `USER_NAME`, `USER_ID`, and `GROUP_ID` in `docker-compose.yml`.

## File Overview

- [`Dockerfile`](Dockerfile): Builds the desktop environment and installs browsers/extensions.
- [`entrypoint.sh`](entrypoint.sh): Creates user/group, sets password, prepares home directories.
- [`supervisord.conf`](supervisord.conf): Runs XRDP services under supervision.
- [`docker-compose.yml`](docker-compose.yml): Defines service, environment, volumes, and healthcheck.
- [`mozilla.cfg`](mozilla.cfg): Firefox system-wide performance defaults.
- [`autoconfig.js`](autoconfig.js): Firefox autoconfig loader.
- [`xfce4-defaults/`](xfce4-defaults/): XFCE window manager and appearance defaults.
- [`.github/workflows/publish.yml`](.github/workflows/publish.yml): CI for building and publishing the image to GHCR.

## License

MIT License © 2025 Morgan Blackthorne
