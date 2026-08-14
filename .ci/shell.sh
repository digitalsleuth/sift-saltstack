#!/bin/bash
#
# Drop into an interactive shell in the tester image with the state tree mounted,
# for poking at a state by hand.
#
#   .ci/shell.sh
#   OS=24.04 SALT=3006 .ci/shell.sh
#
# Inside the container:
#
#   salt-call --local -l debug --file-root . --state-output=mixed \
#     state.sls sift.packages.aeskeyfind pillar='{sift_user: root}'
#
# Must be run from the repository root. Port 8080 maps to container port 80 so
# states that stand up apache (cyberchef) can be checked in a browser.

set -euo pipefail

OS=${OS:-22.04}
SALT=${SALT:-3007}
DOCKER=${DOCKER:-docker}
IMAGE=ghcr.io/ekristen/cast-tools/saltstack-tester:${OS}-${SALT}

if [ ! -d sift ]; then
  echo "Error: run this from the repository root (no ./sift directory here)." >&2
  exit 1
fi

exec "$DOCKER" run --rm -it \
  -v "$PWD:/srv/salt" \
  -w /srv/salt \
  -p 8080:80 \
  --cap-add SYS_ADMIN \
  "$IMAGE" \
  /bin/bash
