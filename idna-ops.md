# IDNA Operations

Shared operational details for all idna skills. Read this once per invocation.

---

## Directory Layout

Code and session data are split, mirroring the `roxabi-forge` pattern.

```
~/projects/roxabi-idna/                ← code (IDNA_DIR, this repo)
  idna_server.py                       ← HTTP server (API + static files, port 8082)
  idna-template.html                   ← browser picker
  idna_generate_round.py               ← 2-phase image gen (imageCLI)
  idna_build_tree.py  idna_encode_all.py  idna_setup.py
  idna/                                ← Python package
  templates/  types/                   ← template code + TOML type configs

~/.roxabi/idna/                        ← session data (IDNA_DATA, local only, never deployed)
  <project>/<subject>/
    session.json                       ← state machine
    round_0/
      v0.png … v3.png                  ← explore variants
      prompts/v0.json … v3.json        ← job files
      embeds/v0.pt … v3.pt             ← cached text embeddings
    round_N/
      va.png  vb.png  vc.png           ← amplify / blend / refine
      prompts/  embeds/
```

Override with env: `IDNA_DIR` (code root) and `IDNA_DATA` (session root).

**Never inside `~/.roxabi/forge/`** — forge is Cloudflare-deployed. IDNA is local-only.

---

## Supervisord

Program name pattern: `idna-<project>-<subject>`  
Example: `idna-lyra-avatar`

```bash
# Via lyra-stack Makefile
make idna                       # status of all idna-* programs
make idna start                 # start idna-lyra-avatar
make idna stop
make idna reload
make idna logs
make idna errlogs

# Direct supervisorctl
supervisorctl start idna-lyra-avatar
supervisorctl status idna-lyra-avatar
supervisorctl tail -f idna-lyra-avatar
```

Conf lives at: `~/projects/conf.d/idna.conf`  
`autostart=false` — start manually when needed, stop when done.

---

## Server

Port: **8082** (fixed)  
URL: `http://localhost:8082/`

The idna server (`idna_server.py`) is self-contained:
- Serves `idna-template.html` at `GET /`
- Serves `round_N/*.png` images as static files
- `GET /api/status` — current session.json
- `POST /api/pick` — `{"variant_id": "va"}` → record pick, trigger next round
- `POST /api/finalize` — lock winner, mark done

Uses **Claude CLI** (`claude -p`) — no API key needed, OAuth-authenticated.

---

## Ports — No Conflicts

| Service | Port | Purpose |
|---------|------|---------|
| diagrams (forge) | 8080 | Galleries + visual explainers → Cloudflare |
| idna | 8082 | Evolutionary selector → local only |

---

## Session State Machine

```
ready → (pick) → generating → (done) → ready (next round)
                                    └→ done (finalize)
```

`status` field: `ready | generating | done | error`  
`progress` during generating: `asking_claude → encoding → generating_images`

---

## Artifact Type Support

| Type | Generator | Notes |
|------|-----------|-------|
| Image | `idna_generate_round.py` + imageCLI FLUX.2-klein | 2-phase: encode all → generate all |
| Voice | voiceCLI (future) | Replace generation subprocess |
| Text | inline in session.json (future) | No generation step |

---

## Project Detection

Detect project + subject from ARGS or cwd:
1. Explicit in ARGS: `"idna for lyra avatar"` → project=lyra, subject=avatar
2. CLAUDE.md heading in cwd
3. `pyproject.toml` → `[project] name`
4. Ask if ambiguous

Session dir: `$IDNA_DATA/<project>/<subject>/` (default `~/.roxabi/idna/`)

---

## Seed Convention

| Round | Seeds |
|-------|-------|
| Round 0 (explore) | 0, 1, 2, 3 |
| Round N (converge) | N×100, N×100+1, N×100+2 |
