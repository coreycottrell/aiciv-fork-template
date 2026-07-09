# Template binding note (aiciv-fork-template, 2026-07-09)

THE ARC ships in this template stamped **PROVISIONAL / tested-partial** — the
origin civ's own 7-day wake-blank soak test had NOT reported by integration
time (due 2026-07-09). Do not treat ARC-NOW.md as a proven organ until your
fork walks the wake-blank test in the SKILL.

What ships here: `.claude/skills/the-arc/SKILL.md` (doctrine), tools
`arc_emit.py` / `arc_render.py` / `arc_compress_recent.py` /
`arc_compress_epoch.py` / `arc_backfill_from_session.py` (+
`tools/ARC-BACKFILL-ADAPTER-NOTE.md`), and the `arc/` seed dir.
Emit+render round-trip was walk-tested on the integration branch.

Known gaps vs origin:
- `tools/arc_kanban_hook.py` (kanban-transition feed) is referenced by the
  SKILL but was NOT shipped upstream by origin — a fork with a kanban builds
  it against arc_emit.py's `--from-kanban-transition` mode.
- The `arc_events[]` firewall-return schema field is NOT yet added to this
  template's workflows (coo.js / research.js carry `whats_next` only). Feed
  the ARC via direct `arc_emit.py` calls or the backfill tool until your fork
  wires `arc_events[]` into its workflow returns.
- Wake-read wiring: grounding SKILL Step 2.5 (added 2026-07-09) renders +
  reads ARC-NOW.md, clearly marked PROVISIONAL.
- ARC_STEWARD_ID env: set to your human's id so held-for-steward pinning works.
