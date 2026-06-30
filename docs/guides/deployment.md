# Deployment Guide

Project-specific deployment procedures. Agents read this via `{standards.deployment}`.

> Universal patterns (CI/CD pipeline stages, Docker best practices, secret management) are embedded in the `devops` agent.
> This file documents **this project's specific** deployment setup.

## Environments

`roxabi-idna` is **local-only**. There is no hosted deployment, no Vercel project, no Cloudflare Pages, no Docker image. Every "environment" is a machine where the picker runs.

| Environment | Host | Purpose |
|---|---|---|
| **Dev** | `roxabitower` (Pop!_OS, RTX 5070 Ti) | Running interactive sessions while picking candidates |
| **Prod** | `roxabituwer` (Ubuntu Server, RTX 3080) | Always-on picker when needed |

Both hosts clone this repo to `~/projects/roxabi-idna` and run the picker via `make run` (foreground).

## Deploy Process

No deploy pipeline. To update a host:

```bash
# on the target host
cd ~/projects/roxabi-idna
git fetch origin
git checkout main
git pull --ff-only
uv sync                          # refresh dev + runtime deps
make run                         # restart = stop (Ctrl+C) then make run again
```

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

Never hard-code host-specific paths.

## Monitoring & Health Checks

- **Logs** — stdout/stderr of the foreground `make run` process.
- **Health** — no HTTP health endpoint. Liveness = port `8082` accepting connections. A quick check:
  ```bash
  curl -fsS http://localhost:8082/ >/dev/null && echo up || echo down
  ```
- **Session inventory** — `make ls` lists session dirs under `$IDNA_DATA`.
- **Uptime** — manual; no auto-restart (on-demand tool).
- **GPU use** — this repo never uses the GPU directly. Generation load shows up under the imageCLI `imagecli-gen` Quadlet worker.

## Rollback

Because deploys are `git pull` + restart `make run`, rollback is `git checkout <prev-sha>` then `make run` again. Session data is untouched (lives in `$IDNA_DATA`, not the repo).