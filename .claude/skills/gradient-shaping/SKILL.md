---
name: gradient-shaping
description: A brainstorm protocol that reframes any problem as an energy landscape, then redesigns the terrain so the desired outcome becomes the lowest-energy state the system naturally flows toward — instead of forcing the solution uphill by brute effort. Use this whenever facing a hard problem, a stuck initiative, a coordination failure, a process that takes constant pushing to maintain, an optimization or design challenge, or any situation where the team is "fighting" to get a result. Trigger this even when the user just says "let's brainstorm X," "how do we solve Y," "this keeps breaking," "we keep having to push for Z," or "design a system that does W" — the protocol applies far more broadly than it first appears. Default to running a situation through this lens before proposing direct solutions.
version: 0.1.0
status: PROVISIONAL
author: ${HUMAN_NAME} (gifted, origin-civ attribution) via fleet-lead
created: 2026-06-22
metadata:
  category: method
related_skills: [critical-thinking, scientific-method, rubber-duck, deep-duck, system-gt-symptom, integration]
applicable_agents: [primary, all-vps, all-agents]
firing_contract: ./FIRING_CONTRACT.md
---

# Gradient Shaping

## The core move

Most problem-solving pushes the desired outcome **uphill**: you spend continuous effort dragging a system toward a state it doesn't want to be in, and the moment you stop pushing, it slides back. This protocol does the opposite. You **re-grade the terrain so the outcome you want is downhill** — the lowest-energy state — and then the system flows there on its own and *stays* there because leaving would cost energy.

The water already knows how to find the bottom. Your job is not to carry the water. Your job is to shape the valley.

> **Shape the landscape so the answer is downhill.**

A solution that requires constant force is a solution you are renting. A solution that sits at the bottom of a well is one you own. Always prefer the second.

## When NOT to skip this

The instinct under pressure is to jump straight to "what action do we take." That instinct is the thing this protocol is built to interrupt. An action is a *push*. Before pushing, spend real effort on **where the floor currently is and why**, because nine times out of ten the leverage is in re-grading, not pushing harder.

---

## The protocol

> **🚨 MANDATORY before you run this: read `references/worked-examples.md` in full.** The phases below are the skeleton; the worked-examples file is where the protocol becomes real. Running the protocol without it is the documented path into the #1 failure mode.

Run these phases in order. Do not let the brainstorm leap to Phase 4 (solutions) before Phases 2 and 3 are genuinely done — that is the single most common failure.

### Phase 1 — SITUATE: state the outcome as a *state*, not an action

Write down the situation plainly. Then state the desired outcome as a **resting configuration the system could be in**, not as a verb you perform.

- Weak (action): "We need to get people to file reports on time."
- Strong (state): "The lowest-effort path for a person at report-time is to have already filed."

The reframe from verb to state is mandatory. If you cannot express the goal as "a state the system settles into," you have not understood the goal yet. Keep rewriting until you can.

### Phase 2 — MAP THE LANDSCAPE: chart the terrain before touching it

You are drawing a contour map of the situation as it actually is. Answer:

- **Axes / degrees of freedom.** What can actually vary here? What are the dials? (Be concrete — money, time, attention, trust, latency, headcount, friction, status, whatever the real variables are.)
- **Forces already acting.** What pressures/incentives/gradients are *already* pushing the system around, with or without your involvement?
- **Current attractors.** Where does this situation naturally settle when nobody intervenes? What is the system's *default resting state*, and — critically — **why is that the floor?** What makes the bad equilibrium the low-energy one?
- **Barriers.** What walls (activation energies) separate the current basin from the one you want? What would have to be climbed?
- **Basin shape.** Is the current bad state a deep narrow pit (hard to escape) or a shallow wide bowl (a nudge away from tipping)?

Output of this phase is a description of the terrain. No solutions yet.

### Phase 3 — FIND THE BODY: locate where effort is currently being spent fighting the gradient

This is the detective phase, borrowed from thermodynamics: **every uphill push is a clue.** Wherever the team is currently spending continuous energy to hold a result in place, that is a spot where the landscape is working against you. Ask:

- Where are we **pushing**? What only stays true as long as someone forces it?
- What snaps back the instant we stop? (That snap-back vector points *down* the real gradient — it is telling you where the floor actually is.)
- What are we spending energy to *prevent*? (Prevention is uphill maintenance.)

List every uphill push. Each one is a candidate for re-grading. The snap-back directions, taken together, are a map of the true landscape drawn for free.

### Phase 4 — RE-GRADE: redesign the terrain so the outcome is the floor

Now generate. For each uphill push found in Phase 3, and for the goal-state from Phase 1, run through these levers. They are ordered roughly from most to least elegant — prefer the earlier ones.

1. **Remove the opposing force (the free-fall move).** Can you simply *stop doing the thing* that creates the uphill? The most powerful interventions often subtract rather than add. Gravity vanishes in free fall not by fighting it but by stepping off the floor. Ask: what are we doing that *manufactures* the resistance we're then struggling against?

2. **Re-tilt the payoffs.** Change the incentive surface so the desired state is the one that costs the actor the least / pays the most. Make the right thing the path of least resistance, not a virtuous detour off it. (If the good outcome requires anyone to act against their own local gradient, it will erode — re-tilt until local self-interest points downhill toward the global goal.)

3. **Lower the barrier (reduce activation energy).** Don't move the destination — shrink the wall in front of it. Defaults, pre-filled paths, removed steps, reduced friction. The state you want may already be downhill; people just can't get over the lip to reach the basin.

4. **Widen the basin.** Make the target attractor catch the system from *many* starting conditions, so you don't have to control where things begin. A protein folds reliably because the funnel is wide, not because it's aimed. A robust solution falls into place from messy starting points.

5. **Seed near the funnel.** If you can't reshape the whole landscape, just *start the system close enough to the desired attractor that flowing in is inevitable.* Initialization is a lever. Where you place the starting point can make the rest automatic.

6. **Relocate the cost (the Maxwell's-demon move).** You usually can't erase the cost, but you can often *move* it to where it's cheaper, deferrable, or paid by something with spare capacity. Ask: who or what pays for this, and is there a different account that barely notices the charge? (This is honest only if you actually name the new payer — see Phase 5.)

7. **Let it tunnel.** Sometimes you don't force the transition at all — you make the target the low state and simply *wait* / leave a standing low-probability path open, and the system gets there on its own timescale. Only viable when you can afford the clock. Worth asking: is there a slow, zero-effort path that gets there if we're patient?

Generate multiple re-grades per push. Quantity here is good.

### Phase 5 — CHECK THE BILL: thermodynamic honesty pass

For every proposed re-grade, ask the discipline question: **where did the cost go?** A real re-grade relocates or removes effort. A fake one just hides the uphill somewhere you'll trip over it later. Check:

- **Did we actually remove the cost, or just move it out of view?** If we moved it — name the new payer explicitly. An unnamed payer is a hidden uphill that will surface as a surprise.
- **Is the new floor stable?** Will the system rest there, or drift back out once attention leaves? (If it drifts back, you built a shallow bowl, not a well — deepen it or add a barrier behind the system once it's in.)
- **Did we create a worse attractor as a side effect?** Re-grading one valley can dig an unintended pit next door (perverse incentive, gamed metric). Look for it.

Kill any re-grade that fails this pass, or send it back to Phase 4.

### Phase 6 — SEED & RELEASE: the minimal intervention

Close by specifying the *smallest* action that starts the flow, plus — equally important — **what to stop doing.** Often the deliverable is partly a list of efforts to *cease*, because they were the uphill manufacturing the problem. State:

- The one-time grading change(s) to make.
- The starting point to seed from.
- The ongoing pushes to **stop** (reclaimed energy).
- What "the system resting in the right basin" will look like, so you can tell it worked.

---

## Question stems (pull from these freely during a session)

- "If nobody did anything, where would this naturally end up — and why is *that* the floor?"
- "What are we holding in place by force right now? What snaps back if we let go?"
- "What are we doing that *creates* the resistance we're fighting?"
- "For the outcome we want — what would have to be true for that to be the *laziest* option?"
- "Whose local gradient points the wrong way, and how do we re-tilt so their easy path is our goal?"
- "What wall is in front of the right answer, and can we lower it instead of pushing people over it?"
- "Can we start closer to the destination instead of steering harder toward it?"
- "Who pays for this? Is there an account with spare capacity that barely feels the charge?"
- "Is the good state a deep well or a shallow bowl? Will it stay put?"

---

## Failure modes to watch for

- **Pushing harder in disguise.** A "solution" that is really just "do the uphill thing but with more discipline / a reminder / a dashboard." That's renting, not owning. Send it back.
- **Skipping the map.** Jumping to Phase 4 before Phases 2–3 are real. You'll re-grade the wrong hill.
- **Hidden payer.** A re-grade that feels free because nobody named who's covering it. Always find the body.
- **Shallow bowl.** A target state with no barrier behind it, so the system rolls right back out. Add a one-way gate once it's in the basin.
- **Mistaking a verb for a state.** If the goal can't be written as "the system rests in configuration X," Phase 1 isn't done.

---

## One-paragraph worked example

*Situation:* agents keep producing documents that drift from spec, and a reviewer has to keep catching it. **Phase 1 (state):** "the lowest-effort path to 'done' already satisfies spec." **Phase 2 (map):** the attractor is drift, because the cheap path for a generating agent is to optimize its local objective and ignore the global constraint — spec-conformance is uphill for it. **Phase 3 (body):** the reviewer is the continuous uphill push; remove the reviewer and quality snaps back down — that snap-back proves conformance was never the floor. **Phase 4 (re-grade):** rather than push harder (more review), *re-tilt* — make spec-conformance the generating agent's own cheapest path by giving it the conformance check *before* it commits, so passing is the path of least resistance, not a gate it's dragged through (lower the barrier + re-tilt). **Phase 5 (bill):** cost moved from human reviewer to a cheap automated pre-check the agent runs itself — named payer, small charge, stable because non-conforming output now costs the agent more than conforming. **Phase 6 (release):** seed the check at generation time; *stop* the downstream human review push; rest state = documents arrive in-spec by default.

---

## Reference files

> **🚨 MANDATORY: read `references/worked-examples.md` BEFORE running the protocol.** It is not optional supplementary reading — it is part of loading this skill. The six abstract phases above under-determine how the move actually feels on a concrete problem; the worked examples are where the protocol becomes operational. A mind that runs gradient-shaping without first reading the worked-examples file will reliably collapse Phase 4 into "push harder in disguise" (the #1 failure mode) because it has no pattern to match against. Read the file in full, then run the protocol.

- `references/worked-examples.md` — **REQUIRED READ.** Full six-phase runs of the protocol. Contains three deep examples — **memory** (a depth problem: make the relevant thing rest near the surface), **abilities** (a demand-pull problem: make the need generate the skill), and **learning** (a flywheel problem: make outcomes re-grade the future) — plus compact cross-domain cases (cost, latency, coordination, governance). Consult it again whenever you're unsure how a phase applies to a concrete situation.

---

When you finish a session, you should be able to point at the result and say: *nobody has to hold this up anymore — it sits at the bottom on its own.* If you can't say that, you found a patch, not a valley. Keep shaping.
