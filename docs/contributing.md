# Contributing

How to contribute to `roxabi-idna`.

## Getting Started

```bash
git clone https://github.com/Roxabi/roxabi-idna.git
cd roxabi-idna
uv sync                          # install runtime + dev deps
cp .env.example .env             # ENABLE_LSP_TOOL + dev-core vars
uv run pre-commit install        # commit hooks (ruff, pyright, trufflehog)
uv run pre-commit install --hook-type pre-push    # license check on push
```

Optional but useful:

- **imageCLI checkout** — image templates (`avatar`, `logo`, `icon_set`) talk to the imageCLI daemon over a Unix socket. Without it, you can still develop/test html/text templates (`color_palette`, `motion_curve`, `voice`, `ui_component`) end-to-end.
- **Supervisor hub** — clone `roxabi-plugins` next to this repo so `make idna start` can dispatch through `~/projects/hub.mk`.

Smoke test:

```bash
uv run pytest                    # (no tests yet — no output is fine)
uv run ruff check                # must be clean
uv run pyright                   # must be clean
```

## Development Workflow

1. **Pick or create an issue** on the `Roxabi/roxabi-idna` project board.
2. Run `/dev #N` in Claude Code — it auto-detects tier (S / F-lite / F-full) and delegates to the right phase skills. State is tracked in `artifacts/`.
3. Work happens in a **git worktree**:
   ```bash
   git worktree add ../roxabi-idna-<N>  -b feat/<N>-<slug>  staging
   cd ../roxabi-idna-<N>
   ```
4. Commits must pass the pre-commit hook (ruff, pyright, trufflehog). No `--no-verify`.
5. Open a PR **against `staging`** (not `main`). PR title must be Conventional Commits (`pr-title.yml` blocks otherwise).
6. Once CI is green and self-review is done, add the `reviewed` label — auto-merge takes it from there.
7. Promotion to `main` happens in a separate staging→main PR; see [docs/processes/dev-process.md](processes/dev-process.md#release-process).
8. When the worktree is done: `cd .. && git worktree remove roxabi-idna-<N>`.

## Commit Conventions

Commits follow Conventional Commits: `<type>(<scope>): <description>`.

Types: `feat` | `fix` | `refactor` | `docs` | `style` | `test` | `chore` | `ci` | `perf`

Scope is optional but useful — common ones here: `server`, `api`, `nodes`, `session`, `pbo`, `templates`, `docs`, `ci`, `deps`.

When Claude contributes, the commit ends with:

```
Co-Authored-By: Claude <model-id> <noreply@anthropic.com>
```

## Documentation

- **Docs live in `docs/`** — Markdown (`.md`), not MDX. No doc site; agents + contributors read the files directly.
- **Two top-level docs at `docs/`** — `operations.md` (runbook) and `session-schema.md` (runtime data shape). These stay at the top of `docs/` (not nested) because they're project-specific references the whole team hits often.
- **Standards / architecture / guides / processes** — under `docs/standards/`, `docs/architecture/`, `docs/guides/`, `docs/processes/`. Paths are wired into `.claude/stack.yml` so dev-core agents can find them.
- **Update with code** — touching `idna/session.py` schema → update `docs/session-schema.md`. Adding a new handler → update `docs/architecture/patterns.md` (Data Flow section) and `docs/standards/backend-patterns.md` (API conventions).
- **Visual explainers / brand galleries** — live outside this repo in `~/.roxabi/forge/idna/`, generated and maintained via the `forge` skill. The repo only holds diagrams that make sense inline (ASCII boxes in `architecture/index.md`).
- **ADRs** — drop a numbered markdown file in `docs/architecture/adr/` when making a non-trivial architectural decision; the `dev-core:adr` skill scaffolds the template.

## Things we don't do

- No frameworks on the frontend (keep `idna/html_*.py` vanilla).
- No ORMs / databases (flat JSON + files on disk).
- No direct heavy-ML imports in this repo (route through `idna/daemon.py`).
- No write access to `$IDNA_DIR` from runtime code (always `$IDNA_DATA`).
- No pushes to `main` that bypass the PR + `ci` gate (admin bypass during `/init` setup was a one-off).

See [docs/standards/code-review.md](standards/code-review.md) for the full review checklist.
