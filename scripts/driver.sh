#!/usr/bin/env bash
set -euo pipefail
METHOD=${1:-score}
SUITE=${2:-all}

if [[ -z "${CLIENT_HOST:-}" ]]; then
  echo "CLIENT_HOST env-var not set" >&2
  exit 1
fi

ssh -o StrictHostKeyChecking=no ec2-user@"$CLIENT_HOST" \
  "~/bench/run_test_suite.sh $METHOD $SUITE"
