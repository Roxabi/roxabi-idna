@.claude/stack.yml
@~/.claude/shared/global-patterns.md

# roxabi-idna

Evolutionary selector for avatars/logos/brand concepts. Python 3.12 service that runs an HTTP picker on port 8082 (`idna_server.py`) and generates candidate rounds via `imageCLI`. Sessions live outside the repo in `$IDNA_DATA` (default `~/.roxabi/idna`).

## Architecture

- `idna_server.py` — HTTP picker (port 8082), serves `idna-template.html` + session data
- `idna_generate_round.py` — produces the next round of candidates
- `idna_encode_all.py` — encodes/embeds face images for similarity scoring
- `idna_build_tree.py` — builds the evolutionary tree from picks
- `idna_setup.py` — session bootstrap
- `templates/` — artifact generation strategies (`BaseTemplate` subclasses for avatar/logo/etc)
- `types/` — template vocabulary configs (axes, poles, `axis_priority` as TOML)

Data split: `IDNA_DIR` = repo code, `IDNA_DATA` = session artifacts (outside repo).

## Docs

- [docs/operations.md](docs/operations.md) — ops runbook (supervisor, logs, data dirs)
- [docs/session-schema.md](docs/session-schema.md) — layout of `$IDNA_DATA/<session>/`
- [docs/architecture/index.md](docs/architecture/index.md) — design + layers
- [docs/standards/](docs/standards/) — coding + testing conventions
- `~/.roxabi/forge/idna/` — visual explainers, brand/avatar galleries (via `forge` skill)
- `artifacts/` — dev-core frames/specs/plans/analyses for ongoing work

## Running

```bash
make idna start      # via supervisor hub
make idna logs       # follow stdout
make idna ls         # list sessions in $IDNA_DATA
```

## TL;DR

- **Project:** roxabi-idna
- **Before work:** Use `/dev #N` as the single entry point — it determines tier and drives the full lifecycle
- **Never** commit without asking, push without request, or use `--force`/`--hard`/`--amend`
- **Always** use appropriate skill even without slash command

## Gotchas

<!-- Add project-specific gotchas here -->
