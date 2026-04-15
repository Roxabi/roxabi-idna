# Troubleshooting Guide

Common issues and their solutions. Agents read this via `{standards.troubleshooting}`.

## Server won't start / pick UI unreachable

| Symptom | Cause | Fix |
|---|---|---|
| `Address already in use :8082` | Previous `idna_server.py` still running | `make idna stop`, check `supervisorctl status idna-*`; last resort `lsof -ti:8082 \| xargs kill` |
| `ModuleNotFoundError: idna` | Running with wrong venv | Use `uv run python idna_server.py` from repo root (not system `python`) |
| `Error: idna not initialized at ...` (make idna start) | `idna_server.py` missing at `$IDNA_DIR` | Check the Makefile-inferred `IDNA_DIR` matches a real checkout |
| `make idna logs` shows `Connection refused` (daemon) | imageCLI daemon not running | Start imageCLI daemon on the same host; `ls -l ~/.local/share/imagecli/daemon.sock` should show a socket |
| Browser hits the server but nodes never generate | Worker silently crashed | Tail `make idna errlogs`; common cause is missing `.pt` embeds → run `idna_encode_all.py <session_dir>` by hand |
| Picker loads but images 404 | Round generated under wrong path | `session.json` and `$IDNA_DATA` paths must match; verify `IDNA_DATA` env in supervisord conf |

## Pre-commit / CI failures

| Symptom | Cause | Fix |
|---|---|---|
| `pyright: Import "torch" could not be resolved` | Touched `idna_encode_all.py` / `idna_generate_round.py` — they're meant for imageCLI's venv | Leave the imports; `[tool.pyright].exclude` already excludes those files. If pyright is still checking them, re-run after `rm -rf .pyright/` |
| `pyright: Import "X" could not be resolved` on a **new** file | Heavy ML dep added to this repo | Route through `idna/daemon.py` instead. If genuinely needed here, add to `[project.dependencies]` |
| Pre-commit hook blocks commit | Real ruff/pyright error | Fix + **new** commit (never `--no-verify`); see `CLAUDE.md` Git rules |
| `license check` fails on first push | New dep with non-allowlisted license string | Re-run `uv run tools/license_check.py`, add the package to `.license-policy.json` `overrides` (or add the license to `allowedLicenses`) |
| CI passes lint/typecheck but fails on `ci` gate | Branch protection expects the exact check name `ci` | Confirm the job named `ci` exists in `.github/workflows/ci.yml` and didn't get renamed |
| `gh: Upgrade to GitHub Pro` when editing ruleset | Repo was flipped back to private | Make repo public, or buy a paid plan for the `Roxabi` org |

## Session / tree issues

| Symptom | Cause | Fix |
|---|---|---|
| `session.json missing 'vocabulary'` (build_tree) | Setup didn't run | `uv run python idna_setup.py <project> <subject> <template>` first |
| `vocabulary needs N poles, got M` | Type config has fewer poles than `width` | Add poles to `types/<template>.toml` or drop `width` in setup |
| Tree depth explodes GPU memory | High `depth` + image template | Use `depth=2` or `depth=3` for image templates; higher depths fine for html/text |
| Same prompt, different image on each reroll | Seed derived from `node_seed(node_id)` is intentional for exploration | If reproducibility is wanted, also pin `round` via `reroll?seed=<int>` |
| Nodes stuck at `status=pending` | `.pt` embed missing and encoder didn't run | `idna_encode_all.py <session_dir>`; worker does it per-round otherwise |
| `_blend_pole_embeds: missing pole embed poles/N.pt` | Pole encodes weren't produced during setup | Re-run `idna_setup.py` with `--encode-poles` (or equivalent setup flag), or encode manually via daemon |

## Supervisor / systemd

| Symptom | Cause | Fix |
|---|---|---|
| `make idna start` does nothing | Service pattern needs `<project>-<subject>` but args passed differently | Check `plugins/idna/supervisor/conf.d/idna.conf`; the program name is `idna-<project>-<subject>` |
| Supervisor auto-starts on `roxabitower` (dev) | Shouldn't on dev | Confirm `lyra.service` is **not** enabled on dev: `systemctl --user status lyra.service` |
| Logs don't rotate | supervisord default logs only rotate at restart | `supervisorctl restart idna-<project>-<subject>` when logs get large |
| Prod box reboot loses picker state | `$IDNA_DATA` must be on the boot volume (it is by default at `~/.roxabi/idna`) | Check mount points if host was re-imaged |

## Development environment

| Symptom | Cause | Fix |
|---|---|---|
| `uv sync` fails with "lockfile conflict" | Pulled a branch with a conflicting `uv.lock` | `rm uv.lock && uv lock` then review the diff |
| `pyright` shows errors the pre-commit doesn't | Different pyright version locally vs in CI | `uv run pyright --version`; commit matches `pyright>=1.1.408` in `pyproject.toml` |
| LSP plugin silent | `ENABLE_LSP_TOOL` missing in `.env` | `echo 'ENABLE_LSP_TOOL=1' >> .env` and restart Claude Code session |
| `roxabi` CLI not found | `~/.local/bin` not in PATH | `export PATH="$HOME/.local/bin:$PATH"` in `~/.bashrc` (shim was created by `/init`) |
