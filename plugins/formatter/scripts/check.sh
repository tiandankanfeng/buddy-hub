#!/usr/bin/env bash
# ============================================================================
#  formatter — Stop hook
#
#  Fires when Claude considers finishing the turn. Runs 'spotless:check' over
#  all source files (of the current profile's language) changed in this
#  session. Warns by default; blocks in strict mode.
# ============================================================================
set -uo pipefail

# shellcheck source=lib/common.sh
source "${CLAUDE_PLUGIN_ROOT}/scripts/lib/common.sh"

is_disabled && exit 0

# ---------- 0. Avoid Stop-hook infinite loop ----------
INPUT="$(cat 2>/dev/null || true)"
if [[ -n "$INPUT" ]]; then
    STOP_ACTIVE="$(extract_field "$INPUT" '.stop_hook_active')"
    if [[ "$STOP_ACTIVE" == "true" ]]; then
        debug "stop_hook_active=true, skipping to avoid loop"
        exit 0
    fi
fi

# ---------- 1. Find a project root from CWD ----------
if ! PROJECT_ROOT="$(find_project_root "$PWD")"; then
    debug "no Maven/Gradle project rooted at $PWD — skip"
    exit 0
fi

BUILD_TOOL="$(detect_build_tool "$PROJECT_ROOT")"
if ! has_spotless "$PROJECT_ROOT" "$BUILD_TOOL"; then
    debug "Spotless not configured — skip"
    exit 0
fi

cd "$PROJECT_ROOT" || exit 0

# ---------- 2. Any relevant file changed this session? ----------
# Currently restricted to Java; will expand as more profile languages land.
LANG="$(profile_language)"
case "$LANG" in
    java) GREP_EXT='\.java$' ;;
    *)    debug "unknown language '$LANG' — skip"; exit 0 ;;
esac

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CHANGED=$(git diff --name-only --diff-filter=AM HEAD 2>/dev/null | grep -E "$GREP_EXT" || true)
else
    CHANGED=""
fi

if [[ -z "$CHANGED" ]]; then
    debug "no $LANG changes detected via git — skip"
    exit 0
fi

COUNT=$(echo "$CHANGED" | wc -l | tr -d ' ')
log_info "final style check on $COUNT changed $LANG file(s) [profile: $(current_profile)]"

# ---------- 3. Run spotless:check ----------
CHECK_OUTPUT=""
CHECK_RC=0
case "$BUILD_TOOL" in
    maven)
        command -v mvn >/dev/null 2>&1 || { log_warn "mvn not in PATH"; exit 0; }
        CHECK_OUTPUT=$(mvn -q spotless:check 2>&1) || CHECK_RC=$?
        ;;
    gradle)
        if   [[ -x "./gradlew" ]];         then GRADLE="./gradlew"
        elif command -v gradle >/dev/null; then GRADLE="gradle"
        else log_warn "gradle not available"; exit 0
        fi
        CHECK_OUTPUT=$("$GRADLE" -q spotlessCheck 2>&1) || CHECK_RC=$?
        ;;
esac

if [[ $CHECK_RC -eq 0 ]]; then
    log_ok "all $LANG files comply with the $(current_profile) profile"
    exit 0
fi

# ---------- 4. Handle violation ----------
log_error "style violations detected:"
echo "$CHECK_OUTPUT" | tail -n 30 >&2

if is_strict; then
    cat <<EOF
{
  "decision": "block",
  "reason": "formatter: $LANG files do not comply with the $(current_profile) profile. Run the PostToolUse formatter or invoke 'spotless:apply' manually."
}
EOF
    exit 2
fi

log_warn "non-strict mode — not blocking. Set BUDDY_FORMATTER_STRICT=1 to enforce."
exit 0
