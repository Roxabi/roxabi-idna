# Ubiquitous Language

Glossary of domain terms used in this project. Keeps agents and contributors aligned on vocabulary.

## Glossary

| Term | Definition | Source |
|---|---|---|
| **Session** | Self-contained run under `$IDNA_DATA/<project>/<subject>/`. Holds `session.json` (state machine) plus per-round directories. | `idna/session.py` |
| **Project** | Outer namespace (e.g. `lyra`, `roxabi-site`). Groups related subjects. | session path, first segment |
| **Subject** | Inner namespace for a specific search (e.g. `avatar`, `logo-v3`). Holds one tree. | session path, second segment |
| **Template** | Strategy class that knows how to build params, prompts, mutations, and artifacts for one artifact type. | `templates/base.py`, `templates/__init__.py` |
| **Artifact** | The rendered output of a node — `.png` for image templates, `.html` / `.txt` for inline ones. | `BaseTemplate.artifact_path`, `artifact_type` |
| **Vocabulary** | `{axes, axis_priority, poles}` that defines the search space for a template. Lives inside `session.json`. | `types/*.toml`, `session.json` |
| **Axis** | Named dimension with `{name, low, high}`. Value is a float in `[0, 1]`. | `types/avatar.toml` |
| **Pole** | Concrete starting point in axis space (a dict of `axis_name: value`). Round 0 seeds from the pole list. | `vocabulary.poles` |
| **Node** | Single tree entry: id, round, parent, mutation, params, prompt, artifact path, status. | `idna_build_tree.py`, `idna/nodes.py` |
| **Node id** | Dash-separated lineage: `v0` (root), `v0-va` (first child), `v0-va-vb` (grandchild). Depth == dash count. | `_CHILD_SUFFIXES`, `node_parent` |
| **Round** | One generation batch. Round 0 = poles; round N = children of the BFS-queue leader. Width = children-per-node. | `round_nodes`, `node_count` |
| **Mutation** | How a child differs from its parent. Two dialects: `axis:<name>:±1` (AxisTemplate) or `amplify`/`blend`/`refine` (legacy cycle). | `child_mutation_key` |
| **BFS queue** | Ordered list of node ids the worker should generate next. Advanced by `/pick`, `/back`, `/reroll`. | `session.queue` |
| **Pick** | User's selection of the best candidate in the current frontier. Advances the BFS queue. | `idna/api.py handle_pick` |
| **Reroll** | Regenerate the current frontier with a different seed without changing tree structure. | `idna/api.py handle_reroll` |
| **Nudge** | Adjust axis values on the selected leaf without advancing the tree (exploratory fine-tuning). | `idna/api.py handle_nudge` |
| **Finalize** | Lock the chosen leaf, regenerate at `FINAL_WIDTH × FINAL_HEIGHT`, mark session `done`. | `idna/api.py handle_finalize`, `idna/hires.py` |
| **PBO** | Preference Bayesian Optimization. GP posterior over `f(x)` learned from pairwise picks, used to propose children outside the raw tree. | `idna/pbo.py` |
| **Embeds** | Cached text encoder outputs (`.pt`) per node prompt — skips re-encoding when regenerating. | `round_k/embeds/<id>.pt` |
| **Daemon** | The imageCLI background process. Owns torch/diffusers/quanto; receives requests over `$HOME/.local/share/imagecli/daemon.sock`. | `idna/daemon.py`, `DAEMON_SOCK` |
| **`IDNA_DIR`** | Repo root (code). Default = inferred from `idna/config.py` location. | `idna/config.py` |
| **`IDNA_DATA`** | Runtime session root. Default = `~/.roxabi/idna`. **Never** inside `~/.roxabi/forge`. | `idna/config.py` |

## Common Confusions

- **Project vs Subject** — `project` is the outer folder (one per consumer, e.g. `lyra`); `subject` is the inner run (one per attempt, e.g. `avatar-v2`). Supervisor program name: `idna-<project>-<subject>`.
- **`IDNA_DIR` vs `IDNA_DATA`** — `IDNA_DIR` is read-only code (this repo); `IDNA_DATA` is writable session state. They must point to different paths. Before the April 2026 split, both lived under `~/.roxabi/idna` — legacy conf files may still reference that combined path.
- **Axis (domain) vs axes (numpy)** — Use "axis" for a domain dimension (`medium`, `aesthetic`). Use "ndarray axis / dim" when talking about numpy tensors (in `idna/pbo.py`).
- **Amplify/Blend/Refine vs axis mutations** — Legacy templates (`voice`, `ui_component`) use the `_MUTATION_CYCLE` rotation. `AxisTemplate` descendants (`avatar`, `logo`, `color_palette`, `motion_curve`, `icon_set`) use `axis:<name>:±1` keys that target specific axes. Don't mix them within one template.
- **Artifact vs node** — A node is metadata; the artifact is the rendered file. Node exists as soon as the tree is built; artifact exists only after the worker (or `render_sync` for inline templates) generates it.
- **Pick vs Finalize** — `pick` selects a frontier member and advances BFS (you'll keep picking). `finalize` stops the search and regenerates at hi-res. You only finalize once per session.
