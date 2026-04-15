# Backend Patterns

Project-specific backend conventions. Agents read this via `{standards.backend}`.

> Universal patterns (REST status codes, ORM anti-patterns, error handling) are embedded in the `backend-dev` agent.
> This file documents **this project's specific** choices.

## Framework & ORM

- **HTTP server** — stdlib `http.server.BaseHTTPRequestHandler` (no Flask/FastAPI/Django). Single-threaded, single-user, low traffic. Port `8082` (hard-coded in `idna.server`).
- **Storage** — flat JSON (`session.json`) + per-round dirs on the local filesystem. No database, no ORM.
- **Runtime** — Python 3.12, `uv` for deps, `uv.lock` committed.
- **Heavy ML** — not imported here. `torch`, `diffusers`, `optimum.quanto`, `PIL` live in imageCLI's venv; this repo talks to the imageCLI daemon over a Unix socket (`idna/daemon.py`).

## Module Structure

```
idna/                                package root
  __init__.py                        re-exports `main` from server
  server.py                          HTTPServer setup, request routing
  api.py / api_new.py                endpoint handlers (pick, back, delete, finalize, nudge, reroll, new)
  config.py                          constants: IDNA_DIR, IDNA_DATA, TREE_*, DAEMON_SOCK, MIME, log
  session.py                         session.json read/write, format detection, discovery
  nodes.py                           tree topology, blend-pole embeds via daemon
  daemon.py                          imageCLI socket client
  generation.py                      background worker: "ensure next round exists"
  hires.py                           FINAL_WIDTH × FINAL_HEIGHT regen at finalize
  pbo.py                             preference Bayesian optimization (numpy/scipy only)
  html_*.py                          static HTML/CSS/JS string templates (server-rendered)

templates/                           strategy plug-ins (one per artifact type)
  base.py                            BaseTemplate / AxisTemplate abstract classes
  {avatar,logo,color_palette,icon_set,motion_curve,voice,ui_component}.py
  __init__.py                        get_template(name) registry

types/                               TOML type configs (axes, poles) referenced at setup
  _shared.toml  avatar.toml  logo.toml

idna_server.py                       PEP 723 entry wrapper
idna_setup.py                        session bootstrap (writes session.json)
idna_build_tree.py                   build all node params + job files (no GPU/LLM)
idna_encode_all.py                   pre-encode prompts                 (PEP 723 → imageCLI venv)
idna_generate_round.py               generate a round of images         (PEP 723 → imageCLI venv)
```

## API Conventions

- **Path shape** — `/<project>/<subject>/<action>`. Two-segment prefix is the session; the rest routes to a handler.
- **Static** — `/` serves the index (session list); `/picker.html`, `/picker.css`, `/picker.js` are inlined via `idna/html_*.py` (no `static/` dir).
- **State endpoints** — return JSON `{ok: true, ...}` / `{ok: false, error: "..."}` . Status always `200` for JSON (client inspects `ok`). `404` only for unknown routes.
- **Binary endpoints** — `.png` with `Content-Type: image/png` served directly from `$IDNA_DATA/...`.
- **Mutation-as-query** — all state changes are `GET` with query params (browser picker is plain links). Idempotent-ish: server is single-user so replay is acceptable.
- **No auth** — listens on localhost only; relies on supervisord + machine-local access.

## Data Access Rules

- **Read-modify-write on `session.json`** — every handler that mutates state reads the whole file, updates the dict, writes it back. Atomicity is single-process + single-user; no locking.
- **Never persist under `$IDNA_DIR`** — writes to the code tree leak session data into git history. Always resolve through `IDNA_DATA`.
- **Round artifacts** — `round_k/<id>.png` + `round_k/prompts/<id>.json` + `round_k/embeds/<id>.pt`. Missing `.png` means "not yet generated"; missing `.pt` means "encoder will run per-round".
- **BFS queue** — `session.queue` is the source of truth for "what to generate next". Mutating it = advancing the tree.
- **Legacy format** — `_is_new_format()` in `idna/session.py` decides which code path to use. New sessions always use the new format; old sessions are read-compatible but not mutated to the new shape.

## AI Quick Reference

- **NEVER** import `torch` / `diffusers` / `optimum.quanto` / `PIL` in this repo — talk to imageCLI's daemon via `idna/daemon.py`.
- **NEVER** write session data inside `$IDNA_DIR` or anywhere under `~/.roxabi/forge/` — use `IDNA_DATA`.
- **ALWAYS** resolve data paths through `idna.config.IDNA_DATA`, never hard-code `~/.roxabi/idna`.
- **PREFER** adding a template (subclass of `BaseTemplate` / `AxisTemplate`) over forking `idna_build_tree.py` — the tree builder is template-agnostic.
- **ALWAYS** update the `templates/__init__.py` registry when adding a template, and add a matching `types/<name>.toml` if axis-based.
- **ALWAYS** keep the HTTP handlers single-threaded and stateless between requests — session.json is the only shared state.
- **PREFER** extending the axis-mutation dialect (`axis:<name>:±1`) over the legacy `amplify/blend/refine` cycle for new templates.
