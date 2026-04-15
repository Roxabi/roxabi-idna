# Configuration

How the project is configured. Agents read this via `{standards.configuration}`.

## Environment Variables

| Variable | Required | Default | Description |
|---|:---:|---|---|
| `IDNA_DIR` | No | repo root (inferred from `idna/config.py` path) | Code root. Used by supervisord conf + setup scripts to locate `idna_server.py`, `templates/`, `types/`. |
| `IDNA_DATA` | No | `~/.roxabi/idna` | Runtime session root. Every session lives at `$IDNA_DATA/<project>/<subject>/`. Must differ from `$IDNA_DIR`. |
| `ENABLE_LSP_TOOL` | No | `1` (via `.env`) | Dev-only. Turns on the Claude Code LSP plugin (`pyright-lsp`) for richer intelligence. |
| `SUPERVISOR_HUB` | No | `$HOME/projects` | Used by the `Makefile` to locate `hub.mk` (shared supervisor targets). |

**Never place `IDNA_DATA` under `~/.roxabi/forge/`** — forge deploys to Cloudflare Pages, idna sessions are local-only and often large (dozens of PNGs per session).

## Config Files

| File | Purpose | Committed? |
|---|---|:---:|
| `.claude/stack.yml` | Dev-core stack declaration (runtime, commands, formatter, test runner) | Yes |
| `.claude/stack.yml.example` | Reference template | Yes |
| `.claude/dev-core.yml` | Dev-core runtime (GitHub project ID, field IDs, Vercel IDs) | No (gitignored) |
| `.env` | Local env vars (`ENABLE_LSP_TOOL`, dev-core secrets) | No (gitignored) |
| `.env.example` | Env template for fresh clones | Yes |
| `pyproject.toml` | Python project, deps, `[tool.pyright]` excludes, `[tool.ruff.lint]` ignores | Yes |
| `uv.lock` | Locked dep versions | Yes |
| `.pre-commit-config.yaml` | Ruff, pyright, trufflehog on commit; license check on push | Yes |
| `.license-policy.json` | pip-licenses allowlist + compound-license overrides | Yes |
| `release-please-config.json` + `.release-please-manifest.json` | Automated versioning (Python) | Yes |
| `.github/workflows/*.yml` | CI, auto-merge, pr-title | Yes |
| `.github/dependabot.yml` | Weekly pip + github-actions updates | Yes |
| `types/*.toml` | Per-template vocabulary (axes, poles, priorities) | Yes |
| `Makefile` | Supervisor dispatch (`make idna start`, …) + `ls` / `clean` helpers | Yes |

## Priority Chain

Runtime values are resolved in this order (highest wins):

1. **Environment variable** (e.g. `IDNA_DATA=/tmp/sessions uv run python idna_server.py`)
2. **`idna/config.py` default** (`Path.home() / ".roxabi" / "idna"` for `IDNA_DATA`)

There is no `.env` auto-load inside `idna/config.py` — supervisord sets env explicitly in the program `environment=` line.

Dev-core config resolves via its own 3-tier chain (`.claude/dev-core.yml` → `process.env` → `gh` CLI); see `dev-core` plugin docs. `.env` in this repo exists only for `ENABLE_LSP_TOOL` and GitHub Project IDs used by the roxabi dashboard CLI.
