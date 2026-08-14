#!/bin/bash
#
# Apply a single Salt state in the same tester image CI uses.
#
#   .ci/test-state.sh sift.packages.aeskeyfind
#   OS=24.04 SALT=3006 .ci/test-state.sh sift.scripts.zimmerman
#
# Must be run from the repository root.

set -euo pipefail

OS=${OS:-22.04}
SALT=${SALT:-3007}
DOCKER=${DOCKER:-docker}
IMAGE=ghcr.io/ekristen/cast-tools/saltstack-tester:${OS}-${SALT}

if [ $# -lt 1 ]; then
  echo "Usage: $0 <state> [salt-call args...]" >&2
  echo "Example: $0 sift.packages.aeskeyfind" >&2
  exit 1
fi

STATE=$1
shift

if [ ! -d sift ]; then
  echo "Error: run this from the repository root (no ./sift directory here)." >&2
  exit 1
fi

exec "$DOCKER" run --rm -it \
  -v "$PWD:/srv/salt" \
  -w /srv/salt \
  --cap-add SYS_ADMIN \
  "$IMAGE" \
  salt-call --local -l info --file-root . --retcode-passthrough \
    --state-output=mixed state.sls "$STATE" pillar='{sift_user: root}' "$@"
