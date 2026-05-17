#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# run-tests.sh — MeTTa/PeTTa test runner for Qwestor-PeTTa
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
# PETTA_DIR can be overridden at call time:  PETTA_DIR=/my/petta bash run-tests.sh
PETTA_DIR="${PETTA_DIR:-$HOME/PeTTa}"
PETTA_RUN="$PETTA_DIR/run.sh"

if [ ! -f "$PETTA_RUN" ]; then
  echo "❌ PeTTa runner not found at: $PETTA_RUN"
  echo "   Set PETTA_DIR to the correct path and retry."
  exit 1
fi

# ── Test discovery ────────────────────────────────────────────────────────────
# Matches the two conventions used in this repo:
#   • files inside any directory named "test/"  (*/test/*.metta)
#   • files whose name ends with "-test.metta"  (*-test.metta)
mapfile -t TESTS < <(find . \( -path "*/test/*.metta" -o -name "*-test.metta" \) | sort)

if [ ${#TESTS[@]} -eq 0 ]; then
  echo "⚠️  No test files found"
  exit 0
fi

# ── Counters (must live in this shell, not a subshell) ────────────────────────
TOTAL=0
PASSED=0
FAILED=0
FAILED_FILES=()

echo "🚀 Running ${#TESTS[@]} MeTTa test file(s)..."
echo "================================================"

# ── Main loop ─────────────────────────────────────────────────────────────────
for file in "${TESTS[@]}"; do
  TOTAL=$((TOTAL + 1))
  printf "▶  %s\n" "$file"

  # Capture all output (stdout + stderr merged).
  # "|| true" prevents set -e from aborting on non-zero exit; PeTTa exits 0
  # even on failures, but future PeTTa versions might not.
  RAW=$(bash "$PETTA_RUN" "$file" 2>&1) || true

  # ── Signal extraction ──────────────────────────────────────────────────────
  # The !(test expected actual) macro emits exactly one of:
  #   "   is <val>, should <val>. ✅ "
  #   "   is <val>, should <val>. ❌ "
  # Nothing else in PeTTa output contains these emoji, so this grep is safe.
  TEST_LINES=$(printf '%s\n' "$RAW" | grep -E '^\s*is .*, should .*\.(✅|❌)\s*$' || true)

  # ── Section markers ────────────────────────────────────────────────────────
  # Our test files use  !(println! "=== TEST N: ... ===")
  # PeTTa echoes the string back as:  "=== TEST N: ... ==="
  # Showing these makes it obvious which group a failure belongs to.
  MARKER_LINES=$(printf '%s\n' "$RAW" | grep -E '^"(===|TEST )' || true)

  if [ -n "$MARKER_LINES" ]; then
    printf '%s\n' "$MARKER_LINES" | sed 's/^/   /'
  fi

  # ── Failure detection ──────────────────────────────────────────────────────
  # Print every failed assertion (❌ lines) so the developer sees exactly
  # what was wrong without having to rerun with verbose output.
  FAIL_LINES=$(printf '%s\n' "$TEST_LINES" | grep '❌' || true)
  FAIL_COUNT=$(printf '%s\n' "$FAIL_LINES" | grep -c '❌' || true)

  if [ -n "$FAIL_LINES" ]; then
    printf '%s\n' "$FAIL_LINES" | sed 's/^/   /'
  fi

  # ── Result summary for this file ──────────────────────────────────────────
  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "   ❌ FAILED ($FAIL_COUNT assertion(s) failed)"
    FAILED=$((FAILED + 1))
    FAILED_FILES+=("$file")
  else
    PASS_COUNT=$(printf '%s\n' "$TEST_LINES" | grep -c '✅' || true)
    echo "   ✅ PASSED ($PASS_COUNT assertions)"
    PASSED=$((PASSED + 1))
  fi

  echo "------------------------------------------------"
done

# ── Final summary ─────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASSED/$TOTAL passed"

if [ $FAILED -gt 0 ]; then
  echo "❌ $FAILED file(s) with failures:"
  for f in "${FAILED_FILES[@]}"; do
    echo "   • $f"
  done
  exit 1
fi

echo "✨ All tests passed!"