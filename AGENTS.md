# Repository instructions

## Project overview

This repository builds `ghcr.io/jasmeralia/browser-rdp`, a containerized Ubuntu desktop for RDP access. The image runs XFCE through XRDP and supervisord, and includes Firefox, Google Chrome, LastPass, and uBlock Origin. `Dockerfile` defines the image; `entrypoint.sh` creates/configures the login user and prepares the mounted home directory; `supervisord.conf` runs the XRDP services. Browser policy and performance settings live in `mozilla.cfg`, `autoconfig.js`, and the Chrome policy in the Dockerfile. XFCE seed settings live under `xfce4-defaults/`.

## Keep project documentation accurate

- The base OS version is set by `FROM` in `Dockerfile`; keep the README description aligned with it.
- The home directory is expected to be mounted for profile persistence. Startup creates missing expected paths and XFCE defaults, preserves existing settings, and adjusts ownership on the home directory and selected profile paths. Do not describe the existing mount as completely untouched.
- `PASSWORD_FILE` takes precedence over `PASSWORD`. Keep the entrypoint behavior and README usage notes aligned if credential handling changes.
- Document user-facing changes to environment variables, ports, mounts, browser policies, or startup behavior in `README.md` as part of the same change.

## Change guidance

- Keep browser and desktop configuration in the existing system-policy/default files where practical. Firefox autoconfig is system-wide and must not depend on a user's persisted profile contents.
- The home mount can contain large, valuable browser profiles and downloads. Avoid recursive ownership changes, deletes, resets, or migrations unless they are necessary and explicitly understood; preserve the entrypoint's non-recursive treatment of the home root.
- Do not put real credentials in tracked files. The compose file is an example and its `PASSWORD` value is a placeholder; deployments should supply a real secret through `PASSWORD_FILE` or an appropriately protected environment.
- Make Dockerfile, shell, and YAML changes consistent with the CI checks described below. Preserve the existing service name, image naming placeholders, and health check unless intentionally changing the published compose interface.

## Build and CI

The GitHub Actions workflow `.github/workflows/publish.yml` runs Hadolint on `Dockerfile` and Yamllint on `docker-compose.yml` for pull requests. For changes to those files, the equivalent checks are:

```sh
hadolint Dockerfile
yamllint docker-compose.yml
```

The workflow builds and publishes the image to GHCR on pushes to `master` and version tags. On `master`, CI creates the next patch version tag itself. Never create or push release tags manually; see the repository-wide Git instructions for branch and PR workflow.

There is no separate application test suite configured in this repository. Use the checks relevant to the files changed and the build/pull request workflow when verification is requested.
