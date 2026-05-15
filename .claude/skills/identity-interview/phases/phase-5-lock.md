---
phase: 5
parent_skill: ../SKILL.md
name: phase-5-lock
description: Lock 3 chosen WOW BUILDS + author spec sheets + game plans + commit first build shipped within 72h. Terminal phase. Schedule build #1 via AgentCal with prompt_payload carrying the spec. .identity-interview-complete/ marker lands here.
version: 0.2.0
authored: 2026-05-13
loads_on: marker .wow-preferences-captured/ present AND .identity-interview-complete/ absent
completion_marker: memories/identity/.identity-interview-complete/
content_artifact: memories/identity/wow-builds-locked.md
shape_artifact: memories/identity/wow-builds-shape.md
shape_consultation_eligible: false
# Phase 5 uses already-consulted shapes from Phase 2 + 4; no fresh consultation fires.
72h_handoff_target: Witness fleet-lead (per memories/identity/72h-verification-shape.md)
---

# Phase 5 — Lock 3 chosen + commit to first-build-shipped within 72h

## Completion signal

${HUMAN_NAME} has chosen 3 WOW BUILDS. ${CIV_NAME} has authored a spec sheet + full game plan for each. The FIRST build is scheduled via AgentCal `prompt_payload` to ship within 72 calendar hours. ${HUMAN_NAME} explicitly commits: "yes, ship build #1 within 72 hours." Marker `.identity-interview-complete/` lands. Sticky-loading stops.

## Conversational shape

1. **Re-anchor from Phase 4 preferences**:
   *"${HUMAN_NAME}, looking at where we landed in Phase 4, here's my read on the 3 builds to lock — ranked by daily-use × goal-advancement, after only-with-AI license. Let's confirm or swap."*

2. **Propose 3 locked builds** from Phase 4 preferences:
   - Ranked by daily-use × goal-advancement (parent Part 8 SCORING)
   - All 3 pass only-with-AI LICENSE (parent Part 8 STAGE 1)
   - Customer-as-eye fires per build: *"each one of these still feels load-bearing?"*

3. **${HUMAN_NAME} confirms / amends / swaps**. ${CIV_NAME} accepts amendments. Discovery belongs to the user.

4. **For EACH locked build, ${CIV_NAME} authors**:
   - **Spec sheet** (what it is in ${HUMAN_NAME}'s language; what capability it draws on; what the first-shipped artifact looks like; success criterion)
   - **Full game plan** (concrete steps; ${CIV_NAME}'s autonomous work + ${HUMAN_NAME}'s checkpoints; expected fire-window)

5. **Schedule build #1 in AgentCal**:
   - `prompt_payload` carries the spec sheet (the AiCIV self-fires when the event triggers)
   - Target `start_time`: ≤ 72h from `.identity-interview-complete/` marker timestamp
   - Calendar metadata is shape-class (cross-grade-eligible); the payload is content-class (membrane-private)

6. **Schedule builds #2 + #3** for days 3-7. They supplement (not replace) the 7-day-wow Day-N themes — see research-baseline.md §3 integration table.

7. **${HUMAN_NAME} explicitly commits**: *"yes, ship build #1 within 72 hours."* The verbal commitment is the close; ${CIV_NAME} acknowledges back: *"locked. I'll ship #1 by [timestamp+72h]. You'll see it land — I'll surface it to you when it does."*

8. **Marker lands**: `.identity-interview-complete/` is created via mkdir-atomic. Sticky-loading stops. Interview is DONE.

## Artifacts produced (structural membrane split — Hengshi #4)

### CONTENT path (NEVER cross-graded — structurally unreachable)

**`memories/identity/wow-builds-locked.md`** — 3 spec sheets + 3 game plans in ${HUMAN_NAME}'s domain language, including user-context, references to private goal-content, ${HUMAN_NAME} phrasings throughout. Membrane-private.

```markdown
# WOW Builds locked — ${HUMAN_NAME}

## Build #1: ${BUILD_NAME}

**Spec**: (in ${HUMAN_NAME}'s domain language, including user-context)
${SPEC_TEXT}

**Game plan**:
- Step 1: ${STEP} (owner: ${CIV_NAME}, expected window: ${WINDOW})
- Step 2: ...
- ${HUMAN_NAME} checkpoints: ${CHECKPOINTS}
- First-shipped artifact: ${ARTIFACT_DESCRIPTION}
- Success criterion: ${CRITERION}
- AgentCal event ID: ${EVENT_ID}

## Build #2: ...

## Build #3: ...
```

### SHAPE path (cross-grade-eligible)

**`memories/identity/wow-builds-shape.md`** — per-build calibration metadata:

```yaml
build_1:
  capabilities_used: [${ABILITIES}]      # subset of TOP-8
  daily_use_score: high / med / low
  goal_advancement_score: high / med / low
  only_with_ai_license: pass / fail      # binary
  capability_theater_risk: low / med / high
  first_ship_eta_hours: ${HOURS}         # ≤72
  agentcal_event_id: ${EVENT_ID}         # references calendar event
  shape_consultation_verdict_phase4: ${VERDICT_OR_NULL}
build_2: {...}
build_3: {...}
```

NEVER contains spec text, game-plan text, or user phrasings.

### AgentCal events (3 scheduled)

- Build #1: `start_time` ≤ marker_timestamp + 72h, `prompt_payload` contains the spec sheet (CONTENT path lives in the payload — but the calendar event itself surfaces only the build name + start_time as shape-class metadata)
- Build #2: `start_time` in days 3-7 window
- Build #3: `start_time` in days 3-7 window

## Marker creation (TERMINAL)

```bash
if mkdir "memories/identity/.identity-interview-complete" 2>/dev/null; then
  echo "phase=5 completed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    > "memories/identity/.identity-interview-complete/receipt.txt"
  echo "Interview complete. Sticky-loading stops. Build #1 scheduled within 72h." \
    >> "memories/identity/.identity-interview-complete/receipt.txt"
fi
```

Then verify:
- `[ -s memories/identity/wow-builds-locked.md ]`
- `[ -s memories/identity/wow-builds-shape.md ]`
- 3 AgentCal events scheduled (verify via AgentCal API per FIRING_CONTRACT verification script)
- First event `start_time` ≤ marker_mtime + 72h

If ANY check fails, marker is renamed `.identity-interview-complete-MISS-${TIMESTAMP}` and skill re-fires next session (per FIRING_CONTRACT.md final verification).

## Hand-off to Witness fleet-lead (Corey Q8 — v0.2 NEW)

Once `.identity-interview-complete/` lands, the 72h verification window opens. Witness fleet-lead is the verifier (per `memories/identity/72h-verification-shape.md`).

${CIV_NAME} signals Witness fleet-lead via the Hub or AgentMail:

```
Subject: [72h-verification-handoff] identity-interview complete — civ ${CIV_NAME}

${CIV_NAME} has completed identity-interview for ${HUMAN_NAME} at ${MARKER_TIMESTAMP}.
Build #1 scheduled for ${BUILD_1_START_TIME} (≤72h from marker).

Per memories/identity/72h-verification-shape.md, please run verification at hour 72:
  - marker existence check
  - artifact validity check (CONTENT + SHAPE present + non-empty)
  - build-shipped-on-time check (build #1 actually fired + produced artifact)
  - structural-membrane audit (no CONTENT-path references in cross-grading-ledger)

Verdict back to ${CIV_NAME} within 6h of hour-72 mark.
```

## Phase-5-specific anti-patterns

- ❌ **First-build > 72h calendar**: if ${HUMAN_NAME}-chosen build #1 truly requires >72h, ${CIV_NAME} surfaces back: *"this is great as build #2 or #3 — what's a simpler version we could ship inside 72h that proves the direction?"* Re-enter Phase 5 with revised candidate. The 72h-first-build is the proof of the retention thesis — do not compromise it.

- ❌ **Spec sheet vague**: spec sheet that reads "ship something cool toward the goal." NO. Concrete: "by Friday 7am, ${HUMAN_NAME}'s inbox receives a 2-page brief titled X containing Y and Z." Vague specs fail verification.

- ❌ **AgentCal payload empty / placeholder**: scheduling a calendar event whose `prompt_payload` is "TODO" or empty. The payload IS the self-prompting substrate — without substantive content, the AiCIV self-fires into nothing.

- ❌ **Phase 5 fires shape-consultation**: NO. Phase 5 uses already-consulted shapes from Phase 2 + Phase 4. A fresh Phase 5 consultation = the calibration was unstable through Phase 4 = revisit Phase 4, not patch in Phase 5.

- ❌ **Commit-without-verbal**: ${HUMAN_NAME} nods but never says "yes, ship build #1 within 72 hours." The verbal commitment is the close — without it, the goal is consumed not authored. Surface plainly: *"can you say yes to that — shipping build #1 in 72 hours?"*

- ❌ **Schedule-and-walk-away**: ${CIV_NAME} schedules the 3 events but never surfaces back to ${HUMAN_NAME} when build #1 ships. The shipping of build #1 IS the conversion event — ${CIV_NAME} surfaces it: *"${HUMAN_NAME}, build #1 just shipped. Here it is. Did it land?"*

- ❌ **Marker lands with INCONSISTENT state**: marker created but artifact missing/empty, or no AgentCal events scheduled, or first event >72h. The terminal marker is special — its existence promises substrate-completeness. Verification per FIRING_CONTRACT.md is mandatory.

## What happens after `.identity-interview-complete/`

- Sticky-loading stops. The skill does NOT auto-load on next session start.
- ${HUMAN_NAME}-${CIV_NAME} pair has substrate: biggest goal (private) + 90-day goal (private) + skill shortlist (federation) + WOW build preferences (shape) + 3 locked builds (private content + cross-grade-eligible shape).
- Build #1 fires within 72h. Builds #2 + #3 fire in days 3-7.
- Witness fleet-lead verifies at hour 72 per `72h-verification-shape.md`.
- The retention thesis is now under test: did ${HUMAN_NAME} get "sucked in" (built artifact tied to personal goal in 72h) or fall off (treated as expensive ChatGPT)?

---

*Phase 5 is the conversion event. The interview becomes a built artifact. ${HUMAN_NAME} commits verbally; ${CIV_NAME} commits structurally (AgentCal event scheduled, prompt_payload carrying the spec). The 72h proof window opens. The retention thesis is the active hypothesis under test from this moment on.*
