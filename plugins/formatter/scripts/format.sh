#!/usr/bin/env bash
# ============================================================================
#  formatter — PostToolUse hook
#
#  Fires after Edit / Write / MultiEdit. If the edited file belongs to the
#  current profile's language, formats it in place using Spotless seeded by
#  the profile XML shipped with the plugin.
#
#  Reads hook JSON from stdin; writes logs to stderr. Exit semantics:
#    0  → continue normally (default, even on format failure)
#    2  → block the tool (only in BUDDY_FORMATTER_STRICT=1 mode)
# ============================================================================
set -uo pipefail

# shellcheck source=lib/common.sh
source "${CLAUDE_PLUGIN_ROOT}/scripts/lib/common.sh"

is_disabled && exit 0

# ---------- 1. Read the hook payload ----------
INPUT="$(cat)"
debug "raw input: $INPUT"

FILE_PATH="$(extract_field "$INPUT" '.tool_input.file_path')"
if [[ -z "$FILE_PATH" ]]; then
    debug "no file_path in tool_input; nothing to format"
    exit 0
fi

# ---------- 2. Does the current profile handle this file? ----------
if ! profile_handles_file "$FILE_PATH"; then
    debug "profile '$(current_profile)' does not handle: $FILE_PATH"
    exit 0
fi

# ---------- 3. Locate project root ----------
if ! PROJECT_ROOT="$(find_project_root "$(dirname "$FILE_PATH")")"; then
    log_warn "could not find pom.xml or build.gradle above $FILE_PATH — skip"
    exit 0
fi

BUILD_TOOL="$(detect_build_tool "$PROJECT_ROOT")"
debug "project root: $PROJECT_ROOT | build tool: $BUILD_TOOL | profile: $(current_profile)"

# ---------- 4. Require Spotless to be wired up ----------
if ! has_spotless "$PROJECT_ROOT" "$BUILD_TOOL"; then
    log_warn "Spotless is not configured in this project."
    log_warn "Run '/formatter:setup' once to integrate it."
    exit 0  # never block — setup is a one-time action for the user
fi

# ---------- 5. Resolve absolute + relative paths ----------
ABS_FILE="$(cd "$(dirname "$FILE_PATH")" && pwd)/$(basename "$FILE_PATH")"
REL_FILE="${ABS_FILE#"$PROJECT_ROOT"/}"
debug "formatting: $REL_FILE"

# ---------- 6. Run the formatter (single-file, fast path) ----------
cd "$PROJECT_ROOT" || exit 0

FMT_OUTPUT=""
FMT_RC=0
case "$BUILD_TOOL" in
    maven)
        # -DspotlessFiles accepts a regex matched against absolute path.
        REGEX_PATH="$(printf '%s' "$ABS_FILE" | sed 's/[.[\*^$(){}?+|/]/\\&/g')"
        if ! command -v mvn >/dev/null 2>&1; then
            log_warn "mvn not in PATH — skip"
            exit 0
        fi
        FMT_OUTPUT=$(mvn -q -o spotless:apply \
            "-DspotlessFiles=${REGEX_PATH}" 2>&1) || FMT_RC=$?
        # Retry online if offline mode failed to resolve a missing artifact.
        if [[ $FMT_RC -ne 0 ]] && echo "$FMT_OUTPUT" | grep -qi "offline"; then
            FMT_OUTPUT=$(mvn -q spotless:apply \
                "-DspotlessFiles=${REGEX_PATH}" 2>&1) || FMT_RC=$?
        fi
        ;;
    gradle)
        if   [[ -x "./gradlew" ]];         then GRADLE="./gradlew"
        elif command -v gradle >/dev/null; then GRADLE="gradle"
        else log_warn "gradle wrapper not found — skip"; exit 0
        fi
        # Spotless Gradle supports -PspotlessIdeHook for single-file formatting.
        FMT_OUTPUT=$("$GRADLE" -q spotlessApply \
            "-PspotlessIdeHook=$ABS_FILE" 2>&1) || FMT_RC=$?
        ;;
    *)
        log_warn "unsupported build tool: $BUILD_TOOL — skip"
        exit 0
        ;;
esac

# ---------- 7. Report result ----------
if [[ $FMT_RC -eq 0 ]]; then
    log_ok "formatted $REL_FILE"
    exit 0
else
    log_error "format failed for $REL_FILE"
    echo "$FMT_OUTPUT" | tail -n 20 >&2
    if is_strict; then
        cat <<EOF
{
  "decision": "block",
  "reason": "formatter: format failed for $REL_FILE (see stderr above). Fix the issue or unset BUDDY_FORMATTER_STRICT."
}
EOF
        exit 2
    fi
    exit 0
fi
