# Architecture

`roxabi-idna` is a single-process Python HTTP service that runs an evolutionary search for brand concepts (avatars, logos, palettes, motion curves, voice lines, UI components). A user picks the best candidate from each round through a browser picker served on port `8082`; the picker updates session state and a background worker generates the next round of candidates via the `imageCLI` daemon.

## High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Browser picker (idna-template.html)      :8082             │
└─────────────┬───────────────────────────────────────────────┘
              │ HTTP (JSON for state, PNG for candidates)
┌─────────────▼───────────────────────────────────────────────┐
│  idna_server.py  →  idna.server.main                        │
│    ├─ api.py / api_new.py        (handlers: pick, reroll,   │
│    │                              reset, finalize, …)       │
│    ├─ generation.py              (worker: ensure next round)│
│    ├─ daemon.py                  (imageCLI socket client)   │
│    ├─ nodes.py / session.py      (tree + state machine)     │
│    └─ pbo.py                     (preference Bayesian opt.) │
└─────────────┬───────────────────────────────────────────────┘
              │ Unix socket
┌─────────────▼───────────────────────────────────────────────┐
│  imageCLI daemon (external — provides torch/diffusers)      │
└─────────────────────────────────────────────────────────────┘

Session data (sessions, rounds, embeds, images) → $IDNA_DATA
Code                                             → $IDNA_DIR
```

## Layers

| Layer | Modules | Responsibility |
|---|---|---|
| **Entry** | `idna_server.py` | PEP 723 wrapper that calls `idna.server.main` |
| **HTTP** | `idna/server.py`, `idna/html_*.py` | Routing, static HTML/CSS/JS generation, request/response |
| **API** | `idna/api.py`, `idna/api_new.py` | Per-endpoint handlers (pick, back, delete, finalize, nudge, reroll, new) |
| **Domain** | `idna/nodes.py`, `idna/session.py`, `idna/pbo.py` | Tree topology, session state machine, preference Bayesian optimization |
| **Template strategy** | `templates/*.py` | Per-artifact-type params/prompt/mutation logic (avatar, logo, color_palette, icon_set, motion_curve, voice, ui_component) |
| **Generation** | `idna/generation.py`, `idna/daemon.py`, `idna/hires.py` | Worker loop, imageCLI socket client, high-res regen at finalize |
| **Config** | `idna/config.py` | Shared constants, env-var resolution (`IDNA_DIR`, `IDNA_DATA`) |
| **Runtime-only scripts** | `idna_build_tree.py`, `idna_encode_all.py`, `idna_generate_round.py`, `idna_setup.py` | Session bootstrap + batch ops; the encode/generate scripts run under imageCLI's venv (PEP 723 shebang) |

## Key Decisions

- **Data split** — `$IDNA_DIR` holds code (this repo); `$IDNA_DATA` (default `~/.roxabi/idna`) holds every session. Session dirs are **never** checked into git and **never** placed under `~/.roxabi/forge/` (forge deploys to Cloudflare Pages; idna is local-only).
- **Heavy-ML delegation** — `torch`, `diffusers`, `optimum.quanto`, `PIL` live in imageCLI's venv. This repo never imports them directly; `idna/daemon.py` talks to the imageCLI daemon over a Unix socket, and `idna_{encode_all,generate_round}.py` opt into imageCLI's venv via PEP 723.
- **Template = strategy** — New artifact types (beyond avatar/logo) subclass `BaseTemplate` (or `AxisTemplate`) in `templates/`. The registry in `templates/__init__.py` wires them by `name`.
- **Axis-aware vs legacy mutation** — `AxisTemplate` descendants use `axis:<name>:±1` mutation keys; legacy templates use the `amplify/blend/refine` cycle from `_MUTATION_CYCLE`.

See the `adr/` directory for Architecture Decision Records.

## See Also

- [Operations](../operations.md) — runtime ops, supervisor commands, data dirs
- [Session Schema](../session-schema.md) — layout of `$IDNA_DATA/<session>/`
- [Patterns](patterns.md) — naming conventions, error hierarchy, data flow
- [Ubiquitous Language](ubiquitous-language.md) — shared domain vocabulary
- [Configuration](../standards/configuration.md) — environment variables, config files, priority chain
- [Deployment](../guides/deployment.md) — deployment steps and platform setup
- [Troubleshooting](../guides/troubleshooting.md) — common issues and solutions
- Visual explainers + brand galleries live in `~/.roxabi/forge/idna/` (forge skill)
