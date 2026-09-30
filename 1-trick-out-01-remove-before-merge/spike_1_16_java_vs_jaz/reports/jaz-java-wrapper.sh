#!/usr/bin/env bash

set -euo pipefail

jaz_binary="/home/edburns/workareas/dd-3016202-cargotracker-devoxx-be-2026-02/1-trick-out-01-remove-before-merge/spike_1_16_java_vs_jaz/scratch/jaz-install/usr/bin/jaz"
mode="${JAZ_WRAPPER_MODE:?}"
invocations="${JAZ_WRAPPER_INVOCATIONS:?}"
dry_run_output="${JAZ_WRAPPER_DRY_RUN_OUTPUT:-}"

{
  printf '%s\t%s\t%s\t' "$(date +%s%3N)" "$$" "${PPID}"
  printf '%q ' "$@"
  printf '\n'
} >> "${invocations}"

arguments=" $* "
if [[ "${mode}" == tuned &&
      "${arguments}" == *"ws-server.jar"* &&
      "${arguments}" != *" --status"* &&
      "${arguments}" != *" --stop"* &&
      "${arguments}" != *" --version"* &&
      -n "${dry_run_output}" ]] &&
  mkdir "${dry_run_output}.lock" 2>/dev/null; then
  set +e
  JAZ_DRY_RUN=1 "${jaz_binary}" "$@" > "${dry_run_output}" 2>&1
  dry_run_status="$?"
  set -e
  printf '%s\n' "${dry_run_status}" > "${dry_run_output}.status"
  if [[ "${dry_run_status}" -ne 1 ]]; then
    printf 'Expected jaz dry run to exit 1, got %s\n'       "${dry_run_status}" >&2
    exit 1
  fi
fi

exec "${jaz_binary}" "$@"
