# Deployment Guide

Project-specific deployment procedures. Agents read this via `{standards.deployment}`.

> Universal patterns (CI/CD pipeline stages, Docker best practices, secret management) are embedded in the `devops` agent.
> This file documents **this project's specific** deployment setup.

## Environments

`roxabi-idna` is **local-only**. There is no hosted deployment, no Vercel project, no Cloudflare Pages, no Docker image. Every "environment" is a machine where the supervisor runs.

| Environment | Host | Purpose |
|---|---|---|
| **Dev** | `roxabitower` (Pop!_OS, RTX 5070 Ti) | Running interactive sessions while picking candidates |
| **Prod** | `roxabituwer` (Ubuntu Server, RTX 3080) | Always-on; supervisord + lyra.service auto-start |

Both hosts clone this repo to `~/projects/roxabi-idna` and use the supervisor hub in `~/projects/` (`make idna …`).

## Deploy Process

No deploy pipeline. To update a host:

```bash
# on the target host
cd ~/projects/roxabi-idna
git fetch origin
git checkout main
git pull --ff-only
uv sync                          # refresh dev + runtime deps
make idna reload                 # restart supervised program if running
```

Production runs under `lyra.service` (systemd user unit with linger) which owns the shared `supervisord`. Program configs live in `~/projects/roxabi-plugins/plugins/idna/supervisor/conf.d/idna.conf` and are auto-loaded by `start.sh --all`. Changes to the supervisor conf require a separate PR in `roxabi-plugins`.

## Promotion

Changes flow: feature branch → `staging` (PR) → `main` (PR). Branch protection on both `main` and `staging` requires the `ci` check; `PR_Main` ruleset allows `squash|rebase|merge` so the staging→main promotion can use a merge commit when helpful. Auto-merge is enabled — land PRs by adding the `reviewed` label once CI is green.

Release Please (`release-please-config.json`) watches `main` and opens a release PR when conventional commits accumulate (no workflow wired yet — see `docs/guides/troubleshooting.md`).

## Environment Variables

See [Configuration](../standards/configuration.md) for the full env-var table. Per-host overrides:

| Variable | Dev (`roxabitower`) | Prod (`roxabituwer`) |
|---|---|---|
| `IDNA_DIR` | `~/projects/roxabi-idna` | `~/projects/roxabi-idna` |
| `IDNA_DATA` | `~/.roxabi/idna` | `~/.roxabi/idna` |
| `HOME` | `/home/mickael` | `/home/mickael` |
| `PATH` | includes `~/.local/bin` (for `uv`, `roxabi`, `trufflehog`) | same |

Set in supervisord program conf via `environment=HOME="%(ENV_HOME)s",PATH="%(ENV_HOME)s/.local/bin:%(ENV_PATH)s"`. Never hard-code host-specific paths.

## Monitoring & Health Checks

- **Logs** — `make idna logs` (stdout) / `make idna errlogs` (stderr). Backed by supervisord's `stdout_logfile`.
- **Health** — no HTTP health endpoint. Liveness = port `8082` accepting connections. A quick check:
  ```bash
  curl -fsS http://localhost:8082/ >/dev/null && echo up || echo down
  ```
- **Session inventory** — `make idna ls` lists session dirs under `$IDNA_DATA`.
- **Uptime** — systemd via `lyra.service`; `Restart=on-failure` at the supervisord level, `autorestart=true` per program.
- **GPU use** — this repo never uses the GPU directly. Generation load shows up under the imageCLI daemon's process.

## Rollback

Because deploys are `git pull` + `make idna reload`, rollback is `git checkout <prev-sha> && make idna reload`. Session data is untouched (lives in `$IDNA_DATA`, not the repo).
