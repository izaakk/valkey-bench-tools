#!/usr/bin/env bash
set -euo pipefail
METHOD=$1
REQUESTED_SUITE=${2:-all}

SUITE_FILE="$(dirname "$0")/test_suites.txt"
if [[ ! -f $SUITE_FILE ]]; then
  echo "Test suite file $SUITE_FILE not found" >&2
  exit 1
fi
SUITES="$(cat "$SUITE_FILE")"

run_suite() {
  local name=$1
  local cmd=$2
  echo "Running $name with method $METHOD"
  eval "$cmd"
}

current_name=""
while IFS= read -r line; do
  if [[ $line == name:=* ]]; then
    current_name=${line#name:=}
  elif [[ $line == test_commands:=* ]]; then
    cmd=${line#test_commands:=}
    if [[ $REQUESTED_SUITE == all || $REQUESTED_SUITE == $current_name ]]; then
      run_suite "$current_name" "$cmd"
    fi
  fi
done <<< "$SUITES"
