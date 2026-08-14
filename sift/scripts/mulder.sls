# Name: Mulder
# Website: https://github.com/calebevans/mulder
# Description: Autonomous DFIR platform that analyses disk images, memory dumps, PCAPs and event logs, producing incident reports with MITRE ATT&CK mappings and IOC exports.
# Category:
# Author: Caleb Evans
# License: Apache License 2.0 (https://github.com/calebevans/mulder/blob/main/LICENSE)
# Notes: no binaries on $PATH -- the image is run directly, see the usage guide
#
# Upstream distributes mulder only as a container image, so this state fetches that image
# at build time. Nothing is placed on $PATH; run it as upstream documents:
#
#   docker run -it --cap-add SYS_ADMIN --device /dev/fuse \
#     -v /cases:/evidence:ro \
#     -v ~/mulder-cases:/home/mulder/.mulder/cases \
#     -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
#     ghcr.io/calebevans/mulder:1.3.2
#   mulder investigate /evidence my-case
#
# Upstream documents --privileged for the FUSE-backed tools (ewfmount, guestmount); the
# narrower '--cap-add SYS_ADMIN --device /dev/fuse' grant above is their documented
# alternative. Mulder needs an LLM provider credential and sends evidence content to
# whichever provider is configured.
#
# The image is ~3.6 GB compressed (47 layers) and multi-arch (amd64 + arm64), so no arch
# guard is needed. Pulling requires a running docker daemon, which means this state cannot
# be applied inside the CI tester container -- see AGENTS.md.
#
# Docs: https://github.com/calebevans/mulder/blob/main/docs/usage-guide.md

{# renovate: datasource=docker depName=ghcr.io/calebevans/mulder #}
{%- set version = "1.3.2" -%}
{%- set hash = "sha256:df1b40ab5f8368fc077a9db5bea5e98a186b3dedecccb6e8fcbbbc87fdd78203" -%}
{%- set repo = "ghcr.io/calebevans/mulder" -%}

include:
  - sift.packages.docker

sift-scripts-mulder-docker-service:
  service.running:
    - name: docker
    - enable: True
    - require:
      - sls: sift.packages.docker

# Pinned by digest rather than tag so the fetched image is immutable, matching how the
# rest of the tree pins downloads. The digest is the multi-arch index, so it resolves on
# both amd64 and arm64.
sift-scripts-mulder-image:
  cmd.run:
    - name: docker pull {{ repo }}@{{ hash }}
    - unless: docker image inspect {{ repo }}@{{ hash }} > /dev/null 2>&1
    - timeout: 3600
    - require:
      - service: sift-scripts-mulder-docker-service

# Pulling by digest leaves the image untagged; tag it so the documented
# `docker run ghcr.io/calebevans/mulder:{{ version }}` works.
sift-scripts-mulder-image-tag:
  cmd.run:
    - name: docker tag {{ repo }}@{{ hash }} {{ repo }}:{{ version }}
    - unless: docker image inspect {{ repo }}:{{ version }} > /dev/null 2>&1
    - require:
      - cmd: sift-scripts-mulder-image
