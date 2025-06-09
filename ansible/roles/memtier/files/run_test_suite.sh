#!/usr/bin/env bash
# Usage: run_test_suite.sh <score|perf> [suite-name]
set -euo pipefail
METHOD=${1:-score}
SUITE=${2:-all}
cd "$(dirname "$0")"
./all_test_suites.sh "$METHOD" "$SUITE"
