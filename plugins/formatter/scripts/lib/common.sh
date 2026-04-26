#!/usr/bin/env bash
# ============================================================================
#  formatter — shared helpers
#
#  Sourced by hook scripts. Provides logging, env-var toggles, project
#  detection, and hook-payload field extraction.
# ============================================================================

# ---------- Logging ----------
# All hook output goes to stderr so it does NOT pollute the JSON hook decision
# on stdout.
_log_prefix="[formatter]"
log_info()  { echo "${_log_prefix} $*" >&2; }
log_warn()  { echo "${_log_prefix} ⚠️  $*" >&2; }
log_error() { echo "${_log_prefix} ❌ $*" >&2; }
log_ok()    { echo "${_log_prefix} ✅ $*" >&2; }

# ---------- Env / config ----------
# BUDDY_FORMATTER_STRICT=1     → fail hooks (exit 2) on format errors, blocking Claude
# BUDDY_FORMATTER_DEBUG=1      → verbose logging
# BUDDY_FORMATTER_DISABLED=1   → noop (useful to temporarily turn off)
# BUDDY_FORMATTER_PROFILE=...  → profile id; defaults to "java-alipay"
is_strict()   { [[ "${BUDDY_FORMATTER_STRICT:-0}"   == "1" ]]; }
is_debug()    { [[ "${BUDDY_FORMATTER_DEBUG:-0}"    == "1" ]]; }
is_disabled() { [[ "${BUDDY_FORMATTER_DISABLED:-0}" == "1" ]]; }

debug() { is_debug && log_info "DEBUG: $*" || true; }

# The active profile id. Maps to config/profiles/<id>.{xml,toml,json,...}
# inside the plugin. v1 ships with only "java-alipay".
current_profile() { echo "${BUDDY_FORMATTER_PROFILE:-java-alipay}"; }

# Resolve the profile file path. Currently assumes .xml (Eclipse JDT profiles).
# When additional languages ship, this is where extension resolution will live.
profile_file() {
    local id; id="$(current_profile)"
    echo "${CLAUDE_PLUGIN_ROOT}/config/profiles/${id}.xml"
}

# Given a profile id, return the language it governs. v1: only java-alipay.
profile_language() {
    local id; id="$(current_profile)"
    case "$id" in
        java-*) echo "java" ;;
        *)      echo "unknown" ;;
    esac
}

# ---------- Project detection ----------
# Walks up from $1 (default: CWD) looking for pom.xml or build.gradle(.kts).
# Prints project root on stdout; exits 1 if none found.
find_project_root() {
    local dir="${1:-$PWD}"
    while [[ "$dir" != "/" && -n "$dir" ]]; do
        if [[ -f "$dir/pom.xml" ]] || \
           [[ -f "$dir/build.gradle" ]] || \
           [[ -f "$dir/build.gradle.kts" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Detect build tool: "maven" | "gradle" | "unknown"
detect_build_tool() {
    local root="$1"
    if   [[ -f "$root/pom.xml" ]]; then echo "maven"
    elif [[ -f "$root/build.gradle" || -f "$root/build.gradle.kts" ]]; then echo "gradle"
    else echo "unknown"
    fi
}

# Check whether the project already has Spotless wired up.
# Returns 0 (yes) / 1 (no).
has_spotless() {
    local root="$1"
    local tool="$2"
    case "$tool" in
        maven)
            grep -q "spotless-maven-plugin" "$root/pom.xml" 2>/dev/null
            ;;
        gradle)
            { [[ -f "$root/build.gradle"     ]] && grep -q "com.diffplug.spotless" "$root/build.gradle"     2>/dev/null; } || \
            { [[ -f "$root/build.gradle.kts" ]] && grep -q "com.diffplug.spotless" "$root/build.gradle.kts" 2>/dev/null; }
            ;;
        *)
            return 1
            ;;
    esac
}

# Check whether a file path should be handled by the current profile.
# Usage: profile_handles_file "/abs/path/to/Foo.java"
profile_handles_file() {
    local file="$1"
    local lang; lang="$(profile_language)"
    case "$lang" in
        java) [[ "$file" == *.java ]] ;;
        *)    return 1 ;;
    esac
}

# ---------- Hook payload extraction ----------
# Extract a field from a hook JSON payload (string on stdin or variable).
# Usage: extract_field <json> <jq_path>
# Example: extract_field "$INPUT" '.tool_input.file_path'
extract_field() {
    local json="$1"
    local path="$2"
    if [[ -z "$json" ]]; then
        echo ""
        return 0
    fi
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$json" | jq -r "$path // empty" 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        # Pass JSON via env var (not stdin) so heredoc doesn't clobber it.
        BUDDY_FMT_JSON="$json" BUDDY_FMT_PATH="$path" python3 <<'PY'
import json, os, sys
try:
    data = json.loads(os.environ.get('BUDDY_FMT_JSON', '') or '{}')
except json.JSONDecodeError:
    print('')
    sys.exit(0)
path = os.environ.get('BUDDY_FMT_PATH', '').lstrip('.').split('.')
cur = data
for key in path:
    if isinstance(cur, dict) and key in cur:
        cur = cur[key]
    else:
        cur = ''
        break
# Normalize Python literals to jq-style strings.
if cur is True: print('true')
elif cur is False: print('false')
elif cur is None: print('')
else: print(cur)
PY
    else
        echo ""
    fi
}
