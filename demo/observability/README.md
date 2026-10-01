# Local OpenTelemetry acceptance run

The CI acceptance run attaches the pinned OpenTelemetry Java agent to the
existing Open Liberty process, starts the pinned local Collector, and invokes
the same bounded `run-openliberty-acceptance.sh` lifecycle used by task 2.5.
It does not add an application dependency, change the Java EE 7 feature set, or
send telemetry to an external service.

From `demo/`, with Java 17, Docker, `curl`, and `sha256sum` available:

```sh
export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64/"
export ANT_HOME="/usr/share/ant"
export M2_HOME="/usr/share/maven"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"
PACKAGE_LOG="$(date -u +%Y%m%d-%H%M)-job-logs.txt"
./mvnw -Popenliberty -DskipTests clean package 2>&1 | tee "$PACKAGE_LOG"
cat "$PACKAGE_LOG"
./scripts/ci/run-observability-check.sh
```

The pinned agent version and SHA-256, plus the Collector image tag, are in
`versions.properties`. The observability script downloads and verifies
OpenTelemetry Java agent 2.31.1, runs
`otel/opentelemetry-collector-contrib:0.162.0-amd64` locally, and
ensures both services are stopped through exit cleanup. No Azure account, key,
or endpoint is used.

The telemetry artifact contains only JSON traces/metrics, a metadata-only
request transcript, bounded collector output, and a redaction result. Liberty
`messages.log` and `console.log` remain in the separate `liberty-logs`
artifact. The filtered access log contains only the two fixed-ID acceptance
requests; request/response bodies and environment dumps are not captured by
the observability harness. The Collector removes URL queries, database
statements/credentials, body fields, and authorization/cookie attributes from
resource, scope, span/event, datapoint, and exemplar attributes. The verifier
and final artifact gate reject forbidden fields and the seeded cargo identifier
across trace, metric, and complete uploaded-artifact files; a failed final scan
prevents telemetry and Liberty artifact uploads.
