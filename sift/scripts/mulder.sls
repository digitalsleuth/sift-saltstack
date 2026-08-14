# Name: Mulder
# Website: https://github.com/calebevans/mulder
# Description: Autonomous DFIR platform that analyses disk images, memory dumps, PCAPs and event logs, producing incident reports with MITRE ATT&CK mappings and IOC exports.
# Category:
# Author: Caleb Evans
# License: Apache License 2.0 (https://github.com/calebevans/mulder/blob/main/LICENSE)
# Notes: mulder
#
# Mulder is distributed only as a container image (~3.6 GB compressed), so this state
# installs a wrapper that runs it rather than baking the image into SIFT. The image is
# pulled by docker on first invocation.
#
# The wrapper uses the narrower '--cap-add SYS_ADMIN --device /dev/fuse' grant that
# upstream documents as the alternative to --privileged; both exist to let FUSE-based
# tools (ewfmount, guestmount) work. Pass --privileged via MULDER_DOCKER_ARGS if a
# tool needs more than that.
#
# Requires an LLM provider credential in the environment; evidence content is sent to
# whichever provider is configured.

{# renovate: datasource=docker depName=ghcr.io/calebevans/mulder #}
{%- set version = "1.3.2" -%}
{%- set image = "ghcr.io/calebevans/mulder:" ~ version -%}

include:
  - sift.packages.docker

sift-scripts-mulder:
  file.managed:
    - name: /usr/local/bin/mulder
    - mode: 755
    - replace: True
    - require:
      - sls: sift.packages.docker
    - contents: |
        #!/bin/bash
        #
        # SIFT wrapper for the mulder container.
        # Managed by sift.scripts.mulder -- local edits will be overwritten.
        #
        #   mulder investigate /evidence my-case
        #   mulder export-iocs my-case --format stix
        #   mulder                       # no args: interactive shell in the container
        #
        # Env:
        #   MULDER_EVIDENCE     host dir mounted read-only at /evidence (default /cases)
        #   MULDER_CASES        host dir for case output   (default ~/mulder-cases)
        #   MULDER_IMAGE        override the pinned image
        #   MULDER_DOCKER_ARGS  extra args for docker run, e.g. --privileged
        #
        # Docs: https://github.com/calebevans/mulder/blob/main/docs/usage-guide.md
        set -euo pipefail

        IMAGE="${MULDER_IMAGE:-{{ image }}}"
        EVIDENCE="${MULDER_EVIDENCE:-/cases}"
        CASES="${MULDER_CASES:-$HOME/mulder-cases}"

        if [ ! -d "$EVIDENCE" ]; then
          echo "mulder: evidence directory '$EVIDENCE' does not exist." >&2
          echo "        Set MULDER_EVIDENCE to your evidence path." >&2
          exit 1
        fi

        # Pass through whichever provider credentials are present. Values are read from
        # the environment rather than baked in, so nothing is written to disk.
        env_args=()
        have_creds=0
        for var in ANTHROPIC_API_KEY \
                   CLAUDE_CODE_USE_VERTEX CLOUD_ML_REGION ANTHROPIC_VERTEX_PROJECT_ID \
                   GOOGLE_APPLICATION_CREDENTIALS \
                   CLAUDE_CODE_USE_BEDROCK AWS_REGION AWS_ACCESS_KEY_ID \
                   AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN \
                   OPENAI_API_KEY ANTHROPIC_BASE_URL; do
          if [ -n "${!var:-}" ]; then
            env_args+=(-e "$var=${!var}")
            case "$var" in
              *API_KEY|CLAUDE_CODE_USE_VERTEX|CLAUDE_CODE_USE_BEDROCK) have_creds=1 ;;
            esac
          fi
        done

        if [ "$have_creds" -eq 0 ]; then
          echo "mulder: no LLM provider credentials found in the environment." >&2
          echo "        Set ANTHROPIC_API_KEY, or the Vertex/Bedrock/LiteLLM equivalents." >&2
          echo "        See https://github.com/calebevans/mulder/blob/main/docs/usage-guide.md" >&2
          exit 1
        fi

        mkdir -p "$CASES"

        # -t only when stdin is a terminal, so the wrapper works in scripts and pipelines.
        tty_args=(-i)
        if [ -t 0 ]; then tty_args=(-i -t); fi

        extra_args=()
        if [ -n "${MULDER_DOCKER_ARGS:-}" ]; then
          read -r -a extra_args <<< "$MULDER_DOCKER_ARGS"
        fi

        cmd_args=()
        if [ "$#" -gt 0 ]; then cmd_args=(mulder "$@"); fi

        exec docker run --rm "${tty_args[@]}" \
          --cap-add SYS_ADMIN --device /dev/fuse \
          -v "$EVIDENCE:/evidence:ro" \
          -v "$CASES:/home/mulder/.mulder/cases" \
          "${env_args[@]}" \
          ${extra_args[@]+"${extra_args[@]}"} \
          "$IMAGE" \
          ${cmd_args[@]+"${cmd_args[@]}"}
