# Deployment Guide

Project-specific deployment procedures. Agents read this via `{standards.deployment}`.

> Universal patterns (CI/CD pipeline stages, Docker best practices, secret management) are embedded in the `devops` agent.
> This file documents **this project's specific** deployment setup.

## Environments

`roxabi-idna` is **local-only**. There is no hosted deployment, no Vercel project, no Cloudflare Pages, no Docker image. Every "environment" is a machine where the service runs on demand.

| Environment | Host | Purpose |
|---|---|---|
| **Dev** | `roxabitower` (Pop!_OS, RTX 5070 Ti) | Running interactive sessions while picking candidates |
| **Prod** | `roxabituwer` (Ubuntu Server, RTX 3080) | On-demand; start manually when an idna session is needed |

Both hosts clone this repo to `~/projects/roxabi-idna`.

## Running the Service

```bash
uv run idna_server.py    # start picker on http://localhost:8082/
```

Stop with `Ctrl-C`. The process is stateless — session data persists in `$IDNA_DATA` across restarts.

## Deploy Process

No deploy pipeline. To update a host:

```bash
# on the target host
cd ~/projects/roxabi-idna
git fetch origin
git checkout staging
git pull --ff-only
uv sync                          # refresh dev + runtime deps
```

Then start the service as above when needed.

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

## Monitoring & Health Checks

- **Logs** — `idna_server.py` writes to stdout; redirect as needed (`uv run idna_server.py >> ~/idna.log 2>&1 &`).
- **Health** — no HTTP health endpoint. Liveness = port `8082` accepting connections. A quick check:
  ```bash
  curl -fsS http://localhost:8082/ >/dev/null && echo up || echo down
  ```
- **Session inventory** — `make ls` lists session dirs under `$IDNA_DATA`.

## Rollback

Because deploys are `git pull`, rollback is `git checkout <prev-sha>` followed by restarting the service. Session data is untouched (lives in `$IDNA_DATA`, not the repo).
