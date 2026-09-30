# Spike 1.15: Repeatable performance workload and resource envelope

Date: 2026-09-30

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.15.

## Decision

Select a non-containerized, diagnostic workload built on the Open Liberty
lifecycle established in section 1.13.

Build and deploy the WAR once. For each independent repetition:

1. restore a pristine `defaultServer` directory;
2. start Liberty with the Maven plugin;
3. measure from launch invocation through a successful seeded REST response;
4. send five unmeasured warm-up requests;
5. start a 10-second JFR dynamically with `jcmd`;
6. send 30 measured sequential requests to
   `/cargo-tracker/rest/cargo`, paced by 200 milliseconds;
7. capture JVM, process, heap, GC, JFR, HTTP, Liberty, and timing evidence;
8. stop Liberty and verify cleanup.

Use five repetitions for the initial direct-`java` baseline and for each launch
mode compared by section 1.16. Do not use a container, synthetic cgroup,
fixed heap, processor-count override, or other JVM tuning flag as part of this
workload contract.

This workload is repeatable for functional and diagnostic evidence. It is not
stable enough to support narrow latency, startup, CPU, heap, or GC regression
thresholds on a shared or hosted machine.

## Environment

The final spike ran against commit
`cf19be6029aad88ce792e544cc4dd8135867723f` with:

- Microsoft Build of OpenJDK 17.0.18;
- Maven Wrapper 3.9.9;
- Liberty Maven Plugin 3.12.1;
- Open Liberty 26.0.0.8;
- eight visible processors;
- approximately 16 GiB of host memory;
- a WSL2 Linux VM with cgroup v2 membership `/init.scope`;
- no Docker/OCI runtime or synthetic cgroup limits.

The WAR SHA-256 was:

```text
6a238acffd4938b52fe49a00cd41cc599774e937bcdcedc348a94d6821b0780d
```

The harness records the complete environment and cgroup view in
`reports/environment.txt`. These measurements establish the workload and its
local noise floor. The implementation issue must run the unchanged harness on
the GitHub-hosted runner before treating runner-specific gross bounds as
required CI policy.

## Workload contract

| Property | Selected value |
|---|---|
| Artifact | One prebuilt `cargo-tracker.war` and one Open Liberty runtime |
| Freshness | Restore a pristine server directory for each repetition |
| Readiness | HTTP 200 from `/cargo-tracker/rest/cargo` containing `ABC123` |
| Warm-up | 5 sequential validated requests |
| Measured workload | 30 sequential validated requests |
| Pacing | 200 ms after each measured request |
| Concurrency | 1 |
| Startup bound | 90 seconds |
| Request timeout | 10 seconds |
| JFR | 10 seconds, started dynamically after warm-up |
| Repetitions | 5 per launch mode |
| Shutdown | `liberty:stop`, required after every repetition |
| Containerization | None |

The exact machine-readable contract is in
`reports/workload-contract.txt`.

## Results

All five repetitions:

- started Liberty successfully;
- returned all 30 measured HTTP responses with status 200 and seeded content;
- produced process samples, JVM command lines, complete flag inventories,
  heap summaries, a server-PID-specific GC log, a parseable JFR, and Liberty
  logs;
- stopped Liberty successfully;
- removed the disposable clone.

### Run results

| Run | Startup ms | Request median ms | Peak RSS KiB | CPU seconds | Heap before KiB | Heap after KiB | GC pauses | GC pause ms | Total ms |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 36,821 | 9.918 | 758,064 | 113.120 | 129,834 | 154,294 | 48 | 473.043 | 61,292 |
| 2 | 49,523 | 13.996 | 708,676 | 160.920 | 122,181 | 146,380 | 42 | 565.772 | 73,638 |
| 3 | 57,137 | 13.364 | 859,464 | 177.180 | 217,860 | 171,211 | 42 | 637.322 | 76,392 |
| 4 | 33,702 | 9.037 | 752,956 | 108.760 | 183,164 | 123,566 | 36 | 429.074 | 51,676 |
| 5 | 37,144 | 8.518 | 808,096 | 118.460 | 139,447 | 164,137 | 38 | 378.193 | 56,936 |

### Cross-run variation

| Metric | Median | Range | CV |
|---|---:|---:|---:|
| Startup | 37,144 ms | 23,435 ms | 20.898% |
| Per-run request median | 9.918 ms | 5.478 ms | 20.691% |
| Peak RSS | 758,064 KiB | 150,788 KiB | 6.652% |
| Process CPU | 118.460 s | 68.420 s | 20.555% |
| Heap before workload | 139,447 KiB | 95,679 KiB | 22.985% |
| Heap after workload | 154,294 KiB | 47,645 KiB | 10.863% |
| GC pause count | 42 | 12 | 9.996% |
| Total GC pause time | 473.043 ms | 259.129 ms | 18.827% |
| Complete repetition | 61,292 ms | 24,716 ms | 14.918% |

Across all 150 measured requests:

- median: 10.459 ms;
- p90: 20.177 ms;
- p95: 23.077 ms;
- p99: 39.919 ms;
- maximum: 87.100 ms;
- coefficient of variation: 66.024%.

The high individual-request CV and approximately 15–23% cross-run variation
for several aggregate measurements demonstrate that this is not a
microbenchmark. The useful invariant is that identical work completes and
produces comparable diagnostic evidence. Section 1.16 must use paired,
alternating repetitions on the same runner and treat differences within this
noise range as observations.

## Diagnostic evidence

Each run preserves:

- launch-to-readiness and total duration;
- 200-millisecond process samples with RSS and aggregate CPU ticks;
- `jcmd VM.command_line`;
- `jcmd VM.flags -all`;
- `jcmd GC.heap_info` before and after the workload;
- unified G1 GC logging for the actual Liberty server PID;
- a parseable 10-second JFR;
- JFR event summary;
- warm-up and measured request TSV files;
- readiness headers and response body;
- Liberty `messages.log` and `console.log`;
- Maven start and stop logs.

All five JFRs contained CPU, execution, allocation, and runtime events. The
harness derives its JFR configuration from the JDK profile but disables:

- `jdk.JVMInformation`;
- `jdk.InitialSystemProperty`;
- `jdk.OSInformation`;
- `jdk.InitialEnvironmentVariable`;
- `jdk.SystemProcess`.

Every final JFR summary reported zero events for those five types.

## Failure policy

Required CI should fail on:

- inability to build or deploy the fixed artifact;
- inability to discover and sample the Liberty JVM;
- startup or readiness exceeding 90 seconds;
- any warm-up or measured request that times out, returns a non-200 status, or
  lacks the seeded cargo content;
- abnormal JVM termination or an out-of-memory error;
- missing or unparseable process, command-line, flag, heap, GC, JFR, HTTP, or
  Liberty evidence;
- inability to stop Liberty or remove the disposable runtime;
- a complete repetition exceeding 120 seconds;
- peak sampled RSS exceeding a provisional gross bound of 2 GiB.

The 120-second and 2-GiB bounds are deliberately broad compared with observed
maxima of 76.392 seconds and 859,464 KiB. The first GitHub-hosted execution
must record its own environment and may widen a gross bound if the same
correct workload demonstrates that the local value is not portable.

Do not fail required CI on:

- startup-time changes within the observed noise floor;
- request latency, CPU time, heap use, GC counts, GC pause time, or RSS
  differences that do not breach a resolved gross bound;
- a `java` versus `jaz` performance difference without repeated paired
  evidence.

## Reproduction

From the repository root:

```bash
1-trick-out-01-remove-before-merge/\
spike_1_15_capture_repeatable_performance_envelope/run-spike.sh
```

Optional parameters:

```bash
RUN_COUNT=5 \
WARMUP_REQUESTS=5 \
MEASURED_REQUESTS=30 \
REQUEST_PACING_SECONDS=0.2 \
JFR_DURATION_SECONDS=10 \
MAX_STARTUP_MS=90000 \
MAX_TOTAL_MS=120000 \
MAX_RSS_KB=2097152 \
1-trick-out-01-remove-before-merge/\
spike_1_15_capture_repeatable_performance_envelope/run-spike.sh
```

The harness uses a disposable shared clone and never modifies application
sources or the campaign worktree's `demo/target`. It builds and deploys once,
restores the pristine deployed server for each repetition, and removes all
scratch state on success or failure.

## Proposed text for the plan's Resolution field

Select a non-containerized, diagnostic workload based on the Open Liberty
lifecycle resolved in section 1.13. Build and deploy one WAR and Liberty
runtime, record their checksums, and restore a pristine `defaultServer`
directory for each repetition. Measure from the `liberty:start` invocation
through HTTP 200 readiness from `/cargo-tracker/rest/cargo` with seeded cargo
`ABC123`. Run five validated warm-up requests, start a 10-second JFR
dynamically with `jcmd`, then run 30 sequential validated requests paced by
200 milliseconds. Use one request at a time and a 10-second request timeout.
Capture the effective JVM command and complete flags, 200-millisecond
RSS/CPU samples, heap summaries before and after the workload, server-PID GC
logs, parseable JFR, request TSV, Liberty logs, Maven logs, exit status, and
cleanup result. Repeat the complete workload five times per launch mode on the
same GitHub-hosted VM, using a fresh Liberty output/data directory each time.
Record the runner CPU, memory, OS, kernel, and cgroup view; do not use
Docker/OCI execution, synthetic cgroup limits, fixed heap/processor tuning, or
other `-X*`/`-XX*` workload flags that would interfere with the section 1.16
`jaz` comparison. The spike's five direct-`java` runs all passed, but startup,
per-run request median, CPU, heap-before, GC-pause-time, and total-duration
variation ranged from approximately 15% to 23%; individual request timing was
noisier. Treat these measurements as diagnostic evidence, not benchmark
thresholds. Fail on functional failure, crash or OOM, startup beyond 90
seconds, missing/unparseable diagnostics, cleanup failure, a complete
repetition beyond 120 seconds, or a provisional gross peak-RSS bound of 2
GiB. Do not fail on ordinary timing/resource variation or declare a
`java`/`jaz` winner without repeated paired evidence. Generate and preserve a
safe JFR configuration that disables JVM information, initial system
properties, OS information, initial environment variables, and system-process
events. Calibrate the broad gross bounds during the first GitHub-hosted run
without changing the workload contract.
