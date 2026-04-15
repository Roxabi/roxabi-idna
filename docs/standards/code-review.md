# Code Review Standards

Project-specific review guidelines. Agents read this via `{standards.code_review}`.

> Universal patterns (security checklist, severity definitions) are embedded in the `security-auditor` agent.
> This file documents **this project's specific** review criteria.

## Review Checklist

- [ ] Code follows project patterns (see [backend-patterns](backend-patterns.md))
- [ ] Tests added/updated for all changed behaviour (see [testing](testing.md))
- [ ] `uv run ruff check` + `uv run pyright` clean — no new `# noqa` / `# type: ignore` without a one-line reason
- [ ] No `torch` / `diffusers` / `optimum.quanto` / `PIL` imports added to this repo (route through `idna/daemon.py` instead)
- [ ] No session data reads/writes to `$IDNA_DIR` (always through `IDNA_DATA`)
- [ ] Public behaviour change → updates to `docs/operations.md` and/or `docs/session-schema.md`
- [ ] New template → registered in `templates/__init__.py` + has `types/<name>.toml` if axis-based
- [ ] No security vulnerabilities introduced
- [ ] No TODO comments without linked issue

## Conventional Comments

Reviews use Conventional Comments format:

| Label | Blocks merge? | When |
|-------|:---:|------|
| `issue(blocking):` | Yes | Bug, security, spec violation |
| `suggestion(blocking):` | Yes | Standard violation |
| `suggestion(non-blocking):` | No | Improvement idea |
| `nitpick:` | No | Style preference |
| `praise:` | No | Good work worth noting |

## Project-Specific Rules

- **Session shape changes** — any change to `session.json` keys needs a matching update to `docs/session-schema.md` and a backward-read path in `idna/session.py` (or an explicit "break old sessions" note in the PR description).
- **Template changes** — mutations must be **pure functions** of `(params, mutation, vocabulary, parent_id)`. No file I/O, no daemon calls, no randomness outside a seeded `random.Random`.
- **Axis vocabularies** — edits to `types/*.toml` change existing sessions' search space. Treat as a breaking change; tag the PR with `data-format` and call out which sessions need resetting.
- **Handler additions** — new `handle_*` functions in `idna/api*.py` must update `idna/server.py` routing *and* the HTML/JS picker code (`idna/html_picker_js_actions.py`).
- **High-res regen** — changes to `idna/hires.py` or `FINAL_WIDTH` / `FINAL_HEIGHT` must be tested against one real session end-to-end before merging.
- **Dependencies** — new entries in `[project.dependencies]` need a justification in the PR (we aim to keep runtime deps tiny: numpy + scipy only). Dev deps (`[dependency-groups].dev`) are freer.
- **Supervisor conf** — `plugins/idna/supervisor/conf.d/idna.conf` lives in `roxabi-plugins`, not here. Changes to supervisor behaviour need a cross-repo coordination note.

## AI Quick Reference

- **ALWAYS** flag new imports of `torch` / `diffusers` / `optimum.quanto` / `PIL` in this repo as `issue(blocking)`.
- **ALWAYS** flag writes to paths under `$IDNA_DIR` that should be under `$IDNA_DATA`.
- **ALWAYS** block PRs that add `# type: ignore` / `# noqa` without a one-line reason comment.
- **PREFER** `suggestion(non-blocking)` for test coverage on pure modules (`nodes`, `pbo`, `session`, `templates`).
- **PREFER** `nitpick` over `suggestion(blocking)` for style deviations that the configured `ruff` rules already ignore (e.g. `E741` for scientific single-letter vars).
