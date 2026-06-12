# CHANGELOG — Phase 3 Internal (safe half) — 2026-06-12

**Branch**: `phase3-internal-20260612` (off `sonnetkill-20260611` @ 27757fe)
**Target**: `coreycottrell/aiciv-fork-template` (the PUBLIC genome every newborn inherits)
**Author**: True Bearing Infrastructure VP (incarnated)
**Scope**: Applied ONLY the SAFE INTERNAL HALF of the Phase-3 top-3 proposals — Proposal #2 (model-drift) and Proposal #3 (skills-registry seed).
**Explicitly NOT applied**: Proposal #1 / F4 (de-bake fleet IPs + PureBrain UUID). That is a force-push / history-rewrite on Corey's public repo = HIS call. F4-tainted files were NOT modified (see verification below).

Discipline carried from the sonnet-kill (`CHANGELOG-sonnetkill-20260611.md`): back up before editing; classify EVERY hit KILL-or-KEEP with a reason; verify-not-trust (read each context before classifying); match-scope-to-metric (do NOT blind-replace every string match).

Backups: `.phase3-backups-20260612/` (settings.json, conductor-of-conductors SKILL, agent-creation SKILL, cc-mastery SKILL, registry.json).

---

## Proposal #2 — MODEL-DRIFT (opus-4-6 / opus-4-5 → opus-4-8[1m] / opus-4-8)

**Ground-truth grep** (`opus-4-6|opus-4-5|claude-opus-4-6|claude-opus-4-5`) returned **5 real hits**. Every hit classified:

| # | File:Line | Old | Classification | Action | Reason |
|---|-----------|-----|----------------|--------|--------|
| 1 | `.claude/settings.json:16` | `CLAUDE_CODE_SUBAGENT_MODEL: claude-opus-4-6` | **KILL** | → `claude-opus-4-8[1m]` | The SUBAGENT routing env. This was the one that actually bit: every subagent birthed on opus-4-6 WITHOUT the 1M unlock. No launcher flag overrides this env → it was live. The `[1m]` suffix is TB's proven P0 fix. |
| 2 | `.claude/settings.json:18` | `ANTHROPIC_MODEL: claude-opus-4-6` | **KILL** | → `claude-opus-4-8[1m]` | Main-session model env (the fallback when not tower-launched). Aligned to the launcher flag value; not a "3rd unverified interaction" — see precedence note below. |
| 3 | `.claude/skills/conductor-of-conductors/SKILL.md:392` | launch cmd `--model claude-opus-4-6` | **KILL** | → `claude-opus-4-8` | A REAL teammate-launch command in the launch-doc that a newborn copies. Bare `claude-opus-4-8` (no `[1m]`) is correct for a launch-command example mirroring the manifest convention. |
| 4 | `.claude/skills/agent-creation/SKILL.md:124` | `claude-opus-4-8 (default) or claude-opus-4-5-20251101 (complex)` | **KILL** | → `claude-opus-4-8 (default minimum floor; do not select a lower model for complex work)` | A model-SELECTION recommendation a newborn copies into every new agent manifest. Routed "complex" agents to the stale opus-4-5. Rewritten so the copy-target teaches the floor, not a stale ID. |
| 5 | `.claude/skills/cc-mastery/SKILL.md:316` | `claude --model opus-4-5    # Specific model` | **KEEP** | (no change) | A `--help`/"Useful Flags" reference illustrating the `--model` FLAG SYNTAX. `opus-4-5` is an arbitrary field-value EXAMPLE, not a model-setting that routes work. Matches the sonnet-kill KEEP class: "docs listing model names as field-value examples." |

**Also surfaced (NOT an opus-4-6/4-5 drift hit, KEPT):**
- `.claude/agents/local-llm.md:5` `model: claude-haiku-4-5-20251001` — **KEEP**. This is the deliberate cheap-LLM agent; haiku is its purpose. This is a model-drift fix for stale opus-4-6/4-5, NOT a "force everything to opus" sweep. (The `--model deepseek-r1:14b` on line 41 is a local-Ollama call, also correct.)

**Counts: 4 KILL → opus-4-8[1m] (×2) / opus-4-8 (×2); 2 KEEP (cc-mastery flag-example + local-llm haiku frontmatter).**

### settings.json precedence — VERIFIED (the "don't add a 3rd unverified interaction" gate)
- Main-session model is driven by `tools/launch_civ_tower.sh:100`, which sets `--model 'claude-opus-4-8[1m]'` explicitly (the sonnet-kill fix on the parent branch). The `--model` LAUNCH FLAG wins over the `ANTHROPIC_MODEL` env for tower launches.
- There is NO `.claude_session_model` file in the template (that is a TB-local artifact, not shipped in the genome) → no third competing source.
- Subagent model has NO overriding flag → `CLAUDE_CODE_SUBAGENT_MODEL` env was the sole authority and was the genuinely-stale one. Fixed.
- Net: launcher flag (opus-4-8[1m]) and both settings.json envs (opus-4-8[1m]) now AGREE. The `ANTHROPIC_MODEL` edit aligns the fallback with the launcher rather than introducing a conflict.

**Files changed (#2):** `.claude/settings.json`, `.claude/skills/conductor-of-conductors/SKILL.md`, `.claude/skills/agent-creation/SKILL.md`.

---

## Proposal #3 — SKILLS-REGISTRY SEED

**Problem (ground-truth):** `memories/skills/registry.json` shipped as `{"skills": {}}` (118 bytes) while **142** `.claude/skills/*/SKILL.md` exist on disk. The constitution MANDATES a pre-task skills grep against this file (`grep -i "KEYWORD" registry.json`) — for every newborn that grep returned NOTHING. Mandated discipline dead-on-arrival.

**`skill_tracker.py` assessment:** Inspected. It tracks skill INJECTIONS (usage logging, JSONL) and has a `list_available_skills()` helper for its audit — but it does NOT seed `registry.json` from frontmatter. Different concern. Left untouched; wrote a dedicated seeder instead.

**New tool:** `tools/seed_skills_registry.py` — idempotent provision-time seeder.
- Parses every `.claude/skills/*/SKILL.md`. Canonical key = parent directory name (collision-proof).
- Extracts `name` + `description` from YAML frontmatter when present (handles single-line AND block/folded `|`/`>` scalars); falls back to dir-name + first H1/content-line for the **16** SKILL.md files that ship without YAML frontmatter.
- `--check` dry-run mode; idempotent (re-run regenerates from current disk).

**Result:** Seeded registry.json from **0 → 142 skills**. 44,146 bytes (was 118). Valid JSON. **0 empty descriptions.** Mandated keyword grep verified working (e.g. `grep -i calendar` now returns real entries).

**Provision-time wiring — DECISION-NEEDED (see below):** The file is POPULATED now (works today for any newborn). Making it auto-run at provision would require hooking either `civ/tools/civos_bootstrap.py` (an F4-tainted file — off-limits this run) or the SEEDED WAKE-UP PROTOCOL in `.claude/CLAUDE.md` (a constitutional doc — AUDITOR-GATE applies, out of this task's scope). Shipped as a standalone idempotent tool + populated file; provision-hook deferred to Corey.

**Files changed (#3):** `memories/skills/registry.json` (seeded). **Added:** `tools/seed_skills_registry.py`.

---

## F4 — CONFIRMED UNTOUCHED

`git diff --name-only` on this branch lists ONLY:
- `.claude/settings.json`
- `.claude/skills/agent-creation/SKILL.md`
- `.claude/skills/conductor-of-conductors/SKILL.md`
- `memories/skills/registry.json`

The F4 files — `civ/tools/civos_bootstrap.py` (PureBrain UUID `e7830968-…`), `.claude/hooks/ceo_mode_enforcer.py` (6 fleet IPs), `provision_docker_host.py`, `schedule_7day_wow.py` — were NOT modified (empty diff-stat verified). The baked secrets were left exactly as found. F4 is Corey's call.

---

## DECISION-NEEDED for Corey

1. **#3 provision auto-hook**: register `seed_skills_registry.py` to run at provision. The clean hook point is either an F4-tainted file or a constitutional doc (both gated this run). Want it wired into the wake-up protocol next (with the AUDITOR-GATE), or is the populated-file-plus-standalone-tool sufficient?
2. **#2 `ANTHROPIC_MODEL` belt-and-suspenders**: kept it aligned to the launcher (`opus-4-8[1m]`). If you prefer settings.json to carry NO main-session model (launcher-only authority), say so and I'll drop the `ANTHROPIC_MODEL` line instead.
3. **cc-mastery flag-example (hit #5)**: KEPT as an illustrative `--model` syntax example. If you'd rather it not show a stale `opus-4-5` value at all, I can refresh the example to a current model id (it's cosmetic, not a routing setting).
