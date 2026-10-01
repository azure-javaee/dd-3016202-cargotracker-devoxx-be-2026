# Bounded JVM performance evidence

The comparison runs direct Microsoft OpenJDK 17, `jaz` 1.0.4 with
`JAZ_BYPASS=1`, and tuned `jaz` on one non-containerized Linux runner. It
builds the WAR and Liberty runtime through the existing build, deploys that WAR
once, snapshots the deployed `defaultServer`, and restores the snapshot before
each launch.

`run-negative-controls.sh` verifies that user heap tuning,
`JAZ_IGNORE_USER_TUNING`, and externally supplied bypass/dry-run modes are
rejected before the harness downloads `jaz` or launches Liberty.

From `demo/`, with the repository's Java 17 environment and `curl`, `dpkg-deb`,
`sha256sum`, `jcmd`, and `jfr` available:

```sh
export JAVA_HOME="/usr/lib/jvm/msopenjdk-17-amd64/"
export ANT_HOME="/usr/share/ant"
export M2_HOME="/usr/share/maven"
export PATH="${M2_HOME}/bin:${ANT_HOME}/bin:${JAVA_HOME}/bin:${PATH}"
PACKAGE_LOG="$(date -u +%Y%m%d-%H%M)-job-logs.txt"
./mvnw -Popenliberty -DskipTests clean package 2>&1 | tee "$PACKAGE_LOG"
cat "$PACKAGE_LOG"
./performance/run-workload.sh
```

The workflow uses its already packaged WAR and runtime and invokes
`run-workload.sh` after task 2.6 observability evidence. The harness downloads
the amd64 Debian package from Microsoft's Ubuntu 24.04 repository, verifies
SHA-256
`3d479f11ff2a037790505746a44568e1408f2f79aac62300ea4c651c4969a710`, and
extracts it into disposable scratch space without changing the runner package
database. Only the mirrored JDK's `bin/java` is replaced. Liberty receives the
mirror in `server.env`; Maven, `jcmd`, and `jfr` continue to use the real JDK.
Both `jaz` modes set `JAZ_EXIT_WITHOUT_FLUSH=1`; bypass also sets
`JAZ_BYPASS=1`. `JAZ_IGNORE_USER_TUNING` is prohibited.

## Fixed workload and evidence

Five cycles run sequentially in this order:

| Cycle | Order |
|---:|---|
| 1 | direct, bypass, tuned |
| 2 | bypass, tuned, direct |
| 3 | tuned, direct, bypass |
| 4 | direct, tuned, bypass |
| 5 | bypass, direct, tuned |

Every launch waits for HTTP 200 JSON readiness and validates the seeded cargo
response, makes five warm-up requests, dynamically starts the same redacted
10-second JFR profile, then makes 30 sequential requests paced at 200 ms.
Each request has a 10-second timeout. Response bodies are validated in
temporary files and are not retained in artifacts.

The scripts record runner CPU, memory, OS, kernel and cgroup view; checksums
for the WAR, Liberty runtime, pristine server, workload, JFR profile and host
record; process-launch-to-readiness time; request distributions; 200-ms RSS
and CPU samples; heap before and after measured work; server-PID-specific GC
logs; JFR and its parsed summary; effective JVM command and flags; process
ancestry; start/stop logs; exit status; and cleanup outcome. The JFR profile
disables JVM information, initial system properties, OS information, initial
environment variables, and system-process events. Every completed recording
must report zero events of those five types before artifact upload. Task 2.6 OpenTelemetry and
Liberty artifacts from the same workflow job/runner are retained as
diagnostic context, not misrepresented as measurements from these individual
processes.

The sampler identifies and publishes the unique server PID while Maven startup
is still running, excludes Liberty's transient `--pid`/`--status` helper JVMs,
and rejects any subsequent PID change or duplicate. This captures startup RSS
and CPU as well as steady-state resource use. Diagnostic GC logging is passed
as a `liberty.jvm.*` Maven property so the Liberty Maven plugin applies it after
refreshing server configuration; the harness confirms the exact option in
`jcmd VM.command_line` before accepting the GC log.

Tuned `jaz` must report its selected heap and G1 policy in both the captured
`JAZ_DRY_RUN=1` output and effective JVM flags. Direct and bypass modes must
retain the same default heap/G1 policy; bypass still records `jaz` diagnostics,
including native-memory tracking and its error-file setting. User-supplied
heap, GC, processor-count, compiler-count, or startup-recording options are
rejected. Positive initial- and maximum-heap values are required for every
direct and bypass run and must remain identical between those modes.

CI fails for startup beyond 90 seconds, failed readiness or workload requests,
crash/OOM, repetition beyond 120 seconds, peak sampled RSS above 2 GiB, missing
or unparseable required diagnostics, artifact mismatch, or cleanup failure.
Each repetition has a 105-second watchdog that reserves 15 seconds for
signal-driven cleanup, and the immutable WAR, runtime, server template,
workload, and JFR profile are rehashed immediately before every launch.
Ordinary differences in startup, request latency, CPU, heap, RSS, or GC are
reported but are not performance thresholds or winner criteria.

The four 90-day artifacts are `performance-java`,
`performance-jaz-bypassed`, `performance-jaz-tuned`, and
`performance-comparison`. They contain run summaries and checksummed metadata,
not the WAR, Liberty installation, package binary, response bodies, raw
environment dumps, or caches. Upload is gated by a final redaction scan after
the checksummed metadata has been generated and by zero-sensitive-event
verification of every retained JFR, including recordings from failed runs.
