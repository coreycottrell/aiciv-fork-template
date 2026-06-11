# Genome Fix: Kill Sonnet Model-Defaults → Opus 4.8 (2026-06-11)

**Branch**: `sonnetkill-20260611`
**Repo**: `coreycottrell/aiciv-fork-template`
**Authorized by**: Corey, 2026-06-11
**Executed by**: True Bearing Infrastructure VP (incarnated)
**Total files changed**: 132 (152 insertions / 152 deletions)

---

## Why This Matters (The Genome Bug)

Every newborn AiCIV is forked from THIS template. The template's `model:` defaults were
still pointing at **Sonnet** in two layers:

1. **The main-session launcher** (`tools/launch_civ_tower.sh:100`) booted every newborn's
   PRIMARY Claude session on `claude-sonnet-4-6` — which is **200K-context-capped** and the
   wrong model floor. This is the headline bug: the env-pin (`[1m]`) could not override a
   hardcoded `--model` on the launch command, so the tower booted on Sonnet regardless.

2. **~117 agent manifests + spawn-example templates** carried `model: sonnet` /
   `model: claude-sonnet-4-5-20250929` / `model: claude-sonnet-4-6` in frontmatter and in
   the copy-paste spawn snippets that every new agent/fork inherits.

**Corey's directive (standing, from the local TB sweep 2026-06-11):** "minimum model to use
right now is opus 4.8." This change makes the template's genome default to that floor.

---

## THE LAUNCHER FIX (most important single line)

**`tools/launch_civ_tower.sh:100`**

```diff
-tmux send-keys -t "${SESSION_NAME}" "claude --model claude-sonnet-4-6 --dangerously-skip-permissions '${CLAUDE_PROMPT}'" C-m
+tmux send-keys -t "${SESSION_NAME}" "claude --model 'claude-opus-4-8[1m]' --dangerously-skip-permissions '${CLAUDE_PROMPT}'" C-m
```

Note the **`[1m]` suffix** — this is intentional and applies ONLY to the main-session
launcher. The `[1m]` suffix unlocks the 1M-context window for the Primary session; without
it Claude Code caps at ~200K → early-session thrashing/OOM (Witness P0 canon). The suffix is
proven ONLY for the main-session launch flag, NOT for subagent frontmatter (see KILL-vs-KEEP).

---

## KILL Categories (what changed → opus)

### 1. Agent manifest frontmatter — 117 files (the routing layer)
- `.claude/agents/*.md` (112 files) + `.claude/agents/dev-team/*.md` (5 files)
- Frontmatter `model:` lines normalized to `model: claude-opus-4-8`:
  - `model: sonnet` → `model: claude-opus-4-8`
  - `model: claude-sonnet-4-5-20250929` → `model: claude-opus-4-8`
  - `model: claude-sonnet-4-6` → `model: claude-opus-4-8` (architect.md, koan.md, meta-cognition.md)
- **No `[1m]` suffix on frontmatter** — that suffix is proven only for the main-session
  launcher, not subagent frontmatter.

### 2. Prose `**Model**:` headers inside manifests
- plugin-sensei, ai-entity-player, skills-master, tg-bridge, tg-archi, flow-coordinator,
  counsel: `**Model**: claude-sonnet-4-5-20250929` → `**Model**: claude-opus-4-8`
- health-auditor.md:1190 `**Model**: Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)` →
  `**Model**: Claude Opus 4.8 (claude-opus-4-8)`
- email-monitor.md:286 `*Model: sonnet-4*` → `*Model: claude-opus-4-8*`
- skills-master.md:138 model-override example → `claude-opus-4-8`

### 3. Agent-creation TEMPLATES (propagate to every NEW agent born from the template)
- `agents/README.md:19` `model: "claude-sonnet-4-5-20250929"` → `"claude-opus-4-8"`
- `agents/spawner.md:196` `default to claude-sonnet-4-5-20250929` → `default to claude-opus-4-8`
- `agents/agent-architect.md:267` `model: sonnet` → `model: claude-opus-4-8`
- `skills/agent-creation/SKILL.md:124,231,338,486` `claude-sonnet-4-20250514` (default) →
  `claude-opus-4-8`

### 4. Spawn-example lines (Task() / agent() snippets newborns copy)
- `CLAUDE-OPS.md:38,208` `model="sonnet"` / `model: "sonnet"` → `claude-opus-4-8`
- `CLAUDE-TEAMS.md:116` `model="sonnet"` → `model="claude-opus-4-8"`
- `hooks/session_start.py:243` printed spawn instruction `model='sonnet'` → `model='claude-opus-4-8'`
- `team-leads/README.md:81`, `team-leads/dev/README.md:183` `model="sonnet"` → `claude-opus-4-8`
- skills `primary-spine:303`, `evening-capture:137`, `verify-publish:114,210`,
  `team-launch:52`, `daily-blog:111` (+inline comment) `model="sonnet"` → `claude-opus-4-8`

### 5. Live launch / API / fork-launch
- `tools/launch_civ_tower.sh:100` — **THE LAUNCHER** → `claude-opus-4-8[1m]` (see above)
- `skills/fork-readiness-test/SKILL.md:34,593` fork-launch flag `--model claude-sonnet-4-6`
  → `--model 'claude-opus-4-8[1m]'` (main-session fork launch → matches launcher, keeps `[1m]`)
- `skills/bluesky-blog-thread/SKILL.md:278` live Messages-API `model="claude-sonnet-4-20250514"`
  → `model="claude-opus-4-8"`
- `skills/agent-teams-orchestration/SKILL.md:99,218,248` "Use Sonnet for teammates to save
  costs" prose → "Use Opus 4.8 for teammates (minimum floor)"

---

## KEEP (deliberately NOT touched) + rationale

These 5 hits remain by design — they are NOT model-settings that route work to Sonnet:

| File:Line | Text | Why KEEP |
|-----------|------|----------|
| `team-leads/tgim/manifest.md:82` | "Team leads = Opus ONLY. NEVER Sonnet." | **Avoid-instruction** — flipping it would invert a correct rule. |
| `skills/deep-research/SKILL.md:182` | "Use haiku — Opus/Sonnet hang on complex WebFetch" | **Descriptive**, routes AWAY from sonnet. |
| `skills/deep-research/SKILL.md:405` | "Use haiku model: Opus/Sonnet hang on web ops" | Same — descriptive, not a setting. |
| `skills/cc-conversation/SKILL.md:159` | `model_filter="claude-sonnet-4-5"` | **Search filter** over past session logs, not a model selection. |
| `skills/cc-conversation/SKILL.md:294` | `"model": "claude-sonnet-4-5-20250929"` | **Example JSONL log data** (sample of what a log record looks like). |

---

## KILL-vs-KEEP Classifier (the rule applied)

**KILL** = anything that SETS the model an agent/session will actually run on:
frontmatter `model:`, `--model` launch flags, `model=`/`model:` spawn-snippet kwargs,
prose `**Model**:` identity headers, template defaults that propagate to new agents.

**KEEP** = anything that mentions "sonnet" WITHOUT selecting it for work:
avoid-instructions ("NEVER Sonnet"), descriptive routing notes ("Opus/Sonnet hang, use
haiku"), search/log filters over historical data, example log records.

This mirrors True Bearing's local sweep precedent (2026-06-11): a blind grep-replace would
have wrongly flipped the 5 KEEP items; a blind "trust the template" assumption would have
missed the launcher. **Verify-not-trust: read each context before classifying.**

---

## Verification (post-change)

```
grep -rn -E '^model:[[:space:]]*(sonnet|claude-sonnet)'  → 0 hits
grep -rn -E "model[=:][[:space:]]*[\"']sonnet"            → 0 hits
grep -rn -- '--model claude-sonnet'                       → 0 hits
```

All Sonnet MODEL-SETTINGS eliminated. Only the 5 documented KEEP items
(avoid-instructions / filters / example-data) remain — which is correct.
