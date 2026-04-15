# Frontend Patterns

Project-specific frontend conventions. Agents read this via `{standards.frontend}`.

> **This project has no frontend framework.** There is no Next.js, React, Vue, Svelte, or build pipeline. The browser-served picker UI is plain HTML + vanilla JS + CSS, all generated as Python strings by `idna/html_*.py` and rendered server-side. This file documents how to work with that minimal UI.

## Where the UI lives

| Module | Output | Served at |
|---|---|---|
| `idna/html_picker.py` | `PICKER_HTML` constant — full picker page | `/<project>/<subject>/picker.html` |
| `idna/html_picker_css.py` | `PICKER_CSS` — scoped styles | `/<project>/<subject>/picker.css` |
| `idna/html_picker_js.py` | `PICKER_JS` — boot + state container | `/<project>/<subject>/picker.js` |
| `idna/html_picker_js_render.py` | render helpers (DOM-building functions) | (imported into `PICKER_JS`) |
| `idna/html_picker_js_actions.py` | action handlers (pick, reroll, back, finalize) | (imported into `PICKER_JS`) |
| `idna/html_index.py` | `_index_html(sessions)` — session list page | `/` |
| `idna/html_index_css.py` / `idna/html_index_js.py` | index-page styles + JS | `/index.css`, `/index.js` |
| `idna-template.html` | standalone HTML template (legacy, used by some flows) | bundled at setup |
| `templates/{color_palette,motion_curve,voice,ui_component,icon_set}.py` | `render_sync()` emits inline HTML artifacts | direct file under `$IDNA_DATA/...` |

## Conventions

- **No build step** — edits to HTML/CSS/JS take effect on next `make idna reload`. Don't add a bundler.
- **No frameworks** — vanilla DOM APIs only. No jQuery, no Alpine, no HTMX. Event handlers via `element.addEventListener(...)`.
- **Single CSS file per page** — no CSS modules, no SASS. Use CSS custom properties for theming (already used for dark/light).
- **Indent + multiline** — the HTML/JS strings are meant to be read. Keep indentation in the Python multiline strings, don't minify.
- **Server-rendered state** — the initial HTML includes the current session state inlined (e.g. `<script>window.__SESSION__ = {…}</script>`). The JS never fetches state on load, only on user actions.
- **Action URLs** — picker buttons are `<a href="/<project>/<subject>/pick?id=…">` (plain links, not `fetch`). Keeps the state flow debuggable via the browser address bar.
- **Images** — `<img src="…/round_N/<id>.png">` with `loading="lazy"` for long trees. `onerror` hides broken images (pending-generation state).

## Inline-rendered templates

Templates that produce HTML/text artifacts (`color_palette`, `motion_curve`, `voice`, `ui_component`, `icon_set`) implement `render_sync(node, session_dir, vocabulary) -> Path | None` on `BaseTemplate`. Called by `idna_build_tree.py` for `artifact_type in ("html", "text")` at build time. Guidelines:

- **Self-contained** — one HTML file per node, no external CSS/JS. Inline `<style>` and inline event handlers if needed.
- **Viewable from `file://`** — so we can open without the picker running.
- **Deterministic** — given the same `node["params"]`, produce the same HTML. No timestamps, no random.
- **Under ~50 KB** — large galleries are expensive to load when browsing.

## AI Quick Reference

- **NEVER** add a JS framework, bundler, or CSS preprocessor — this is intentionally a plain-HTML picker.
- **ALWAYS** keep `idna/html_*.py` Python-string templates indented and readable — we edit them by hand.
- **ALWAYS** use plain `<a href="…">` links for picker actions (not `fetch`) so state changes are debuggable from the URL bar.
- **NEVER** fetch session state on page load — the server inlines it into the initial HTML.
- **PREFER** a new `templates/<name>.py` with `render_sync` over extending the picker HTML when the artifact is standalone viewable content.
