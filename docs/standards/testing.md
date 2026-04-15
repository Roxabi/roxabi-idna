# Testing Standards

Project-specific testing conventions. Agents read this via `{standards.testing}`.

> Universal patterns (Testing Trophy, mock boundaries, coverage anti-patterns, flaky test classification) are embedded in the `tester` agent.
> This file documents **this project's specific** testing setup.

## Framework Setup

- **Runner** — `pytest` (via `uv run pytest`). No config file yet; defaults apply.
- **Layout** — tests live next to code in `tests/` at the repo root (not co-located). Create it on first test. Mirror package structure: `tests/test_nodes.py` → `idna/nodes.py`.
- **Discovery** — default `test_*.py` / `*_test.py`. Class pattern `Test*`. Function pattern `test_*`.
- **Dev dep** — `pytest>=9.0.3` in `[dependency-groups] dev` of `pyproject.toml`.
- **CI** — `ci.yml` runs `uv run pytest` after lint/typecheck.

## Mocking Strategy

- **imageCLI daemon** — never hit a real socket in tests. Mock `idna.daemon.send_request` (or whatever function the test path goes through) with `monkeypatch`. Don't try to spin up a fake socket.
- **Filesystem** — use `tmp_path` fixture for anything that reads/writes sessions. Never let a test touch `$IDNA_DATA`.
- **HTTP** — `idna/server.py` uses stdlib `BaseHTTPRequestHandler`. Test handlers at the function level (`handle_pick`, `handle_finalize`) with fake session dicts — don't stand up a real server for unit tests.
- **Environment** — `monkeypatch.setenv("IDNA_DATA", str(tmp_path))` + re-import or re-read `idna.config.IDNA_DATA` in the test. The module reads env at import time.
- **Time / randomness** — tree mutations use `random.Random(seed)` with a deterministic seed derived from `node_id`. Tests should assert against known outputs for known ids.

## Coverage Thresholds

- No hard threshold yet. Start by covering:
  - `idna/session.py` — `session.json` read/write + legacy format detection (high-value, pure)
  - `idna/nodes.py` — `node_parent`, `node_count`, `round_nodes`, blend weight math
  - `idna/pbo.py` — GP fit/predict on synthetic data
  - `templates/*.py` — `build_params`, `mutate`, `build_prompt` for at least one axis-based + one legacy template
- `idna/server.py`, `idna/api*.py` — handler-level unit tests are welcome, but full HTTP loop tests are out of scope (external-process behaviour).
- Goal once a baseline exists: 60% line coverage on pure modules (`nodes`, `pbo`, `session`, `templates`), waive coverage on the HTTP/daemon glue.

## Fixtures

Minimal set to maintain as patterns emerge:

- `tmp_session` — builds a minimal `$IDNA_DATA/<project>/<subject>/session.json` with a tiny vocabulary (2 axes, 3 poles) and yields the path.
- `fake_daemon` — monkeypatches the daemon client to return canned tensors / dicts.

Keep fixtures in `tests/conftest.py`.

## AI Quick Reference

- **ALWAYS** use `tmp_path` for session-like filesystem tests — never touch `$IDNA_DATA`.
- **NEVER** import `torch` / `diffusers` in tests — mock `idna/daemon.py` instead.
- **ALWAYS** call handlers (`handle_pick`, `handle_finalize`, …) directly for unit tests rather than starting a real HTTPServer.
- **PREFER** table-driven tests with `pytest.mark.parametrize` for template mutations — mutations are pure functions of (params, mutation, vocabulary, parent_id).
- **ALWAYS** set `IDNA_DATA` via `monkeypatch.setenv` before importing modules that capture it at import time.
- **NEVER** assert on exact `.png` bytes — image equality is brittle; assert on metadata (size, file existence, `session.json` updates) instead.
