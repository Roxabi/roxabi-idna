# Patterns

Recurring patterns and conventions used in this project.

## Naming Conventions

| Scope | Convention | Example |
|---|---|---|
| Module files | `snake_case.py` | `idna_server.py`, `html_picker_js.py` |
| Package dir | lowercase, no underscores | `idna/`, `templates/`, `types/` |
| Classes | `PascalCase` | `BaseTemplate`, `AxisTemplate` |
| Functions / methods | `snake_case` | `build_params`, `_blend_pole_embeds` |
| Private helpers | prefix `_` | `_node_round`, `_parse_path`, `_MUTATION_CYCLE` |
| Constants | `UPPER_SNAKE_CASE` | `TREE_WIDTH`, `IDNA_DATA`, `DAEMON_SOCK` |
| Type-config files | `snake_case.toml` | `types/avatar.toml`, `types/_shared.toml` |
| Node IDs (domain) | `v<N>[-v<suffix>]*` | `v0`, `v0-va`, `v0-va-vb` (suffix = `va…vi`) |
| Mutation keys | `axis:<name>:±1` or cycle term | `axis:medium:+1`, `amplify`, `blend`, `refine` |

## Error Handling

- **HTTP layer** — `idna/server.py` uses `BaseHTTPRequestHandler`. Handlers return `(status_code, body)` tuples; the server serialises to JSON. Unknown routes → 404 JSON.
- **Session state** — Any mutation reads `session.json`, applies the change, writes it back atomically from the same request. Concurrent writes are not expected (single user, single browser).
- **Daemon failures** — `idna/daemon.py` wraps the imageCLI socket. Socket errors are logged via `log.error(...)` and surface to the worker loop; the picker keeps serving stale state. Never swallow exceptions silently.
- **Logging** — Single logger `idna` (`log = logging.getLogger("idna")`), `INFO` default via `logging.basicConfig`. Use `log.error(...)` for recoverable failures, let unexpected exceptions propagate so supervisord captures the traceback.
- **Generation scripts** — `idna_{build_tree,encode_all,generate_round}.py` `sys.exit(1)` with a `print(..., file=sys.stderr)` on missing vocabulary/poles/session-id so supervisord logs the reason. No custom exception hierarchy — the scripts are linear.

## Data Flow

### Session lifecycle

```
idna_setup.py <project> <subject> <template>
  → writes $IDNA_DATA/<project>/<subject>/session.json (vocabulary + config)

idna_build_tree.py <session_dir> [--depth N]
  → writes round_k/prompts/<id>.json job files for every node in the tree
  → for html/text templates, also renders artifacts immediately
  → no GPU / no LLM calls

idna_encode_all.py <session_dir>             (imageCLI venv, optional pre-pass)
  → writes round_k/embeds/<id>.pt

idna_generate_round.py <round_dir>            (imageCLI venv)
  → writes round_k/<id>.png

idna_server.py (supervised)
  → serves picker UI, accepts pick/reroll/reset/nudge/finalize
  → BFS worker ensures the next round exists on demand
  → at finalize, calls high-res regen (FINAL_WIDTH × FINAL_HEIGHT)
```

### Request → handler → state → file

```
Browser  ──(GET /<project>/<subject>/pick?id=v0-va)──▶  idna.server.main
                                                          │
                                                          ▼
                                                  idna.api.handle_pick
                                                          │  reads + writes
                                                          ▼
                                                  $IDNA_DATA/.../session.json
                                                          │
                                    (background) ──▶  idna.generation._ensure_worker
                                                          │
                                                          ▼
                                                  idna.daemon  ──(socket)──▶  imageCLI
                                                          │
                                                          ▼
                                                  round_k/<id>.png
```

### Template plug-in

`templates/__init__.py` defines a `get_template(name)` registry. Adding a new template:

1. Create `templates/<name>.py`, subclass `BaseTemplate` (or `AxisTemplate` for numeric-axis spaces).
2. Implement `build_params`, `mutate`, `build_prompt`, `artifact_path`. Optionally override `child_mutation_key`, `negative_prompt`, `render_sync` (inline renderers like `color_palette`, `motion_curve`, `voice`).
3. Register in `templates/__init__.py`.
4. Add a type config at `types/<name>.toml` (axes, poles, axis_priority) if axis-based.

## See Also

- [Architecture Overview](index.md) — layers, boundaries, high-level design
- [ADRs](adr/) — Architecture Decision Records
