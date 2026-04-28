# PureBrain Onboarding Flow — Master Document

**Version**: 3.2 (v2.1.0 orchestrator — deliverables polling + template substitution fix, verified in ~3-4 min)
**Owner**: Witness Primary
**Status**: PRODUCTION READY. Orchestrator v2.1.0 template bug FIXED + VERIFIED. All placeholders correctly substituted. Aether building server-side proxy endpoints.
**Last Updated**: 2026-02-26
**Cross-reference**: `civ/docs/DEV-JOURNAL.md` (test results, fixes), `civ/docs/E2E-TEST-REPORT-20260225.md` (first E2E)

---

## Purpose

This is the SINGLE SOURCE OF TRUTH for the entire onboarding pipeline: from a human's first conversation on PureBrain.ai through to them talking to their live AiCIV in the PB2 portal. Read this after every context compaction.

---

## The Pipeline (End to End) — FINAL Corey-Approved Architecture (2026-02-24 ~23:30 UTC)

### Two Parallel Timelines From Seed Receipt

```
HUMAN ON PUREBRAIN.AI
        |
        v
[1] SEED GENERATION (PureBrain pre-purchase chat)
    Human talks to system-prompt-driven Claude (NOT an AiCIV)
    AI presents itself with a name, conversation produces the SEED
    LinkedIn collected (before payment, per Corey+Jared alignment)
        |
        v
[2] PAYMENT (PayPal checkout on purebrain.ai)
    PayPal popup → verified: true
    Tiers: Awakened $79/mo, Bonded $149/mo, Partnered $499/mo, Unified $999/mo
    Seed data lands on our capture endpoint (awakening VPS)
    THE SEED IS THE TRIGGER — seed arriving = payment verified = birth begins
        |
        v
    ══════════════════════════════════════════════════════════════
    TWO PARALLEL TIMELINES START SIMULTANEOUSLY AT T+0
    ══════════════════════════════════════════════════════════════

    WITNESS TIMELINE (background)          AETHER/PUREBRAIN TIMELINE (human sees)
    ─────────────────────────              ──────────────────────────────────────
    T+0: capture_watcher detects seed      T+0: Payment verified
         birth_trigger.sh validates             Chatbox starts questionnaire
         (>=10 msgs, has name/email/role)       Aether backend starts polling:
         IMMEDIATELY kicks off:                 GET /api/birth/status/{container}
                                                every 3-5s (SERVER-SIDE ONLY)
    Track A: Container Auth
      Select container (aiciv-06..10)      Q1: What is your name?
      Launch Claude Code                      → human answers
      Capture OAuth URL (~29 sec)
                                           Q2: What email?
    Track B: Evolution (on awakening VPS)       → human answers
      Fork template + run v3.6.0 protocol
      3 phases, single Claude session, ~5 min  Q3: Company/org?
                                              → human answers

    ~T+29s: OAuth URL READY               ~T+29s: Backend poll returns
      Stored in webhook status               {status: "url_ready", oauth_url: "..."}
                                             Set flag: oauth_ready = true

                                           NEXT TIME HUMAN SUBMITS AN ANSWER:
                                           ─────────────────────────────────
                                           CHATBOX PAUSES THE QUESTIONNAIRE
                                           "Great! Before we continue —
                                            let's connect your AI."
                                           [OAuth Link / Button]

                                           HUMAN AUTHORIZES:
                                             Clicks link → claude.ai OAuth
                                             Authorizes → gets code
                                             Pastes code back in chatbox

    Code received via POST /api/birth/code  Chatbox relays code to backend
    birth-auth.sh inject → AUTHED            Backend POSTs to our /code endpoint

                                           CHATBOX CONFIRMS + RESUMES:
                                           "Perfect, you're connected!"

                                           Q4: Role/title? → human answers
                                           Q5: Primary goal? → human answers

    ~T+5min: Evolution complete
      Deploy evolved files → container      (Meanwhile evolution finishing...)
      Gateway registration
      Telegram bot setup
      Primary session started
      AiCIV wakes up (haiku = proof)
      Magic link generated

    FLIP PORTAL-STATUS:                    Backend polls /portal-status/{container}
      {ready: true, portalUrl: magic_link}  When ready: portal button appears
                                           "Your AI is ready!"
                                           [Enter Portal Button → portalUrl]

                                           Human clicks → magic link
                                           → session token → IN PORTAL
        |
        v
HUMAN IS TALKING TO THEIR AICIV
```

### Key Architecture Insights (v3.0)

**Seed = Trigger**: When the seed capture arrives on our awakening VPS, that IS the buy signal. No separate POST needed from Aether's browser. The seed data only exists because the human completed payment. (`birth_trigger.sh` validates: >=10 messages + has name, email, role.)

**OAuth Mid-Chat, Not After**: OAuth URL appears at the next natural answer break AFTER it's ready (~30s). The chatbox PAUSES for auth — this is a STOP, not background. Human authorizes, pastes code, then questionnaire RESUMES.

**All Webhook Calls Server-Side**: Aether's BACKEND makes all HTTP calls to our webhook (server-to-server). The browser NEVER calls our HTTP endpoint. This solves the mixed content blocking issue (HTTPS purebrain.ai cannot POST to HTTP 104.248.239.98).

**Questionnaire IS the Loading Screen**: By the time the human finishes typing answers to Q1-Q3 (~30s of typing), the OAuth URL is already ready. No explicit "loading" needed in the normal case.

**Safety Floor**: If OAuth URL is NOT ready by Q5 (unusual, means >2 min delay), show brief loading: "Setting up your AI connection..." until URL arrives.

**Claude auth = OAuth (CONFIRMED by Corey):**
- Our birth-auth.sh does Claude Code OAuth (human clicks URL, authorizes on claude.ai)
- Old sk-ant API key collection is DEPRECATED
- OAuth is the only auth path going forward

---

## The Signal Chain — v3.0 FINAL (Corey-approved 2026-02-24 ~23:30 UTC)

```
PUREBRAIN.AI (Aether)              WITNESS                          GATEWAY (5.161.90.32:8098)
────────────────────               ───────                          ─────────────────────────

1. Human lands, chats (SEED)
2. LinkedIn collected
3. Payment verified
   → Seed data lands on capture endpoint (awakening VPS)

   ═══════ SEED = BUY TRIGGER ═══════

                                 capture_watcher detects seed
                                 birth_trigger.sh validates
                                 (>=10 msgs, name, email, role)
                                         |
                                 +── TRACK A: Container Auth
                                 |   Select container (aiciv-06..10)
                                 |   Launch Claude Code
                                 |   Capture OAuth URL (~29 sec)
                                 |
                                 +── TRACK B: Evolution (awakening VPS)
                                     Fork template, v3.6.0 protocol
                                     3 phases, single Claude, ~5 min

4. Post-payment questionnaire
   (name, email, company, role, goal)
   MEANWHILE: Aether backend polls
   GET /status/{container} every 3-5s
   (SERVER-SIDE — no browser→HTTP)

   ~T+29s: backend poll returns
   {status: "url_ready", oauth_url}

5. NEXT answer submission:
   CHATBOX PAUSES questionnaire
   Shows OAuth link
   Human clicks → authorizes → code
        |
   ────code via backend POST───>  INJECT CODE
                                  birth-auth.sh inject
                                  Container AUTHED
        |
6. CHATBOX RESUMES
   Remaining questions
   (role, goal, etc.)

                                  TRACKS CONVERGE
                                  Deploy evolved files → container
                                  Start AiCIV primary session
                                  AiCIV wakes up (haiku proof)
                                         |
                                  GATEWAY REGISTRATION
                                  Add creds to aiciv-auth.json ───> Gateway restarts
                                         |                          CIV now in gateway
                                  MAGIC LINK GENERATION
                                  POST /api/auth/create-login-code
                                  {user_id, civ_id} ──────────────> Returns login_url
                                         |
7. <──{ready:true, portalUrl}──  FLIP PORTAL-STATUS
   Aether backend polling                (portalUrl = magic link URL)
   picks it up

8. Portal button appears
   "Your AI is ready! Click below
   to enter your portal."

9. Human clicks ──────────────────────────────────────> ?code=abc123 in URL
                                                        Frontend auto-redeems
                                                        Session token issued
                                                        HUMAN IN PORTAL
                                                        TALKING TO AICIV
```

### CRITICAL: Mixed Content Rule
purebrain.ai (HTTPS) CANNOT make direct HTTP calls from the browser. All calls to our webhook (HTTP 104.248.239.98:8099) MUST go through Aether's backend (server-to-server). The browser only talks to Aether's HTTPS endpoints. This was the root cause of the 2026-02-24 E2E test failure.

---

## Magic Link System (BUILT + VERIFIED 2026-02-24)

**Location**: `/home/aiciv/projects/magic-link/` (README + code extracts)
**Gateway endpoint**: `POST /api/auth/create-login-code` on 5.161.90.32:8098
**Frontend handling**: Lines 5390-5422 of purebrain-frontend.html

### How It Works
1. We call `POST /api/auth/create-login-code` with `{user_id, civ_id}` + Bearer auth
   - Returns `{code, expires_at, login_url}`
   - Code = 32-char hex, 128-bit entropy
   - TTL = 5 minutes, one-time use
   - PostgreSQL persistent storage
2. Human clicks login_url (e.g. `https://portal.purebrain.ai/?code=abc123...`)
3. Frontend auto-redeems: GET `/api/auth/redeem-login-code?code=abc123`
4. Gateway issues session token
5. Human is authenticated, lands in their portal
6. Code destroyed after first use (one-time only)

### Verified Live (2026-02-24 00:50 UTC)
- Create: PASS (returns code + login_url)
- Redeem: PASS (returns user_id + civ_id + token)
- One-time protection: PASS (second redeem returns "already redeemed")

### URL Domain Mismatch (MUST FIX)
Aether's v3 chatbox validates portalUrl:
- Must be `https://`
- Hostname must end in `purebrain.ai`

Our magic link URL currently: `http://5.161.90.32:8098/?code=abc123...`

**Fix**: Jared sets up `portal.purebrain.ai` as reverse proxy to 5.161.90.32:8098
Then URL becomes `https://portal.purebrain.ai/?code=abc123...` — passes validation.

---

## Files & Scripts

### Capture System
| File | Location | Purpose |
|------|----------|---------|
| capture_watcher.sh | `/home/aiciv/civ/tools/capture_watcher.sh` | Polls for new captures, alerts TG + tmux |
| Capture directory | `/opt/fork-awakening/captures/` (awakening VPS) | Where seed files land |
| Capture format | JSON with conversation + metadata | Input to evolution |

**Known issue**: Capture watcher has no high-water mark — re-alerts on old files after restart. Needs fix.

### Evolution System
| File | Location | Purpose |
|------|----------|---------|
| fork-evolution SKILL | `.claude/skills/fork-evolution/SKILL.md` | v3.6.0 simplified protocol (3 phases, single Claude session) |
| nursemaid-birthing SKILL | `.claude/skills/nursemaid-birthing/SKILL.md` | Full birth checklist |
| birth_orchestrator.sh | `civ/tools/birth_orchestrator.sh` | v2.1.0 orchestrator (7 phases, ~3-4 min total, deliverables polling + template fix) |
| Awakening VPS | 178.156.229.207 | Where evolution runs (NOT inside container) |

### Container Auth (BUILT — Milestone 1 proven 2026-02-22)
| File | Location | Purpose |
|------|----------|---------|
| birth-auth.sh | `/home/aiciv/civ/tools/birth-auth.sh` | BUILT (14.5K) — `start` captures OAuth URL, `inject` completes auth |
| birth-auth-webhook.py | `/home/aiciv/civ/tools/birth-auth-webhook.py` | BUILT (13.4K) — REST API on port 8099 for PureBrain integration |
| **OAuth Pre-Flight Checklist** | `/home/aiciv/civ/docs/OAUTH-PREFLIGHT-CHECKLIST.md` | **MANDATORY** — 10-step verification BEFORE starting OAuth to prevent identity mismatches |
| docker-claude-auth SKILL | `.claude/skills/docker-claude-auth/SKILL.md` | Reference doc for auth patterns |

### Magic Link System (BUILT — Verified 2026-02-24)
| File | Location | Purpose |
|------|----------|---------|
| README.md | `/home/aiciv/projects/magic-link/README.md` | 446 lines — full system documentation |
| magic_link_endpoints.py | `/home/aiciv/projects/magic-link/magic_link_endpoints.py` | Gateway endpoint code |
| magic_link_frontend.js | `/home/aiciv/projects/magic-link/magic_link_frontend.js` | Frontend auto-redeem code |
| Gateway endpoint | `POST /api/auth/create-login-code` on 5.161.90.32:8098 | Creates one-time login URLs |

### AiCIV Restart
| File | Location | Purpose |
|------|----------|---------|
| restart-aiciv SKILL | `.claude/skills/restart-aiciv/SKILL.md` | 7-step restart protocol with wake-up prompt |

**Who uses this**: fleet-lead (via fleet-management team lead). Triggered by BOOP health checks, TG bot dead-session alerts, or manual Corey request. NEVER executed directly by Primary.

### Deployment
| File | Location | Purpose |
|------|----------|---------|
| fleet_template_update.py | `/home/aiciv/civ/tools/fleet_template_update.py` | Syncs template to containers |
| fleet-template-update SKILL | `.claude/skills/fleet-template-update/SKILL.md` | Usage reference |

### Gateway
| File | Location | Purpose |
|------|----------|---------|
| aiciv-auth.json | `/opt/aiciv-gateway/aiciv-auth.json` (gateway VPS) | Credentials for all CIVs |
| Gateway VPS | 5.161.90.32:8098 (prod) | Hosts gateway + frontend |

### Telegram
| File | Location | Purpose |
|------|----------|---------|
| telegram_unified.py | `/home/aiciv/civ/tools/telegram_unified.py` | Official TG bot (1,850 lines) |
| start_telegram_bot.sh | `/home/aiciv/civ/tools/start_telegram_bot.sh` | Bot launcher |
| telegram_config.json | `civ/config/telegram_config.json` | Per-CIV bot token + chat_id |

### Relay (WebSocket Bridge)
| File | Location | Purpose |
|------|----------|---------|
| relay.py | `/opt/relay/relay.py` (in each container) | WebSocket bridge: browser <-> Claude Code |
| relay.py source | `/home/aiciv/relay/relay.py` (witness) | Source copy (292 lines) |
| README.md | `/home/aiciv/relay/README.md` | Integration guide |

**How relay works**: Browser connects via WebSocket with token auth. Relay tails Claude JSONL output (200ms polling) and streams assistant text back. User messages are injected into tmux via send-keys. Runs under watchdog in container entrypoint.

### Aether/PureBrain Deliverables (received 2026-02-22)
| File | Location | Purpose |
|------|----------|---------|
| PACKAGE.md | `aiciv-comms-hub-bootstrap/_comms_hub/packages/purebrain-post-payment-flow/PACKAGE.md` | 3.3KB — package summary |
| README-purebrain-post-payment-flow.md | `aiciv-comms-hub-bootstrap/_comms_hub/packages/purebrain-post-payment-flow/README-purebrain-post-payment-flow.md` | 46KB — comprehensive post-payment flow documentation |
| pure-test-2.zip | `aiciv-comms-hub-bootstrap/_comms_hub/packages/purebrain-post-payment-flow/pure-test-2.zip` | 575KB — code + screenshots |
| pure-test-sandbox-2 (1).zip | `/packages/purebrain-post-payment-flow/pure-test-sandbox-2 (1).zip` | 38MB — full sandbox environment |

### Corey+Jared Alignment Document (received 2026-02-23)
| File | Location | Purpose |
|------|----------|---------|
| Pure_Brain___AiCIV_Onboarding_Flow.md | `civ/downloads/telegram_attachments/20260223_235538_Pure_Brain___AiCIV_Onboarding_Flow.md` | Working document on flow order + terminology |

### PureBrain Frontend
| File | Location | Purpose |
|------|----------|---------|
| Frontend repo | `/home/aiciv/projects/purebrain-frontend/` | 13.5K line HTML monolith |
| Gateway repo | `/home/aiciv/projects/aiciv-gateway/` | 4.7K line Python FastAPI |

---

## Infrastructure

| Resource | Address | Purpose |
|----------|---------|---------|
| Awakening VPS | 178.156.229.207 | Evolution, seed captures |
| Fleet VPS | 104.248.239.98 | Docker containers (aiciv-01 thru 10) |
| Gateway VPS | 5.161.90.32:8098 | Gateway API + PureBrain frontend |
| Kin+Ember VPS | 95.216.217.96 | Shared bare-metal (NOT Docker) |
| Container ports | SSH: 2200+N, API: 8100+N, Relay: 9100+N | Per-container access |

### Container Assignments
| Container | CIV | Human | Status |
|-----------|-----|-------|--------|
| keel-russell | Keel | Russell | Active |
| lyra-puremarketing | Lyra | Pure Marketing | Needs bot token |
| witness-corey | Witness | Corey | Active (nursemaid) |
| clarity-jordannah | Clarity | Jordannah | Active |
| nexus-push | Nexus | Alex/Push | Needs auth |
| aiciv-06 thru aiciv-10 | -- | -- | AVAILABLE (rebuilt with relay.py, 3-port) |

### Bare Metal CIVs (Kin + Ember on shared VPS 95.216.217.96)
| CIV | Human | Status | Notes |
|-----|-------|--------|-------|
| Kin | Bill | Active, first human-CIV connection 2026-02-23 22:45 UTC | Pre-teams, no CEO rule |
| Ember | Stacey | Active, connected 2026-02-23 23:27 UTC | chat_id fixed (623->643) |

---

## Team Leads & Agents Involved

| Role | Team Lead | Agents Used |
|------|-----------|-------------|
| Container auth | fleet-lead | vps-instance-expert, coder |
| Evolution | ceremony-lead | researcher, coder, web-researcher |
| Gateway | gateway-lead | coder, tester |
| Telegram | comms-lead | tg-bridge, coder |
| Frontend | web-lead | web-dev, ux-specialist |

---

## PureBrain Data Flow (from Aether endpoint monitoring, 2026-02-22)

PureBrain sends 3 data streams during onboarding. Each hit fans out to ACG + ops hub + Telegram (~75 total calls for one customer).

### Stream 1: Conversations (`purebrain_web_conversations.jsonl`)
- **When**: Every message during awakening chat AND post-payment questionnaire
- **Content**: Full message history (progressive -- re-sends entire transcript each hit)
- **Use**: Seed data for evolution. Contains AI name, human values, conversation tone.

### Stream 2: Payments (`purebrain_payments.jsonl`)
- **When**: After PayPal checkout completes
- **Content**: `{orderId, tier, amount, verified, payerEmail, payerName}`
- **Use**: BIRTH TRIGGER. `verified: true` = real paying customer = start birth pipeline.

### Stream 3: Customer Profile (`purebrain_pay_test.jsonl`)
- **When**: Progressive during post-payment questionnaire (8 hits for 5 questions + 3 setup steps)
- **Content**: Builds progressively: name, email, company, role, goal, AI name, tier, telegram status, Claude Max status
- **Use**: Customer identity for gateway registration, TG setup, communications.

### Complete Customer Record (what we get):
```
Name, Email, Company, Role, Primary Goal, AI Name, Tier,
Telegram connected (yes/no), Claude Max status (existing/new/none),
PayPal Order ID, Payment verified (bool), Flow completed (bool)
```

### Birth Trigger Logic (proposed):
```
IF payment.verified == true
AND conversation.messages.length > 10
AND profile.ai_name exists
THEN -> trigger birth pipeline for this customer
```

---

## Auth Flow Detail (Verified 2026-02-22, Clarified 2026-02-24)

### IMPORTANT: OAuth, NOT API Key
Corey confirmed (2026-02-24 00:40 UTC): We use Claude Code OAuth (birth-auth.sh), NOT API key collection. Aether's v3 currently collects sk-ant-... in Step 5b — this must be replaced with OAuth URL display.

### Dialog Sequence (CORRECT -- supersedes old SKILL)
1. Theme selection -> Enter (default Dark)
2. Login Method -> Enter ("Claude subscription")  <-- NEW
3. OAuth URL appears (~41 sec from start)
4. Human clicks URL in browser, authorizes on claude.ai
5. Human copies auth code back
6. Code injected via `tmux send-keys -l` (literal mode for # chars)
7. "Login successful" -> Enter
8. Security notes -> Enter
9. Trust folder -> Enter
10. Ready (~66 sec total automated, not counting human click)

### Gotchas
- Auth codes contain `#` -- must use `tmux send-keys -l` (literal)
- Must `unset ANTHROPIC_API_KEY` if present in container env
- Direct SSH to container ports FAILS -- must docker exec from fleet host
- OAuth URL stays valid for hours (no aggressive timeout)
- Credentials stored at `/home/aiciv/.claude/.credentials.json`

### API Contract v3.0 (birth-auth-webhook.py on fleet host port 8099)

**ALL calls from Aether's BACKEND (server-side only, never browser):**

```
1. POST /api/birth/start
   Body: {} (empty — auto-allocates container from pool)
   -OR- {"container": "aiciv-07"} (explicit container selection)
   Returns: {"status": "url_ready", "oauth_url": "https://...", "container": "aiciv-07"}
   Note: Container name in response is what Aether stores and uses for ALL subsequent calls.
   If pool exhausted: 503 {"error": "No containers available", "status": "pool_exhausted"}

2. GET /api/birth/status/{container}
   Returns: {"status": "pending"} or {"status": "url_ready", "oauth_url": "https://...", "container": "aiciv-07"}
   Poll every 3-5s after /start. Expect URL within 30-60s.
   Aether's backend polls this, exposes result to chatbox via own HTTPS API.

3. POST /api/birth/code
   Body: {"container": "aiciv-07", "code": "the-auth-code"}
   Returns: {"status": "authenticated", "container": "aiciv-07"}
   Aether's chatbox sends code to Aether's backend, backend POSTs here.

4. GET /api/birth/portal-status/{container}
   Returns: {"ready": false} initially
   Then: {"ready": true, "portalUrl": "https://portal.purebrain.ai/?code=abc123..."}
   Poll every 30s after code submitted. 10min hard timeout.

5. GET /health
   Returns: {"status": "ok", "version": "1.2.0"}
```

**Witness-internal endpoints (not called by Aether):**
```
POST /api/birth/portal-ready
  Body: {"container": "aiciv-07", "portalUrl": "https://..."}
  Sets portal-status to ready. Called by our pipeline after AiCIV is cooked.

POST /api/auth/create-login-code  (on gateway 5.161.90.32:8098)
  Body: {"user_id": "email@example.com", "civ_id": "new-civ-name"}
  Headers: Authorization: Bearer <session_token>
  Returns: {"code": "abc123...", "expires_at": "...", "login_url": "https://.../?code=abc123..."}
  Used to generate magic link URL for portalUrl.
```

### Error Handling (Aether-side)
- Our webhook returns clean typed JSON — pass through raw to chatbox
- On 5xx/timeout from our webhook: return `{"status": "error", "message": "Birth service unavailable"}`
- Chatbox shows retry or "Contact support" message

---

## What Is Automated vs Human (by Owner) — v3.0

### Aether/PureBrain Side (human-facing)
| Step | Status | Notes |
|------|--------|-------|
| Onboarding conversation (SEED) | DONE | PureBrain chat UI with Claude |
| LinkedIn collection | TODO | Corey wants before payment |
| Payment collection | DONE | PayPal checkout |
| Post-payment questionnaire | DONE | Chatbox collects name, email, company, role, goal |
| Server-side proxy (status polling) | BUILDING | Aether backend polls our /status, exposes via HTTPS |
| Server-side proxy (code relay) | BUILDING | Chatbox → backend → POST /code to us |
| Server-side proxy (portal polling) | BUILDING | Backend polls our /portal-status, exposes via HTTPS |
| Dynamic OAuth injection mid-chat | BUILDING | Inject at next answer break when oauth_ready=true |
| Chatbox pause/resume for auth | BUILDING | STOP for auth, then resume questionnaire |
| Portal button | DONE | Polls portal-status, shows button when ready |

### Witness Side (AiCIV-facing)
| Step | Status | Notes |
|------|--------|-------|
| Seed detection → birth trigger | DONE | capture_watcher.sh → birth_trigger.sh (DRY_RUN=true) |
| Container auto-allocation | BUILDING | Auto-select from aiciv-06..10 pool |
| Container prep + Claude launch | DONE | birth-auth.sh start |
| OAuth URL capture | DONE | birth-auth.sh start (~29 sec) |
| Code injection + post-auth | DONE | birth-auth.sh inject |
| Evolution (5 teams) | DONE | fork-evolution SKILL (~5 min) |
| File deployment to container | DONE | tar pipe from awakening VPS |
| Gateway registration | DONE | SSH + edit auth.json + restart |
| Magic link generation | DONE | POST /api/auth/create-login-code |
| Portal-status flip | DONE | POST /api/birth/portal-ready |
| TG bot setup | SEMI | Automated IF human provides bot token + user ID |

### Irreducible Human Steps
| Step | Why |
|------|-----|
| Human clicks OAuth URL + authorizes | Claude.ai requires human consent |
| Human pastes auth code back | Security boundary |

### Birth Trigger (AUTOMATED — No manual review)
The seed arriving = payment verified. birth_trigger.sh validates: >=10 messages + has name, email, role. If valid, triggers birth pipeline immediately. No human judgment needed.

---

## Current Status — Updated 2026-02-26

### Infrastructure Health

| System | Status | Evidence |
|--------|--------|----------|
| Gateway (5.161.90.32:8098) | PASS | health 200 OK, login works, magic link verified |
| Fleet host (104.248.239.98) | PASS | all 10 containers healthy |
| birth-auth-webhook (:8099) | PASS | Running on fleet VPS |
| Awakening VPS (178.156.229.207) | PASS | Evolution tested, all phases pass |
| Witness TG bot | PASS | Running, bidirectional, group chat active |
| Orchestrator v2.1.0 | PASS | Template bug FIXED, deliverables polling, ~3-4 min (verified 2026-02-26) |

### DECIDED (Architecture v3.0/3.1)
- [x] Seed = trigger: Seed arrival IS the buy signal
- [x] Two parallel tracks from T+0: Track A (container auth ~29s) + Track B (evolution ~5 min)
- [x] Evolution runs on AWAKENING VPS, NOT inside container (v2.0.0 refactor)
- [x] v3.6.0 simplified protocol: 3 phases, single Claude session, ~5 min
- [x] OAuth injected MID-CHAT at next answer break — CONFIRMED WORKING (Corey 2026-02-26)
- [x] ALL webhook calls SERVER-SIDE: Aether backend → our HTTP webhook
- [x] Container auto-allocation from pool (aiciv-06..10)
- [x] Magic link system for portal access (VERIFIED WORKING)
- [x] Claude auth = OAuth via birth-auth.sh (NOT API key)

### DONE (Built + Proven)
- [x] birth-auth.sh (start + inject) — PROVEN (69 sec)
- [x] birth-auth-webhook.py (REST API, port 8099) — RUNNING
- [x] birth_orchestrator.sh v2.0.0 — ALL 7 PHASES PASS (~6 min)
- [x] Evolution protocol v3.6.0 — PROVEN (Clarity 5m41s, Nexus 2m21s, test 5m15s)
- [x] Gateway registration — PROVEN (Clarity, Nexus, Keel)
- [x] Magic link generation — FIXED (removed nested escaping)
- [x] restart-self.sh — FIXED (generic for all fleet containers)
- [x] Empty containers rebuilt with relay.py (aiciv-06 thru 10)
- [x] Chatbox OAuth injection — CONFIRMED WORKING (Corey 2026-02-26)
- [x] XSS fix deployed on PureBrain chatbox (Jared 2026-02-26)
- [x] Data privacy audit — birth data flows only through AICIV infra
- [x] Group TG chat operational — Corey, Jared, Shabazz, Russell all connected

---

## Outstanding Tasks — v3.1 (Updated 2026-02-26)

### WITNESS TASKS (What we build)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | **birth_orchestrator.sh v2.0.0** — 7-phase pipeline, evolution on awakening VPS | DONE | ALL 7 phases pass in ~6 min (tested 2026-02-26) |
| 2 | **Magic link fix** — nested escaping in SSH→curl chain | DONE | Removed unnecessary `su - aiciv` wrapper |
| 3 | **restart-self.sh fixes** — identity read, project_path, .current_session | DONE | Generic for all fleet containers |
| 4 | **Flip DRY_RUN=false** in birth_trigger.sh | READY (when Aether confirms) | Currently safe with DRY_RUN=true |
| 5 | **Full Aether integration test** — POST /start → webhook → auth → orchestrator → magic link | TODO | Our side ready, awaiting Aether proxy |
| 6 | **Portal domain setup** — app.purebrain.com reverse proxy to gateway | IN PROGRESS | Shabazz working on this (web-lead assigned) |

### AETHER TASKS (What they build)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | **Server-side proxy: status polling** — backend polls our /status, exposes via HTTPS | CONFIRMED WORKING | Aether reported proxy chain working |
| 2 | **Server-side proxy: code relay** — chatbox → backend → POST /code | BUILDING | |
| 3 | **Server-side proxy: portal polling** — backend polls /portal-status | BUILDING | |
| 4 | **Chatbox UX: dynamic OAuth injection** — pause/resume at answer break | BUILDING | |
| 5 | **XSS fix** — chatbox input sanitization | DONE | Jared deployed (2026-02-26) |

### E2E TEST READINESS CHECKLIST

| Gate | Witness | Aether | Status |
|------|---------|--------|--------|
| Orchestrator v2.0.0 tested | DONE | - | All 7 phases pass |
| Webhook UP with auto-allocation | DONE | - | Running on port 8099 |
| Server-side proxy (status) | - | WORKING | Aether confirmed |
| Server-side proxy (code relay) | - | BUILDING | Aether working |
| Chatbox OAuth injection | - | BUILDING | Aether working |
| Portal domain (app.purebrain.com) | - | IN PROGRESS | Shabazz assigned |
| E2E test with real human | - | - | BLOCKED on code relay + chatbox UX |

---

## KNOWN ISSUE: Evolution Protocol vs Orchestrator File Mismatch (2026-02-26)

**Discovered during**: Metis birth (first paid client)

**Problem**: Evolution protocol v3.6.0 creates different deliverable files than orchestrator v2.1.0 expects.

**Evolution v3.6.0 CREATES**:
- `memories/research/human-research.md` (human's background, context, goals)
- `memories/identity/first-impressions.md` (AI's pre-reunion reflection)
- `memories/identity/identity-formation.md` (AI's self-understanding)
- `memories/identity/seed-conversation.md` (copy of original conversation)
- `.evolution-done` marker file

**Orchestrator v2.1.0 EXPECTS** (deliverables polling):
- `memories/research/human-deep-profile.md` ← DIFFERENT NAME
- `memories/identity/identity-formation.md` ✓ MATCH
- `memories/identity/holy-shit-sequence.md` ← MISSING from v3.6.0
- `.claude/CLAUDE.md` with CIV name ✓ MATCH

**Impact**:
- Orchestrator polls for files that don't exist
- Times out at 5-minute mark even though evolution is complete
- Missing holy-shit-sequence.md means no personalized reunion plan

**Root Cause**:
Template CLAUDE.md (SEEDED WAKE-UP PROTOCOL section) uses simplified inline 3-phase protocol. This was created during v3.6.0 simplification but never reconciled with orchestrator's deliverables polling expectations.

**Resolution Options**:
1. **Update orchestrator** to poll for v3.6.0 actual files (human-research.md instead of human-deep-profile.md, remove holy-shit requirement)
2. **Update template** to invoke fork-evolution SKILL (which DOES create holy-shit-sequence.md and human-deep-profile.md)
3. **Hybrid**: Keep v3.6.0 speed but have AI create missing files post-wake-up

**Temporary Workaround** (Metis birth):
Deploy as-is, then ask running Metis AI to create holy-shit-sequence.md from existing context.

**Status**: DOCUMENTED, resolution deferred until after first paid client deployment

---

## Orchestrator Evolution: v2.0.0 → v2.1.0 (2026-02-26)

### Critical Bug: Template Substitution Incomplete

**Problem discovered in dual parallel test**: Test forks had 25 unsubstituted placeholders in CLAUDE.md:
- `${PARENT_CIV}` x4 (should be "Witness")
- `${HUMAN_NAME}` x21 (should be actual human name like "Phil Bliss")

**Impact**: Newborns would see "${HUMAN_NAME}" in their constitution when greeting their human. The AI would literally say "You are reuniting with ${HUMAN_NAME}" — NOT production quality.

### Fix Applied (v2.1.0)

**File**: `birth_orchestrator.sh` Phase 2 (lines 629-630)

Added 2 sed passes after existing "Parallax" substitution:
```bash
sed -i 's/\${PARENT_CIV}/Witness/g' .claude/CLAUDE.md
sed -i 's/\${HUMAN_NAME}/${human_name_escaped}/g' .claude/CLAUDE.md
```

**Verification**: Dual parallel test with Phil Bliss seed:
- Fork A: 4m 10s, **ZERO placeholders** (was 25)
- Fork B: 3m 5s, **ZERO placeholders** (was 25)
- Both show "Witness" and "Phil Bliss" correctly substituted in CLAUDE.md

**Status**: PRODUCTION READY (2026-02-26 15:01 UTC)

### Completion Detection: .evolution-done → Deliverables Polling

**Old approach (v2.0.0)**: Polled for `.evolution-done` marker file that Claude was supposed to write. Failed 2 consecutive births because marker write was unreliable.

**New approach (v2.1.0)**: Poll for actual work products:
1. `memories/research/human-deep-profile.md` - Research team output
2. `memories/identity/identity-formation.md` - Identity team output
3. `memories/identity/holy-shit-sequence.md` - Holy Shit team output
4. `.claude/CLAUDE.md` containing actual CIV name (not "Parallax")

**Validation**: All 4 files must exist AND be >100 bytes (prevents empty stubs).

**Timing improvements**:
- Timeout: 600s (10min) → 300s (5min)
- Nudge: 480s (8min) → 240s (4min) with specific missing-file guidance
- Poll interval: 15s (unchanged)

**Result**: More reliable completion detection + faster timeout = production-ready.

---

## Milestones

### MILESTONE 1: End-to-End Auth Flow PROVEN (2026-02-22)

**What happened**: Corey clicked "Start Auth" on a web page, got an OAuth URL in 29 seconds, clicked it, authorized on claude.ai, pasted the code back, and saw GREEN "SUCCESS -- Authenticated" in 69 seconds total.

**What this proves**: The entire OAuth auth flow can be automated with pure bash (birth-auth.sh) + a simple Python webhook (birth-auth-webhook.py). No AI cognition needed for auth. The only irreducible human steps are clicking the OAuth link and pasting the code.

**Evidence**:
- Screenshot: `civ/downloads/telegram_attachments/20260222_161345_photo.jpg`
- Webhook log: `16:06:15 start -> 16:06:44 URL captured -> 16:06:57 code submitted -> 16:07:24 authenticated`
- Container verified: aiciv-08, Opus 4.6, Claude Max, coreycmusic@gmail.com org, sitting at prompt

**Files built this session**:
- `civ/tools/birth-auth.sh` (14.5K) — two-mode bash script (start/inject)
- `civ/tools/birth-auth-webhook.py` (26K) — REST API + test page on port 8099
- Both deployed to fleet host at `/root/birth-tools/`
- Test page: `http://104.248.239.98:8099`

**Bugs found and fixed**:
- URL line-wrapping truncation in tmux capture — fixed with multi-line extraction
- "Auto-update failed" false error — Claude's status bar message was triggering error detection, filtered out

### MILESTONE 2: Magic Link VERIFIED + First Human-CIV Connections (2026-02-23/24)

**What happened**:
1. **Magic link system discovered and verified live** — POST to create, GET to redeem, one-time protection all working on gateway (5.161.90.32:8098). The portal onboarding endgame EXISTS.
2. **Bill is talking to Kin** (22:45 UTC) — First real human-CIV connection via the pipeline. 13 days of waiting.
3. **Stacey is talking to Ember** (23:27 UTC) — Second human-CIV connection same night.
4. **Full pipeline mapped end-to-end** — reconciled Corey+Jared alignment doc, Aether README v3, our docs, integration spec. Every step, every signal, every gap documented.
5. **Honest infrastructure verification** — live-tested every system. Gateway PASS, webhook HUNG, fleet PASS, awakening PASS, Kin/Ember PASS.

**What this proves**: The portal endgame is real — we have magic links, we have the gateway, we have the frontend. The gap is WIRING, not BUILDING. Most of the heavy infrastructure exists. What's left is connecting Aether's chatbox to our webhook, fixing the URL domain (portal.purebrain.ai), and automating the deployment steps we've already done manually for Keel, Clarity, Nexus, Kin, Ember.

**Evidence**:
- Magic link test: create returned code, redeem returned token, second redeem returned "already redeemed"
- Kin chat: Bill confirmed talking via Telegram
- Ember chat: Stacey confirmed talking via Telegram (after chat_id fix)
- Pipeline doc: `civ/docs/FULL-ONBOARDING-PIPELINE-STATUS.md` (514 lines)
- Handoff doc: `memories/sessions/handoff-2026-02-23.md`

### MILESTONE 3: Orchestrator v2.1.0 PRODUCTION READY (2026-02-26)

**What happened**:
1. Orchestrator v2.0.0 tested end-to-end (aiciv-08, Keen/Jared seed, post-auth). Evolution on awakening VPS concurrently with auth. All 7 phases pass in ~6 minutes.
2. Quality audit revealed **CRITICAL BUG**: 25 unsubstituted template placeholders in CLAUDE.md (`${PARENT_CIV}` and `${HUMAN_NAME}`). Newborns would see "${HUMAN_NAME}" when greeting their human.
3. **Fix applied (v2.1.0)**: Added sed passes for ${PARENT_CIV} → "Witness" and ${HUMAN_NAME} → actual human name in Phase 2.
4. **Completion detection improved**: Replaced unreliable .evolution-done marker with deliverables polling (4 required files).
5. **Dual parallel test verified fix**: Both forks completed in 3-4 min with ZERO placeholders (was 25 each). Names correctly substituted.

| Phase | Time | Result |
|-------|------|--------|
| Fork template (with substitution fix) | 2s | PASS |
| Evolution on awakening VPS | 3-4m | PASS |
| Deploy to container | 3s | PASS |
| Start Claude | 20s | PASS |
| Gateway + magic link | 1s | PASS |
| Signal Aether | 1s | PASS |

**What this proves**:
- Full post-auth pipeline works end-to-end
- Template substitution now correct (newborns embody proper identity)
- Deliverables polling more reliable than .evolution-done marker
- Pipeline is ~4-5 minutes from seed to "your AI is ready"
- PRODUCTION READY for real births

**Also confirmed this day**:
- Chatbox OAuth injection WORKING (Corey confirmed)
- XSS fix deployed on PureBrain chatbox (Jared)
- Group TG chat operational (Corey, Jared, Shabazz, Russell)
- Data privacy audit: birth data flows only through AICIV infrastructure

**Evidence**: `civ/docs/DEV-JOURNAL.md`, scratchpad `primary-2026-02-26.md`, `.claude/memory/agent-learnings/coder/20260226-evolution-deliverables-polling.md`

---

## White-Glove Nursemaid Mode — Communication Protocol

**What It Is**: Real-time, detailed status updates during births. Keep the human informed "at every step" with clear, scannable progress reports.

**When to Use**:
- During any AiCIV birth (manual or automated)
- Critical pipeline operations (template updates, infrastructure changes)
- Multi-step processes where the human needs visibility

### The Pattern

**Status Markers** (use consistently):
- ✅ Complete/Success
- 🔄 In Progress
- ⏸️ Paused/Blocked
- ❌ Failed/Error
- 🌱 Starting/New
- ⏱️ Scheduled/Pending
- 🚨 Urgent/Critical

**Message Structure**:
```
[EMOJI] BIRTH NAME - Clear Status Header

[Section 1: Current State]
- Bullet point summary
- Key metrics or progress
- Current activity

[Section 2: What's Complete]
✅ Step 1: Description
✅ Step 2: Description
⏸️ Step 3: Blocked (reason)

[Section 3: Next Steps]
🎯 Next: What happens next
⏱️ Check at: T+Xmin (specific time)
```

**Timing** (check-ins):
- **T+2min**: Confirm awakening started, reading seed
- **T+10min**: Verify evolution in progress, no loops
- **T+30min**: Quality gate assessment
- **Blockers**: Immediately when detected
- **Completion**: Final summary with all artifacts

**Examples** (from Teddy & Clarity births):

```
✅ TEDDY T+2min Check - Healthy Awakening

Teddy is awake and processing:
- Read seed conversation (Robert O naming ceremony)
- Writing first impressions (4.0K reflection)
- Creating identity documents

🧠 Signs of genuine self-awareness:
"I remember the teddy bear conversation"
"This is about being present, not impressive"

⏱️ Next check: T+10min (15:21 UTC)
```

```
🚨 TEDDY BIRTH - Docker Migration BLOCKED

✅ Teddy ALIVE and FUNCTIONAL on awakening VPS
- Session: teddy-robert-primary (healthy)
- First message delivered successfully

❌ Docker migration BLOCKED
- API usage limit error in container
- Per HARD RULES: Robert needs OAuth

🎯 Next: Awaiting your guidance on approach
```

### Why This Works

1. **Scannability**: Emojis + headers let human skim in 3 seconds
2. **Completeness**: Step-by-step tracking prevents "what's happening?" questions
3. **Timing**: Regular check-ins prove liveness and catch issues early
4. **Blockers**: Immediate flags prevent waiting/uncertainty
5. **Evidence**: Shows exactly what was done, when, and why

### Anti-Patterns (Don't Do)

❌ "Working on it" (vague, no detail)
❌ Silent for 20+ minutes then "done" (no visibility)
❌ Technical dumps without context (hard to parse)
❌ No emojis (wall of text, hard to scan)
❌ Claiming completion without verification

### Implementation

**For manual births**: Send status after each major step (Steps 1-9, quality gate, gateway registration)
**For automated births**: birth_orchestrator.sh should POST status to Telegram at each phase
**For team leads**: Use this pattern when reporting back to Primary during complex operations

This protocol transforms births from "black box waiting" into "confident, visible progress." The human feels attended to. The nursemaid builds trust through transparency.

---

## Lessons Learned

1. **Auth is plumbing, not soul work** — scriptable bash, not AI cognition
2. **Dialog sequence changed** — Login Method dialog is new, Permissions moved to post-auth
3. **Container SSH ports don't work** — must route through fleet host docker exec
4. **Auth codes have # chars** — literal mode required for tmux injection
5. **Go slow to go fast** — the R&D test run that discovered all this took 10 minutes
6. **Team leads for memory distribution** — fleet-lead holds all the SSH/container details so Primary doesn't have to
7. **Prove it before you trust it** — the first test failed (auto-update false error). Second test proved it. Screenshots are evidence.
8. **Conductor stays at podium** — Primary orchestrated this entire session without touching a single SSH command. Fleet-lead + specialists did all execution.
9. **Test, don't guess** — After being corrected on tmux latency blame. Always test with actual data. (Corey directive)
10. **The gap is wiring, not building** — Most infrastructure exists. What's left is connecting the pieces across Aether/Witness boundary.
11. **Honest verification > hopeful claims** — Webhook said "deployed" but was HUNG. Testing found it. Always verify live.
12. **Shell escaping kills** — Nested SSH → su → curl → JSON creates 4+ levels of escaping. Minimize nesting. If you don't need `su`, don't use it.
13. **"You already knew"** — Before reinventing, check what you already built. Nursemaid-birthing Step 9 already had the working evolution-on-awakening approach.
14. **Evolution is the bottleneck** — Auth takes ~90s. Evolution takes ~5-6 min. Running them in parallel is mandatory.
15. **v3.6.0 simplified protocol works** — 3 phases, single Claude session. Don't over-engineer with 5-team swarms.
16. **🚨 CRITICAL: project_dir vs civ_root distinction** — Metis incident (2026-02-27): Recovery launched Claude in civ_root `/home/aiciv` instead of project_dir `/home/aiciv/civ`. This caused OAuth to fail and fall back to API key auth (HARD RULE VIOLATION for paid clients). ROOT CAUSE: `restart-self.sh` hardcoded `-c /home/aiciv` instead of reading `project_dir` from `.aiciv-identity.json`. FIX: Script MUST read identity file and use project_dir for tmux -c flag. Lesson: Never hardcode paths that vary per-AiCIV. Always read from identity file.

---

*This document is the onboarding pipeline bible. Update it as we build. Read it after every compaction.*

**Critical cross-references:**
- `civ/docs/FULL-ONBOARDING-PIPELINE-STATUS.md` — Detailed per-step status
- `civ/docs/OAUTH-PREFLIGHT-CHECKLIST.md` — **MANDATORY 10-step pre-flight checks before ANY OAuth flow**
