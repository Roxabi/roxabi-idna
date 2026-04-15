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
- `templates/` — HTML/JS frontend assets
- `types/` — Python type stubs

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

## Critical Rules

### TL;DR

- **Project:** roxabi-idna
- **Before work:** Use `/dev #N` as the single entry point — it determines tier (S / F-lite / F-full) and drives the full lifecycle
- **All code changes** → worktree: `git worktree add ../roxabi-idna-XXX -b feat/XXX-slug staging`
- **Always** `AskUserQuestion` for choices — never plain-text questions
- **Never** commit without asking, push without request, or use `--force`/`--hard`/`--amend`
- **Always** use appropriate skill even without slash command

### 1. Dev Process

**Entry point: `/dev #N`** — single command that scans artifacts, shows progress, and delegates to the right phase skill.

| Tier | Criteria | Phases |
|------|----------|--------|
| **S** | ≤3 files, no arch, no risk | triage → implement → pr → validate → review → fix* → cleanup* |
| **F-lite** | Clear scope, single domain | Frame → spec → plan → implement → verify → ship |
| **F-full** | New arch, unclear reqs, >2 domains | Frame → analyze → spec → plan → implement → verify → ship |

`*` = conditional (runs only if applicable)

Phases: **Frame** (problem) → **Shape** (spec) → **Build** (code) → **Verify** (review) → **Ship** (release).

### 2. AskUserQuestion

Always `AskUserQuestion` for: decisions, choices (≥2 options), approach proposals.
**Never** plain-text "Do you want..." / "Should I..." → use the tool.

### 3. Git

Format: `<type>(<scope>): <desc>` + `Co-Authored-By: Claude <model> <noreply@anthropic.com>`
Types: feat|fix|refactor|docs|style|test|chore|ci|perf
Never push without request. Never force/hard/amend. Hook fail → fix + NEW commit.

### 4. Artifact Model

Artifacts are the state markers `/dev` uses for progress detection and resumption.

| Type | Directory | Question answered |
|------|-----------|-------------------|
| **Frame** | `artifacts/frames/` | What's the problem? |
| **Analysis** | `artifacts/analyses/` | How deep is it? |
| **Spec** | `artifacts/specs/` | What will we build? |
| **Plan** | `artifacts/plans/` | How do we build it? |

### 5. Coding Standards

| Context | Read |
|---------|------|
| Tests | [testing](docs/standards/testing.md) |

## Gotchas

<!-- Add project-specific gotchas here -->
