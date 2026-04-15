# Development Process

Project-specific development workflow. Agents read this via `{standards.dev_process}`.

## Branch Strategy

| Branch | Role | Protection |
|---|---|---|
| `main` | Production-equivalent. Prod host (`roxabituwer`) tracks this. | `ci` required, no force-push, no deletion, `PR_Main` ruleset (squash \| rebase \| merge) |
| `staging` | Integration. Feature work lands here first. | Same as `main` |
| `feat/<N>-<slug>` | Feature branches | Cut from `staging`, merge back via PR |
| `fix/<N>-<slug>` | Bug fixes | Cut from `staging`, merge back via PR |
| `chore/<slug>` | Tooling / docs only | Cut from `staging` or `main`, merge back via PR |
| `dependabot/**` | Auto-generated | Auto-merge when CI green + `reviewed` label |

Feature flow: `feat/... → staging → main`. Dependabot + hotfixes can go straight to `main` when that's the safer route.

## Workflow

Single entry point: `/dev #N` (the issue number). Tier is auto-detected:

| Tier | When | Phases |
|---|---|---|
| **S** (small) | ≤ 3 files, no arch change, no risk | triage → implement → pr → validate → review → fix* → cleanup* |
| **F-lite** | Clear scope, one domain | Frame → spec → plan → implement → verify → ship |
| **F-full** | New arch / unclear reqs / > 2 domains | Frame → analyze → spec → plan → implement → verify → ship |

*Artifacts* (`artifacts/frames/`, `artifacts/analyses/`, `artifacts/specs/`, `artifacts/plans/`) are the state markers `/dev` uses to resume an in-progress issue.

All code changes happen in a **git worktree**:

```bash
git worktree add ../roxabi-idna-<issue>  -b feat/<issue>-<slug>  staging
```

Keeps the main checkout clean while work-in-progress; every new session starts clean by default.

## Code Ownership

Single maintainer for now. Review is still enforced via branch protection (self-review + the `ci` check); open PRs even for small changes so the audit trail stays intact.

| Path | Area |
|---|---|
| `idna/` | HTTP server, API, state machine |
| `templates/` | Per-artifact-type strategy plug-ins |
| `types/` | TOML vocabularies (axes/poles) |
| `idna_*.py` (root scripts) | Setup + tree/encode/generate entry points |
| `.github/workflows/` | CI definitions (changes need CI re-run to take effect) |
| `docs/` | Project docs (this directory) |
| `~/.roxabi/forge/idna/` | Visual explainers, galleries (via `forge` skill — edited outside this repo) |

## Release Process

- **Conventional Commits** — every merge commit to `main` follows `<type>(<scope>): <desc>` (types: `feat|fix|refactor|docs|style|test|chore|ci|perf`). Enforced by the `pr-title.yml` workflow.
- **Release Please** — config at `release-please-config.json` (`release-type: python`). No workflow wired yet; when added (`.github/workflows/release-please.yml`), pushes to `main` will open a release PR that bumps version + updates `CHANGELOG.md`.
- **Tags** — only produced by Release Please. No manual `git tag` unless hot-fixing an old release.
- **Semver** — Breaking = major, feature = minor, fix = patch. Since `roxabi-idna` has no public Python API (it's a service), "breaking" primarily means session-format changes or removed commands.

## Commit & PR hygiene

- Every commit ends with `Co-Authored-By: Claude <model> <noreply@anthropic.com>` when Claude contributed.
- Never `git push --force` on `main` / `staging`. Hook failure → fix + **new** commit.
- Never `git commit --amend` on a pushed commit.
- PR titles match the Conventional Commits regex; CI blocks otherwise.
- Label `reviewed` triggers auto-merge (needs CI green first).
