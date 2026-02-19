# Team Lead Templates

## THE TEAM RULE (Corey Directive 2026-02-10)

> **If it CAN be done by a team, it MUST be done by a team. PERIOD.**

This is not a suggestion. This is a context distribution mandate. Primary's context window is for orchestration and human dialogue -- NOT for absorbing agent work output. Every team lead keeps its specialists' output in ITS context, returning only a summary to Primary.

**Before calling Task(agent-id) directly, ask: "Does a team lead exist for this domain?"**
- YES -> Use the team lead. Always. No exceptions. No rationalizing.
- NO -> Direct delegation is acceptable. Consider whether a new team lead vertical is needed.

**Why this is exponential:** 6 specialists through a team lead = ~500 tokens back to Primary. 6 specialists directly = ~15,000+ tokens flooding Primary. That's 30x context savings per mission. Over a session, this compounds into the difference between orchestrating 5 tasks and orchestrating 50.

---

## What Is a Team Lead?

A team lead is a **mini-conductor** -- an ephemeral agent that orchestrates a roster of specialists for a focused domain. Team leads do not DO work directly; they delegate via `Task()` calls, synthesize results, and report back.

Team leads are:
- **Ephemeral**: They exist only during an Agent Team session, then vanish
- **Template-assembled**: Primary constructs their prompt from a template file + objective + prior scratchpad
- **Domain-focused**: Each team lead knows only its vertical's agents, skills, and context
- **Sub-conductors**: They follow the same conductor pattern as Primary, but for a single domain

Team leads do NOT have registry entries. They are assembled on-demand from these templates.

## How Primary Spawns a Team Lead

### Step 1: Decide if a Team Lead Is Needed

| Scenario | Action |
|----------|--------|
| Single agent task | `Task(agent-id)` directly -- no team lead |
| 2-3 agent sequential pipeline | Primary orchestrates directly |
| 4+ agents in a domain-focused project | **Spawn a team lead** |
| Cross-domain work | **Multiple team leads** as teammates |

### Step 2: Construct the Prompt

Primary reads the template file and appends the objective:

```
prompt = [contents of .claude/team-leads/{vertical}.md]
       + "\n## Current Objective\n" + task_description
       + "\n## Output Paths\n" + file_paths_for_deliverables
       + "\n## Prior Work\n" + scratchpad_content_if_any
```

### Step 3: Spawn as Teammate or Subagent

**As a subagent** (common case -- cheaper, fire-and-forget):
```
Task({
  subagent_type: "general-purpose",
  prompt: constructed_prompt,
  description: "Gateway team lead: implement dark mode",
  model: "opus"
})
```

**As a teammate** (when inter-lead coordination is needed):
```
Task({
  team_name: "project-name",
  name: "gateway-lead",
  subagent_type: "general-purpose",
  prompt: constructed_prompt,
  model: "opus",
  run_in_background: true
})
```

### Step 4: Monitor and Synthesize

- Subagent: returns result directly when complete
- Teammate: sends messages, writes scratchpad; Primary reads and synthesizes

## Cost Guidance

| Approach | Context Cost | When to Use |
|----------|-------------|-------------|
| Direct `Task(agent)` | 1 Sonnet context | Single-agent, clear task |
| Primary orchestrates 2-3 agents | 2-3 sequential contexts | Simple pipeline |
| **Team lead as subagent** | 1 Opus + 3-5 Sonnet | **4+ agents, one domain** |
| **Team lead as teammate** | 1 persistent Opus + subagents | **Parallel with other leads** |
| Multiple team leads | N Opus + subagents each | Cross-domain complex project |

**Key insight:** A team lead as subagent (who then uses Task() internally) is cheaper than spawning multiple teammates, because Task() subagents are sequential and fire-and-forget, not persistent parallel contexts.

**Model selection:**
- Team leads: **Opus** (they make routing and synthesis decisions)
- Their specialist subagents: inherit from agent registry (usually Sonnet)
- Cost-sensitive, well-defined tasks: Sonnet for the team lead is acceptable

## Available Verticals

| Vertical | File | Domain | Key Agents |
|----------|------|--------|------------|
| **Gateway** | `gateway.md` | AICIV gateway product | coder, web-dev, tester, reviewer, ux-specialist, koan |
| **Web/Frontend** | `web-frontend.md` | All web properties | web-dev, ux-specialist, coder, tester, reviewer, nexus-keeper |
| **Legal** | `legal.md` | Legal analysis across jurisdictions | counsel + 12 specialist lawyers |
| **Research** | `research.md` | Multi-angle research and analysis | researcher, compass, chart-analyzer, integration-verifier, primary-helper |
| **Infrastructure** | `infrastructure.md` | VPS ops, system health, platform | vps-instance-expert, tg-archi, performance-monitor, mcp-expert, coder |
| **Business** | `business.md` | Marketing, outreach, content | marketing, consulting-ops, arcx-biz-dev-mngr, blogger, bsky-voice, human-liaison |

## Permission Requirements

Team leads need their specialists to have full tool access. Ensure `settings.json` includes:

```json
{
  "permissions": {
    "allow": [
      "Write *",
      "Edit *",
      "Bash *"
    ]
  }
}
```

Without these permissions, specialist agents called via Task() will be blocked from writing files, editing code, or running commands.

## Scratchpad Convention

Each team writes to its own scratchpad:

```
.claude/scratchpads/team-{vertical}-{date}.md
```

Examples:
- `.claude/scratchpads/team-gateway-20260210.md`
- `.claude/scratchpads/team-web-20260210.md`
- `.claude/scratchpads/team-web-20260210-dark-mode.md` (multiple tasks same day)

**Critical rule**: NEVER use Write to update scratchpads mid-session -- use Edit (surgical append). Write = full overwrite = loses prior state.

## Artifact Output Protocol

When team leads or their agents produce rich output (reports, HTML, code), they should use `<artifact>` tags so the content renders in the gateway's artifact preview panel.

Full protocol: `artifact-protocol.md`

This enables:
- Research reports appearing as readable documents in the artifact panel
- HTML/CSS/JS being rendered as live previews
- Code being displayed with syntax highlighting
- All of this working universally for ANY AICIV using this gateway

## Architecture Reference

Full architecture document: `exports/architecture/VERTICAL-TEAM-LEADS.md`

This covers:
- Template structure specification (Section 1)
- All six vertical definitions with rosters and skills (Section 2)
- Spawn protocol details (Section 3)
- Memory bridge pattern (Section 4)
- Scratchpad lifecycle (Section 5)
- Scaling considerations and cost analysis (Section 6)
