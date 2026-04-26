#!/usr/bin/env bash
# ============================================================================
#  formatter — smoke tests
#
#  Verifies routing, env-var toggles, and recursion guard without actually
#  invoking Maven/Gradle.
#
#  Run:
#    ./tests/smoke.sh
# ============================================================================
set -uo pipefail

# Resolve plugin root regardless of CWD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FORMAT_SH="$CLAUDE_PLUGIN_ROOT/scripts/format.sh"
CHECK_SH="$CLAUDE_PLUGIN_ROOT/scripts/check.sh"

PASS=0
FAIL=0
pass() { echo "  ✅ $*"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $*"; FAIL=$((FAIL+1)); }

# Scratch sandbox
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# -------- Test 1: profile does not handle non-Java file --------
echo "Test 1: non-Java file is skipped (profile java-alipay)"
OUTPUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"'"$WORK"'/README.md"}}' \
    | bash "$FORMAT_SH" 2>&1)
RC=$?
[[ $RC -eq 0 ]] && pass "exit code 0" || fail "expected rc=0, got $RC"
[[ -z "$OUTPUT" ]] && pass "no output" || fail "unexpected output: $OUTPUT"

# -------- Test 2: Java file outside any project --------
echo "Test 2: Java file outside Maven/Gradle project"
mkdir -p "$WORK/lonely"
touch "$WORK/lonely/Orphan.java"
OUTPUT=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$WORK"'/lonely/Orphan.java"}}' \
    | bash "$FORMAT_SH" 2>&1)
RC=$?
[[ $RC -eq 0 ]] && pass "exit code 0 (non-blocking)" || fail "expected rc=0, got $RC"
echo "$OUTPUT" | grep -q "could not find pom.xml" \
    && pass "emits 'not a project' warning" \
    || fail "missing expected warning, got: $OUTPUT"

# -------- Test 3: Java file in Maven project without Spotless --------
echo "Test 3: Java in Maven project w/o Spotless"
mkdir -p "$WORK/myproj/src/main/java/com/example"
cat >"$WORK/myproj/pom.xml" <<'EOF'
<?xml version="1.0"?>
<project><modelVersion>4.0.0</modelVersion>
  <groupId>x</groupId><artifactId>y</artifactId><version>1</version>
</project>
EOF
touch "$WORK/myproj/src/main/java/com/example/Foo.java"
OUTPUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"'"$WORK"'/myproj/src/main/java/com/example/Foo.java"}}' \
    | bash "$FORMAT_SH" 2>&1)
RC=$?
[[ $RC -eq 0 ]] && pass "exit code 0" || fail "expected rc=0, got $RC"
echo "$OUTPUT" | grep -q "Spotless is not configured" \
    && pass "prompts for /formatter:setup" \
    || fail "expected setup hint, got: $OUTPUT"
echo "$OUTPUT" | grep -q "/formatter:setup" \
    && pass "mentions new slash command name" \
    || fail "slash command name not updated in output: $OUTPUT"

# -------- Test 4: DISABLED env var short-circuits --------
echo "Test 4: BUDDY_FORMATTER_DISABLED=1 short-circuits"
OUTPUT=$(BUDDY_FORMATTER_DISABLED=1 \
    bash "$FORMAT_SH" <<<'{"tool_name":"Edit","tool_input":{"file_path":"/tmp/X.java"}}' 2>&1)
RC=$?
[[ $RC -eq 0 && -z "$OUTPUT" ]] && pass "silent exit 0" \
    || fail "expected silent rc=0, got rc=$RC output=$OUTPUT"

# -------- Test 5: Stop hook honors stop_hook_active --------
echo "Test 5: Stop hook avoids recursion when stop_hook_active=true"
OUTPUT=$(echo '{"stop_hook_active":true}' | bash "$CHECK_SH" 2>&1)
RC=$?
[[ $RC -eq 0 ]] && pass "exit 0 on recursion signal" \
    || fail "expected rc=0, got $RC"

# -------- Test 6: profile selection via BUDDY_FORMATTER_PROFILE --------
echo "Test 6: unknown profile gracefully skips (no-op)"
OUTPUT=$(BUDDY_FORMATTER_PROFILE=bogus-profile \
    bash "$FORMAT_SH" <<<'{"tool_name":"Edit","tool_input":{"file_path":"/tmp/X.java"}}' 2>&1)
RC=$?
# Unknown profile → profile_language returns 'unknown' → profile_handles_file
# returns false → file skipped silently. We just care that it doesn't blow up.
[[ $RC -eq 0 ]] && pass "unknown profile exits cleanly" \
    || fail "expected rc=0, got $RC | output=$OUTPUT"

# -------- Summary --------
echo ""
echo "============================================"
echo " $PASS passed, $FAIL failed"
echo "============================================"
[[ $FAIL -eq 0 ]]
