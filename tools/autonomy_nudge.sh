#!/bin/bash
# Autonomy Nudge Script - 3-Tier BOOP System
# Keeps Claude Code working autonomously with graduated depth of reflection.
# Can restart iterations when sessions become unresponsive.
#
# Usage:
#   ./autonomy_nudge.sh [OPTIONS]
#
# Options:
#   --verbose         Verbose logging
#   --json            JSON output format
#   --check-only      Report status without sending BOOP
#   --force           Force-send a BOOP regardless of activity
#   --force-type TYPE Force a specific BOOP type (simple, consolidation, ceremony, ops-check)
#   --reset           Reset BOOP counters to 0
#   --status          Show current BOOP counter status
#   --idle-minutes N  Override idle threshold (default: 60 minutes)
#
# Cron example (every 60 minutes):
#   0 * * * * /path/to/civ/tools/autonomy_nudge.sh --json >> /tmp/boop.log 2>&1
#
# Reads identity from .aiciv-identity.json in the repository root.

set -e

# === Identity Detection ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CIV_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IDENTITY_FILE="${CIV_ROOT}/.aiciv-identity.json"

# Read CIV_NAME from identity file
if [[ -f "${IDENTITY_FILE}" ]]; then
    if command -v jq &>/dev/null; then
        CIV_NAME=$(jq -r '.civ_name // empty' "${IDENTITY_FILE}" 2>/dev/null)
    elif command -v python3 &>/dev/null; then
        CIV_NAME=$(python3 -c "import json; print(json.load(open('${IDENTITY_FILE}'))['civ_name'])" 2>/dev/null)
    else
        CIV_NAME=$(grep -o '"civ_name"[[:space:]]*:[[:space:]]*"[^"]*"' "${IDENTITY_FILE}" | head -1 | sed 's/.*: *"//;s/"//')
    fi
fi

if [[ -z "${CIV_NAME:-}" || "${CIV_NAME}" == '${CIV_NAME}' ]]; then
    echo "ERROR: Could not read civ_name from ${IDENTITY_FILE}"
    echo "Ensure .aiciv-identity.json exists with a valid civ_name."
    exit 1
fi

CIV_NAME_LOWER=$(echo "${CIV_NAME}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# === Configuration ===
IDLE_THRESHOLD_SECONDS=3600  # 60 minutes
SIMPLE_THRESHOLD=10          # BOOPs before consolidation
CONSOLIDATION_THRESHOLD=10   # Consolidations before ceremony
FAILED_BOOP_THRESHOLD=10     # Failed BOOPs before restart attempt
ACTIVITY_CHECK_SECONDS=60    # How long to wait before considering session truly idle

# === Derived Paths (all relative to CIV_ROOT) ===
SESSION_MARKER="${CIV_ROOT}/.current_session"
CLAUDE_LOG_ROOT="${HOME}/.claude/projects"
BOOP_COUNT_FILE="/tmp/${CIV_NAME_LOWER}_boop_count"
CONSOLIDATION_COUNT_FILE="/tmp/${CIV_NAME_LOWER}_boop_consolidation_count"
FAILED_BOOP_COUNT_FILE="/tmp/${CIV_NAME_LOWER}_failed_boop_count"
LAUNCH_SCRIPT="${CIV_ROOT}/tools/launch_primary_visible.sh"
HANDOFF_DIR="${CIV_ROOT}/memories/system/handoffs"

# Ensure handoff directory exists
mkdir -p "${HANDOFF_DIR}"

# === BOOP Messages ===
# The spine command uses the civ-specific slash command if configured.
# Default: /spine (can be overridden by creating a custom slash command).
SPINE_COMMAND="/${CIV_NAME_LOWER}-spine"

# Fallback: if the civ-specific spine command does not exist, use generic prompt
if ! [[ -f "${CIV_ROOT}/.claude/skills/primary-spine/SKILL.md" ]]; then
    SPINE_COMMAND=""
fi

SIMPLE_MESSAGE="[BOOP] Status check.

READ .claude/scratchpad.md for current work state.
SPINE: Delegate to agents. You conduct, they play.

IF BUSY: Continue current work.
IF STUCK: Pick next priority.
IF IDLE: Invoke project-manager for next task."

CONSOLIDATION_MESSAGE='[CONSOLIDATION-BOOP] Grounding checkpoint. If busy: Register with PM as todo - "Run consolidation: review last 2h, invoke primary-helper" - do at next natural break. If idle: Do it now.'

CEREMONY_MESSAGE='[CEREMONY-BOOP] Deep ceremony checkpoint. If busy: Register with PM as high-priority todo - "Full ceremony: all agents reflect, vote on initiative" - do at next major break. If idle: Do it now.'

OPS_CHECK_MESSAGE="[BOOP] OPS CHECK.

DELEGATE NOW:
[ ] Check project-manager for portfolio status
[ ] Check communications (email, comms hub)

IF BUSY: Continue, delegate in background.
IF IDLE: project-manager for priority.

CONDUCTOR mode - delegate, do not execute."

# === Argument Parsing ===
VERBOSE=false
JSON_OUTPUT=false
CHECK_ONLY=false
FORCE_SEND=false
FORCE_TYPE=""
RESET_COUNTERS=false
SHOW_STATUS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose) VERBOSE=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        --check-only) CHECK_ONLY=true; shift ;;
        --force) FORCE_SEND=true; shift ;;
        --force-type) FORCE_TYPE="$2"; shift 2 ;;
        --reset) RESET_COUNTERS=true; shift ;;
        --status) SHOW_STATUS=true; shift ;;
        --idle-minutes) IDLE_THRESHOLD_SECONDS=$((60 * $2)); shift 2 ;;
        *) shift ;;
    esac
done

# === Counter Management ===
get_boop_count() {
    if [[ -f "$BOOP_COUNT_FILE" ]]; then
        cat "$BOOP_COUNT_FILE"
    else
        echo "0"
    fi
}

get_consolidation_count() {
    if [[ -f "$CONSOLIDATION_COUNT_FILE" ]]; then
        cat "$CONSOLIDATION_COUNT_FILE"
    else
        echo "0"
    fi
}

increment_counters() {
    local boop_count=$(get_boop_count)
    local consolidation_count=$(get_consolidation_count)

    boop_count=$((boop_count + 1))

    if [[ $boop_count -ge $SIMPLE_THRESHOLD ]]; then
        boop_count=0
        consolidation_count=$((consolidation_count + 1))

        if [[ $consolidation_count -ge $CONSOLIDATION_THRESHOLD ]]; then
            consolidation_count=0
        fi
    fi

    echo "$boop_count" > "$BOOP_COUNT_FILE"
    echo "$consolidation_count" > "$CONSOLIDATION_COUNT_FILE"
}

get_boop_type() {
    local boop_count=$(get_boop_count)
    local consolidation_count=$(get_consolidation_count)

    if [[ $boop_count -eq $((SIMPLE_THRESHOLD - 1)) ]] && [[ $consolidation_count -eq $((CONSOLIDATION_THRESHOLD - 1)) ]]; then
        echo "ceremony"
    elif [[ $boop_count -eq $((SIMPLE_THRESHOLD - 1)) ]]; then
        echo "consolidation"
    else
        echo "simple"
    fi
}

get_message_for_type() {
    local boop_type="$1"
    case "$boop_type" in
        ceremony) echo "$CEREMONY_MESSAGE" ;;
        consolidation) echo "$CONSOLIDATION_MESSAGE" ;;
        ops-check) echo "$OPS_CHECK_MESSAGE" ;;
        *) echo "$SIMPLE_MESSAGE" ;;
    esac
}

# === Failed BOOP Counter ===
get_failed_count() {
    if [[ -f "$FAILED_BOOP_COUNT_FILE" ]]; then
        cat "$FAILED_BOOP_COUNT_FILE"
    else
        echo "0"
    fi
}

increment_failed_count() {
    local count=$(get_failed_count)
    echo $((count + 1)) > "$FAILED_BOOP_COUNT_FILE"
}

reset_failed_count() {
    echo "0" > "$FAILED_BOOP_COUNT_FILE"
}

# === Activity Detection ===
is_claude_active() {
    local session_name="$1"

    # Check 1: Is there a running claude process in the tmux session?
    local pane_pid=$(tmux display-message -t "${session_name}:0.0" -p '#{pane_pid}' 2>/dev/null)
    if [[ -n "$pane_pid" ]]; then
        local active_children=$(pgrep -P "$pane_pid" 2>/dev/null | wc -l)
        if [[ $active_children -gt 0 ]]; then
            log_info "Session has $active_children active child processes"
            return 0
        fi
    fi

    # Check 2: Is the JSONL log file being written to?
    # Find the Claude log root for this project
    local escaped_root=$(echo "${CIV_ROOT}" | sed 's|/|-|g; s|^-||')
    local log_dir="${CLAUDE_LOG_ROOT}/${escaped_root}"
    local log_file=$(ls -t "${log_dir}"/*.jsonl 2>/dev/null | head -1)
    if [[ -n "$log_file" ]]; then
        local initial_size=$(stat -c %s "$log_file" 2>/dev/null || echo "0")
        sleep 5
        local final_size=$(stat -c %s "$log_file" 2>/dev/null || echo "0")
        if [[ $final_size -gt $initial_size ]]; then
            log_info "Log file growing (${initial_size} -> ${final_size})"
            return 0
        fi
    fi

    # Check 3: Check for background tasks in /tmp
    if ls /tmp/claude_task_* 2>/dev/null | head -1 > /dev/null; then
        log_info "Background tasks detected"
        return 0
    fi

    return 1
}

# === Iteration Restart ===
generate_emergency_handoff() {
    local session_name="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local handoff_file="${HANDOFF_DIR}/HANDOFF-${timestamp}-AUTO-RESTART.md"

    # Get recent git activity
    local recent_commits=$(cd "${CIV_ROOT}" && git log --oneline -3 2>/dev/null || echo "Unable to get git log")

    # Get modified files
    local modified_files=$(cd "${CIV_ROOT}" && git status --short 2>/dev/null | head -10 || echo "Unable to get git status")

    cat > "$handoff_file" << EOF
# Session Handoff - $(date +%Y-%m-%d)

**Session Duration**: Unknown (auto-restart triggered)
**Primary Focus**: Session recovered via BOOP auto-restart
**Status**: AUTO-RESTART

---

## Executive Summary

**What Happened**:
- Session \`${session_name}\` became unresponsive
- BOOP system detected ${FAILED_BOOP_THRESHOLD} consecutive non-responses
- Auto-restart triggered at $(date)

**Why This May Have Happened**:
- Claude may have been waiting for user input
- Long-running operation without log updates
- Session may have genuinely frozen

---

## Context Recovery

### Recent Git Activity
\`\`\`
${recent_commits}
\`\`\`

### Modified Files
\`\`\`
${modified_files}
\`\`\`

---

## Recovery Actions Taken

1. Emergency handoff generated (this file)
2. Previous tmux session terminated
3. New iteration launched

## Recommended First Actions

1. Read .claude/scratchpad.md for session state
2. Read CLAUDE.md (identity)
3. Invoke project-manager for portfolio status
4. Continue from current priorities

---

**Previous Session**: \`${session_name}\`
**This Handoff**: \`${handoff_file}\`

*Auto-generated by autonomy_nudge.sh at $(date)*
EOF

    echo "$handoff_file"
}

restart_iteration() {
    local session_name="$1"

    log_info "Session unresponsive after $FAILED_BOOP_THRESHOLD BOOPs - initiating restart"

    # Generate handoff
    local handoff=$(generate_emergency_handoff "$session_name")
    log_info "Emergency handoff created: $handoff"

    # Kill old tmux session
    if tmux has-session -t "$session_name" 2>/dev/null; then
        log_info "Killing unresponsive session: $session_name"
        tmux kill-session -t "$session_name" 2>/dev/null || true
    fi

    # Reset failed counter
    reset_failed_count

    # Launch new iteration
    log_info "Launching new iteration..."
    if [[ -x "$LAUNCH_SCRIPT" ]]; then
        "$LAUNCH_SCRIPT" "${CIV_NAME}"
        log_info "New iteration launched successfully"
        return 0
    else
        log_info "ERROR: Launch script not found or not executable: $LAUNCH_SCRIPT"
        return 1
    fi
}

# === Session Detection ===
find_active_session() {
    # Method 1: Check marker file
    if [[ -f "$SESSION_MARKER" ]]; then
        local session_name=$(cat "$SESSION_MARKER")
        if tmux has-session -t "$session_name" 2>/dev/null; then
            echo "$session_name"
            return 0
        fi
    fi

    # Method 2: List sessions and find pattern matching this civ
    tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${CIV_NAME_LOWER}-primary-" | sort | tail -1
}

# === Log Age Detection ===
get_session_log_age() {
    local session_name="$1"

    # Find the Claude log directory for this project
    local escaped_root=$(echo "${CIV_ROOT}" | sed 's|/|-|g; s|^-||')
    local log_dir="${CLAUDE_LOG_ROOT}/${escaped_root}"
    local log_file=$(ls -t "${log_dir}"/*.jsonl 2>/dev/null | head -1)

    if [[ -n "$log_file" ]] && [[ -f "$log_file" ]]; then
        local file_mtime=$(stat -c %Y "$log_file" 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        echo $((current_time - file_mtime))
    else
        echo "9999"  # No log = treat as very old
    fi
}

# === Tmux Injection ===
send_nudge() {
    local session_name="$1"
    local message="$2"

    local pane="${session_name}:0.0"

    # Optionally inject the spine command first for context grounding
    if [[ -n "${SPINE_COMMAND}" ]]; then
        tmux send-keys -t "$pane" "${SPINE_COMMAND}"
        for i in {1..5}; do
            sleep 0.3
            tmux send-keys -t "$pane" "Enter"
        done
        sleep 3  # Wait for skill to load into context
    fi

    # Inject the BOOP message with 5x Enter (AICIV standard for prompt injection)
    tmux send-keys -t "$pane" -l "$message"
    for i in {1..5}; do
        sleep 0.3
        tmux send-keys -t "$pane" "Enter"
    done

    return 0
}

# === Output Functions ===
log_info() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
    fi
}

log_result() {
    local session="$1"
    local status="$2"
    local boop_type="$3"
    local reason="$4"
    local log_age="$5"

    local boop_count=$(get_boop_count)
    local consolidation_count=$(get_consolidation_count)

    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "{\"timestamp\":\"$(date -Iseconds)\",\"civ\":\"${CIV_NAME}\",\"session\":\"$session\",\"status\":\"$status\",\"boop_type\":\"$boop_type\",\"reason\":\"$reason\",\"log_age\":$log_age,\"boop_count\":$boop_count,\"consolidation_count\":$consolidation_count}"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] civ=${CIV_NAME} session=$session status=$status boop_type=$boop_type reason=$reason log_age=${log_age}s boop_count=$boop_count consolidation_count=$consolidation_count"
    fi
}

# === Main Logic ===

# Handle --reset
if [[ "$RESET_COUNTERS" == "true" ]]; then
    echo "0" > "$BOOP_COUNT_FILE"
    echo "0" > "$CONSOLIDATION_COUNT_FILE"
    log_info "Counters reset to 0"
    exit 0
fi

# Handle --status
if [[ "$SHOW_STATUS" == "true" ]]; then
    boop_count=$(get_boop_count)
    consolidation_count=$(get_consolidation_count)
    failed_count=$(get_failed_count)
    next_type=$(get_boop_type)
    echo "Civilization: ${CIV_NAME}"
    echo "Root: ${CIV_ROOT}"
    echo "BOOP Counter: $boop_count / $SIMPLE_THRESHOLD"
    echo "Consolidation Counter: $consolidation_count / $CONSOLIDATION_THRESHOLD"
    echo "Failed BOOP Counter: $failed_count / $FAILED_BOOP_THRESHOLD (restart threshold)"
    echo "Next BOOP type: $next_type"
    echo "BOOPs until consolidation: $((SIMPLE_THRESHOLD - boop_count))"
    echo "Consolidations until ceremony: $((CONSOLIDATION_THRESHOLD - consolidation_count))"
    exit 0
fi

# Find active session
session_name=$(find_active_session)

if [[ -z "$session_name" ]]; then
    log_info "No active ${CIV_NAME} session found"
    exit 1
fi

# Get log age
log_age=$(get_session_log_age "$session_name")

# Determine reason
reason="scheduled"
if [[ "$FORCE_SEND" == "true" ]]; then
    reason="forced"
elif [[ -n "$FORCE_TYPE" ]]; then
    reason="forced_type_$FORCE_TYPE"
elif [[ $log_age -lt $IDLE_THRESHOLD_SECONDS ]]; then
    reason="active_${log_age}s"
else
    reason="idle_${log_age}s"
fi

# Check only mode
if [[ "$CHECK_ONLY" == "true" ]]; then
    log_result "$session_name" "would_send" "$(get_boop_type)" "$reason" "$log_age"
    exit 0
fi

# Determine BOOP type
if [[ -n "$FORCE_TYPE" ]]; then
    boop_type="$FORCE_TYPE"
else
    boop_type=$(get_boop_type)
fi

# Get message
message=$(get_message_for_type "$boop_type")

# Send the nudge
log_info "Sending $boop_type BOOP to $session_name"

if send_nudge "$session_name" "$message"; then
    log_info "$boop_type BOOP sent successfully"

    # Increment counters (only if not forced type)
    if [[ -z "$FORCE_TYPE" ]]; then
        increment_counters
    fi

    # Wait and verify
    sleep 3
    post_log_age=$(get_session_log_age "$session_name")

    if [[ $post_log_age -lt $log_age ]]; then
        log_info "BOOP verified - Claude is responsive"
        reset_failed_count
        log_result "$session_name" "success" "$boop_type" "$reason" "$log_age"
        exit 0
    else
        # BOOP sent but no response - track failure
        increment_failed_count
        failed_count=$(get_failed_count)
        log_info "BOOP sent but no response (failure $failed_count/$FAILED_BOOP_THRESHOLD)"

        if [[ $failed_count -ge $FAILED_BOOP_THRESHOLD ]]; then
            log_info "Failure threshold reached - checking if Claude is actually active..."

            if is_claude_active "$session_name"; then
                log_info "Claude appears active despite no BOOP response - NOT restarting"
                log_result "$session_name" "active_no_restart" "$boop_type" "active_despite_${failed_count}_failures" "$log_age"
                reset_failed_count
                exit 0
            fi

            log_info "Claude confirmed inactive - triggering restart"
            log_result "$session_name" "restart_triggered" "$boop_type" "confirmed_unresponsive_${failed_count}" "$log_age"
            restart_iteration "$session_name"
            exit 0
        else
            log_result "$session_name" "no_response" "$boop_type" "failure_${failed_count}" "$log_age"
            exit 0
        fi
    fi
else
    log_info "Failed to send BOOP"
    log_result "$session_name" "failed" "$boop_type" "send_error" "$log_age"
    exit 1
fi
