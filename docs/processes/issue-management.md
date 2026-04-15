# Issue Management

Project-specific issue conventions. Agents read this via `{standards.issue_management}`.

> Universal patterns (severity × impact matrix, spec completeness checklist) are embedded in the `product-lead` agent.
> This file documents **this project's specific** issue workflow.

## Issue Lifecycle

Issues move through statuses on the GitHub Project **roxabi-idna board** (#20):

```
Backlog → Analysis → Specs → In Progress → Review → Done
```

| Status | Enters when | Leaves when |
|---|---|---|
| **Backlog** | Issue created / triaged | Work picked up (or parked) |
| **Analysis** | `/dev` tier needs deeper technical exploration (F-full) | Spec is ready for drafting |
| **Specs** | Solution being designed | Spec accepted → ready to plan/implement |
| **In Progress** | Branch cut, PR open (draft or ready) | PR merged or closed |
| **Review** | PR has `reviewed` label awaiting merge | Merged or kicked back to In Progress |
| **Done** | PR merged | (terminal) |

Tier-S issues skip `Analysis` and `Specs`; tier F-full uses all five pre-done columns.

## Labels

| Category | Labels | Purpose |
|---|---|---|
| **Type** | `bug`, `feature`, `enhancement`, `docs`, `chore`, `research` | What kind of work |
| **Area** | `backend`, `frontend`, `infra`, `api`, `design` | Which slice of the repo |
| **Size** | `XS`, `S`, `M`, `L`, `XL` (on project board, not as labels) | Effort estimate |
| **Priority** | `P0 - Urgent`, `P1 - High`, `P2 - Medium`, `P3 - Low` (on project board) | Urgency |
| **Flow** | `reviewed` | Triggers auto-merge once CI is green |
| **Meta** | `dependencies`, `ci` | Dependabot / CI-only PRs |
| **Default** | `good first issue`, `help wanted`, `question`, `duplicate`, `invalid`, `wontfix` | GitHub defaults |

Note: for this single-service Python repo, `frontend` means the minimal browser picker UI (`idna/html_*.py`, `idna-template.html`, inline-rendered HTML templates); `backend` covers `idna/server.py`, `idna/api*.py`, session/tree/PBO logic.

## Templates

`.github/ISSUE_TEMPLATE/` is not yet populated. Recommended templates when we get there:

- **Bug report** — reproduction (session + template + axis values), expected vs actual, logs from `make idna errlogs`, host (`roxabitower` / `roxabituwer`).
- **Feature request** — target artifact type (avatar/logo/palette/…), why existing templates don't cover it, proposed axes.
- **Template proposal** — new `templates/<name>.py` with axes spec, sample prompts, expected `artifact_type`.

For now, open issues against the `roxabi-idna` project on GitHub (`Roxabi/roxabi-idna`); the `dev-core:issue-triage` skill handles size/priority/status fields.

## Sizing Guidelines

| Size | Time | Typical scope |
|---|---|---|
| **XS** | < 1 h | Typo, single constant tweak, doc fix, single ruff/pyright silence |
| **S** | < 4 h | Single-file bug fix, add a template field, touch one handler |
| **M** | 1–2 d | New template end-to-end (`templates/<name>.py` + `types/<name>.toml` + registry), new handler + picker wiring |
| **L** | 3–5 d | Session format change with migration path; PBO algorithm change with tests; new artifact type (e.g. audio) requiring daemon protocol additions |
| **XL** | > 1 w | Architectural shift (e.g. replace BaseHTTPRequestHandler with FastAPI, multi-user support, remote deploy) |

When in doubt, size up one tier — under-sized issues cause late scope expansion and block the board column ordering.

## Dependencies & sub-issues

- **Blocked by** — use GitHub issue links in the description (`Blocked by #<N>`) for cross-issue dependencies.
- **Parent / child** — supported via the `gh` CLI + dev-core's `issue-triage` skill. Parent = umbrella (F-full), children = the sliced F-lite issues that implement it.
- **Cross-repo** — for work that spans `roxabi-idna` ↔ `imageCLI` ↔ `roxabi-plugins` (e.g. supervisor conf changes), open issues in both repos and cross-link; the dashboard shows both boards side-by-side.
