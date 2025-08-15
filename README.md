# Browser RDP Desktop

A containerized Ubuntu 24.04 desktop with XFCE, XRDP, and preinstalled browsers (Firefox, Chrome, Opera) plus LastPass extension, ready for remote access.

## Features

- **Desktop:** XFCE4 with terminal and goodies
- **Remote Access:** XRDP server (port 3389)
- **Browsers:** Firefox (deb), Google Chrome, Opera (latest stable)
- **Password Manager:** LastPass extension preinstalled for all browsers
- **Persistence:** Host-mounted volumes for browser profiles and Downloads
- **User Setup:** Customizable user, group, and password via environment variables
- **Supervision:** Managed by supervisord for reliability

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
- [`.github/workflows/publish.yml`](.github/workflows/publish.yml): CI for building and publishing the image to GHCR.

## License

MIT License © 2025 Morgan Blackthorne