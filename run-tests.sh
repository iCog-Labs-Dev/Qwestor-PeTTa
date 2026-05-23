#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# run-tests.sh — MeTTa/PeTTa test runner for Qwestor-PeTTa
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────
# run-tests.sh  —  PeTTa test runner
#
# Usage:
#   ./run-tests.sh                  run all test files
#   ./run-tests.sh --file <path>    run a single test file
#   ./run-tests.sh --verbose        show full PeTTa compiler output
# ─────────────────────────────────────────────

echo "🚀 Starting PeTTa-Qwestor Transpiled Tests..."

# ─────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────
PETTA_ROOT="${PETTA_ROOT:-/c/Users/tby/PeTTa}"
RUN_SH="$PETTA_ROOT/run.sh"

if [ ! -f "$RUN_SH" ]; then
    echo "❌ PeTTa runtime not found at: $RUN_SH"
    echo "   export PETTA_ROOT=/path/to/PeTTa"
    exit 1
fi

echo "📦 Using PeTTa runtime: $RUN_SH"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Project root: $PROJECT_ROOT"

# ─────────────────────────────────────────────
# FLAGS
# ─────────────────────────────────────────────
VERBOSE=false
SINGLE_FILE=""

for arg in "$@"; do
    case "$arg" in
        --verbose) VERBOSE=true ;;
        --file)    shift; SINGLE_FILE="$1" ;;
    esac
done

# Filter out PeTTa compiler noise unless --verbose.
# Keeps: test result lines, println! output, errors.
filter_output() {
    if $VERBOSE; then
        cat
    else
        sed 's/\x1b\[[0-9;]*m//g' | \
        grep -E '(✅ Passed:|❌ Failed:|is .*, should .*\. ❌|^ERROR:)'
    fi
}

# ─────────────────────────────────────────────
# Run one test file from its own directory
# ─────────────────────────────────────────────
run_test() {
    local abs_file="$1"
    local file_dir file_name TEMP

    file_dir="$(dirname "$abs_file")"
    file_name="$(basename "$abs_file")"
    TEMP=$(mktemp "$file_dir/petta_tmp_XXXXXX.metta")

    cat "$abs_file" > "$TEMP"

    (cd "$file_dir" && "$RUN_SH" "$(basename "$TEMP")" 2>&1) | filter_output
    local EXIT="${PIPESTATUS[0]}"

    rm -f "$TEMP"
    return $EXIT
}

# ─────────────────────────────────────────────
# --file mode
# ─────────────────────────────────────────────
if [[ -n "$SINGLE_FILE" ]]; then
    ABS_FILE="$(cd "$(dirname "$SINGLE_FILE")" && pwd)/$(basename "$SINGLE_FILE")"
    if [[ ! -f "$ABS_FILE" ]]; then
        echo "❌ File not found: $SINGLE_FILE"
        exit 1
    fi
    echo "▶ Running: $SINGLE_FILE"
    run_test "$ABS_FILE"
    EXIT=$?
    [[ $EXIT -eq 0 ]] && echo "✅ Passed" || echo "❌ Failed (exit $EXIT)"
    exit $EXIT
fi

# ─────────────────────────────────────────────
# Collect test files
# ─────────────────────────────────────────────
mapfile -t ALL_FILES < <(find "$PROJECT_ROOT" -path "*/test/*.metta" | sort -u)

TEST_FILES=()
for f in "${ALL_FILES[@]}"; do
        TEST_FILES+=("$f")
done

if [ ${#TEST_FILES[@]} -eq 0 ]; then
    echo "⚠️  No test files found."
    exit 0
fi

echo "Found ${#TEST_FILES[@]} test file(s)."

FAILED=0
FAILED_FILES=()
COUNT=0

# ─────────────────────────────────────────────
# Run all tests
# ─────────────────────────────────────────────
for file in "${TEST_FILES[@]}"; do
    DISPLAY="${file#$PROJECT_ROOT/}"
    echo "================================================"
    echo "▶ $DISPLAY"
    echo "------------------------------------------------"

    run_test "$file"
    EXIT=$?

    if [[ $EXIT -eq 0 ]]; then
        echo "✅ Passed: $DISPLAY"
    else
        echo "❌ Failed: $DISPLAY (exit $EXIT)"
        FAILED=$((FAILED + 1))
        FAILED_FILES+=("$DISPLAY")
    fi

    COUNT=$((COUNT + 1))
done

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo "================================================"
echo "Ran $COUNT file(s). Passed: $((COUNT - FAILED)). Failed: $FAILED."

if [ $FAILED -ne 0 ]; then
    echo ""
    echo "Failed files:"
    for f in "${FAILED_FILES[@]}"; do
        echo "  ✗ $f"
    done
    exit 1
fi

echo "✨ All tests passed!"