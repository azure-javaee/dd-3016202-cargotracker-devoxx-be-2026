#!/usr/bin/env bash

set -euo pipefail

SPIKE_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE="$(cd "${SPIKE_DIRECTORY}/../.." && pwd)"
DEMO_DIRECTORY="${DEMO_DIRECTORY:-${WORKTREE}/demo}"
RUN_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIRECTORY="${SPIKE_DIRECTORY}/reports/acceptance-${RUN_TIMESTAMP}"
LOG_DIRECTORY="${SPIKE_DIRECTORY}/logs"
BASE_URL="${BASE_URL:-http://127.0.0.1:8080/cargo-tracker}"
SERVER_MAY_BE_RUNNING=false

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/msopenjdk-17-amd64}"
export ANT_HOME="${ANT_HOME:-/usr/share/ant}"
export M2_HOME="${M2_HOME:-/usr/share/maven}"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

mkdir -p "${RUN_DIRECTORY}" "${LOG_DIRECTORY}"

run_maven() {
  local phase="$1"
  shift
  local log="${LOG_DIRECTORY}/${RUN_TIMESTAMP}-${phase}-job-logs.txt"
  local status

  set +e
  (
    cd "${DEMO_DIRECTORY}"
    ./mvnw --batch-mode --no-transfer-progress "$@"
  ) 2>&1 | tee "${log}"
  status="${PIPESTATUS[0]}"
  set -e

  return "${status}"
}

preserve_server_logs() {
  local server_logs="${DEMO_DIRECTORY}/target/liberty/wlp/usr/servers/defaultServer/logs"

  if [[ -f "${server_logs}/messages.log" ]]; then
    cp "${server_logs}/messages.log" "${RUN_DIRECTORY}/liberty-messages.log"
  fi
  if [[ -f "${server_logs}/console.log" ]]; then
    cp "${server_logs}/console.log" "${RUN_DIRECTORY}/liberty-console.log"
  fi
}

cleanup() {
  local status="$?"
  local stop_status=0

  trap - EXIT
  preserve_server_logs

  if [[ "${SERVER_MAY_BE_RUNNING}" == true ]]; then
    set +e
    run_maven stop liberty:stop
    stop_status="$?"
    set -e
    if [[ "${status}" -eq 0 && "${stop_status}" -ne 0 ]]; then
      status="${stop_status}"
    fi
  fi

  exit "${status}"
}
trap cleanup EXIT

probe() {
  local name="$1"
  local path="$2"
  shift 2
  local headers="${RUN_DIRECTORY}/${name}.headers"
  local body="${RUN_DIRECTORY}/${name}.body"
  local status
  local expected

  status="$(
    curl \
      --silent \
      --show-error \
      --max-time 20 \
      --dump-header "${headers}" \
      --output "${body}" \
      --write-out '%{http_code}' \
      "${BASE_URL}${path}"
  )"

  if [[ "${status}" != "200" ]]; then
    printf '%s returned HTTP %s, expected 200\n' "${path}" "${status}" >&2
    return 1
  fi

  for expected in "$@"; do
    if ! grep --fixed-strings --quiet "${expected}" "${body}"; then
      printf '%s did not contain expected text: %s\n' "${path}" "${expected}" >&2
      return 1
    fi
  done

  printf 'PASS\t%s\tHTTP 200\t%s\n' "${path}" "$*" \
    >> "${RUN_DIRECTORY}/summary.tsv"
}

if curl --silent --max-time 2 "${BASE_URL}/" >/dev/null; then
  printf 'Refusing to run because %s is already responding.\n' "${BASE_URL}" >&2
  exit 1
fi

printf 'result\tpath\tstatus\tevidence\n' > "${RUN_DIRECTORY}/summary.tsv"

run_maven package -DskipTests clean package
run_maven deploy liberty:deploy

SERVER_MAY_BE_RUNNING=true
run_maven start \
  -Dapplications=cargo-tracker \
  -DserverStartTimeout=90 \
  liberty:start

messages_log="${DEMO_DIRECTORY}/target/liberty/wlp/usr/servers/defaultServer/logs/messages.log"
grep --fixed-strings --quiet \
  "is ready to run a smarter planet" \
  "${messages_log}"
grep --extended-regexp --quiet \
  "CWWKZ0001I.*Application cargo-tracker started" \
  "${messages_log}"

ready=false
for _ in $(seq 1 60); do
  if curl \
    --silent \
    --fail \
    --max-time 2 \
    "${BASE_URL}/rest/cargo" |
      grep --fixed-strings --quiet '"trackingId":"ABC123"'; then
    ready=true
    break
  fi
  sleep 1
done

if [[ "${ready}" != true ]]; then
  printf '%s/rest/cargo did not become ready within 60 seconds.\n' \
    "${BASE_URL}" >&2
  exit 1
fi

probe root "/" "Cargo Tracker"
probe dashboard "/admin/dashboard.xhtml" "Cargo Dashboard" "ABC123"
probe cargo-rest "/rest/cargo" \
  '"trackingId":"ABC123"' \
  '"trackingId":"DEF789"' \
  '"trackingId":"JKL567"' \
  '"trackingId":"MNO456"'

if ! grep --ignore-case --quiet '^Content-Type: application/json' \
  "${RUN_DIRECTORY}/cargo-rest.headers"; then
  printf '/rest/cargo did not return application/json.\n' >&2
  exit 1
fi

printf 'PASS\t/rest/cargo\tContent-Type\tapplication/json\n' \
  >> "${RUN_DIRECTORY}/summary.tsv"

printf 'Acceptance lifecycle passed. Evidence: %s\n' "${RUN_DIRECTORY}"
