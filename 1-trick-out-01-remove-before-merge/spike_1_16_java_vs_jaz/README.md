# Spike 1.16: `java` versus `jaz`, GC logs, and JFR capture

Date: 2026-09-30

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.16.

## Decision

Compare direct `java`, bypassed `jaz`, and tuned `jaz` on one
non-containerized runner using the workload resolved by spike 1.15 without
copying or independently redefining that workload.

The harness reads:

- `../spike_1_15_capture_repeatable_performance_envelope/reports/workload-contract.txt`;
- `../spike_1_15_capture_repeatable_performance_envelope/reports/profile-without-environment.jfc`.

It preserves copies and SHA-256 hashes of those inputs with the 1.16 evidence.
The request count, pacing, readiness condition, JFR duration, repetition
count, startup bound, total-duration bound, peak-RSS bound, container policy,
and redaction policy therefore remain the section 1.15 decisions.

Use this as a diagnostic comparison job, not as evidence that `jaz` should
replace direct `java` by default. The spike proves that `jaz` can launch,
supervise, diagnose, and stop this Open Liberty workload and that its selected
settings are observable. It does not establish a repeatable performance
winner on the unconstrained host.

Install a pinned `jaz` package without `sudo`, verify its SHA-256, and expose
it to Open Liberty through the per-server `JAVA_HOME` setting in
`server.env`. The `jaz` Java home must mirror the real JDK layout and override
only `bin/java`; a minimal directory containing only a launcher does not give
Liberty the JDK metadata it needs to add its Java 17 module-access options.

Use these modes:

1. `direct`: the real Microsoft OpenJDK 17 `JAVA_HOME`;
2. `bypass`: the mirrored Java home with `JAZ_BYPASS=1`;
3. `tuned`: the mirrored Java home with normal `jaz` tuning.

Set `JAZ_EXIT_WITHOUT_FLUSH=1` for both `jaz` modes so shutdown is not delayed
by telemetry flushing. Do not set `JAZ_IGNORE_USER_TUNING` and do not pass
heap, processor-count, GC-selection, or startup-JFR tuning options.

## Pinned launcher

| Property | Value |
|---|---|
| Product | Azure Command Launcher for Java |
| Version | 1.0.4 |
| Architecture | amd64 |
| Package | `jaz_1.0.4_amd64.deb` |
| SHA-256 | `3d479f11ff2a037790505746a44568e1408f2f79aac62300ea4c651c4969a710` |
| Source | Microsoft Ubuntu 24.04 package repository |

The harness downloads the package directly, verifies the pinned digest, and
extracts it into disposable scratch space with `dpkg-deb`. It does not modify
the runner's package database.

## Environment

The final spike ran against commit
`f493d6012f9c012999b82ca9a02d7c73ba44f9f2` with:

- Microsoft Build of OpenJDK 17.0.18;
- Maven Wrapper 3.9.9;
- Liberty Maven Plugin 3.12.1;
- Open Liberty 26.0.0.8;
- `jaz` 1.0.4;
- eight visible processors;
- approximately 16 GiB of host memory;
- a WSL2 Linux VM with cgroup v2 membership `/init.scope`;
- no container runtime or synthetic cgroup limits.

The WAR SHA-256 was:

```text
16f79447db08524486ae0cddae7a6cabf16fd5d8077cb28c4e7ed5c1d93a5d49
```

The experiment establishes launcher integration and the local paired noise
floor. The implementation issue must repeat the unchanged experiment on one
GitHub-hosted VM before treating the measurements as hosted-runner evidence.

## Launcher integration

Open Liberty's `server.env` is the substitution point. Maven and its Liberty
plugin continue to run with the real JDK. For the server process, direct mode
sets `JAVA_HOME` to the real JDK, while the two `jaz` modes set it to a
symlinked mirror whose `bin/java` wrapper executes the pinned `jaz` binary.

The wrapper records every invocation. For the tuned server launch it also
replays the exact Liberty JVM argument vector with `JAZ_DRY_RUN=1` before the
real launch. The harness then:

- identifies and samples the real child Java process rather than the
  supervising `jaz` process;
- records the `jaz` launcher PID and process relationship;
- confirms direct mode has no `jaz` ancestor;
- confirms both `jaz` modes retain a launcher ancestor while Liberty runs;
- confirms `liberty:stop` removes both the Java child and launcher;
- preserves Maven, Liberty, launcher, GC, JFR, JVM-command, JVM-flag, process,
  heap, HTTP, and timing evidence.

## Tuning and diagnostics semantics

Preflight dry runs establish the following:

- normal `jaz` selects its heap and G1 tuning;
- `-Xlog` is treated as diagnostic configuration and does not suppress
  tuning;
- `JAZ_BYPASS=1` suppresses heap and GC tuning but still adds launcher
  diagnostics, including native-memory tracking and an error-file location;
- a user-provided tuning option such as `-Xmx256m` suppresses normal `jaz`
  heap and GC tuning, while launcher diagnostics remain.

The last case is the required failure example. Required CI must reject a
tuned-mode run whose effective flags do not contain the expected `jaz`
settings. It must also reject direct or bypass mode if tuned heap/GC settings
appear unexpectedly.

GC logging remains the section 1.15 server-PID-specific unified log. JFR is
started dynamically with `jcmd` after warm-up using the redacted 1.15 profile;
it is not configured through a JVM startup option and therefore does not
interfere with `jaz` tuning.

## Experiment protocol

Build and deploy the WAR and Liberty runtime once. Record their hashes, retain
a pristine deployed `defaultServer`, and restore it before every launch. Run
five cycles with all three modes in each cycle. Rotate the mode order:

| Cycle | Order |
|---:|---|
| 1 | direct, bypass, tuned |
| 2 | bypass, tuned, direct |
| 3 | tuned, direct, bypass |
| 4 | direct, tuned, bypass |
| 5 | bypass, direct, tuned |

This produces five repetitions per mode and reduces position, cache, and
temporal bias. Each launch executes the unchanged section 1.15 workload and
must satisfy its functional, diagnostic, duration, memory, and cleanup gates.

## Results

All 15 launches passed. Every mode:

- used the same WAR, Liberty runtime, readiness condition, request workload,
  safe JFR profile, GC logging, and diagnostic protocol;
- returned all 30 measured responses with status 200 and seeded cargo content;
- produced parseable GC logs and JFR recordings;
- preserved effective JVM commands and complete flag inventories;
- stopped Liberty and removed the Java and launcher processes.

### Effective JVM policy

| Setting | Direct `java` | Bypassed `jaz` | Tuned `jaz` |
|---|---:|---:|---:|
| Maximum heap | 4,139,778,048 bytes | 4,139,778,048 bytes | 10,015,997,952–10,468,982,784 bytes |
| Minimum heap-free ratio | 40 | 40 | 10 |
| Maximum heap-free ratio | 70 | 70 | 50 |
| G1 periodic GC interval | 0 | 0 | 10,000 ms |
| Time-based G1 heap sizing | not enabled | not enabled | enabled |
| Native-memory tracking | off | summary | summary |
| GC | G1 | G1 | G1 |

The bypass mode therefore measures the launcher without heap or GC tuning,
but it is not byte-for-byte equivalent to direct `java`: `jaz` still enables
native-memory tracking and configures its error-file location.

### Median measurements

| Metric | Direct `java` | Bypassed `jaz` | Tuned `jaz` |
|---|---:|---:|---:|
| Startup | 25,469 ms | 30,498 ms | 28,790 ms |
| Per-run request median | 7.815 ms | 7.782 ms | 7.619 ms |
| Peak RSS | 810,748 KiB | 878,740 KiB | 790,644 KiB |
| Process CPU | 80.420 s | 99.500 s | 82.620 s |
| Heap before workload | 145,689 KiB | 178,298 KiB | 157,281 KiB |
| Heap after workload | 153,528 KiB | 142,759 KiB | 166,336 KiB |
| GC pause count | 37 | 36 | 44 |
| Total GC pause time | 277.522 ms | 333.112 ms | 341.114 ms |
| Complete repetition | 42,982 ms | 48,346 ms | 46,068 ms |

Across all 150 requests per mode, median request latency was 7.880 ms for
direct `java`, 8.158 ms for bypassed `jaz`, and 7.782 ms for tuned `jaz`.

### Paired interpretation

Paired cycle medians relative to direct `java` were:

| Metric | Bypassed `jaz` | Tuned `jaz` |
|---|---:|---:|
| Startup | +5.716% | -0.205% |
| Per-run request median | -0.361% | -2.176% |
| Peak RSS | +7.996% | +0.374% |
| Process CPU | +9.267% | -4.249% |
| GC pause count | -2.778% | +18.919% |
| Total GC pause time | +0.494% | +12.604% |
| Complete repetition | +5.274% | -0.501% |

Startup, total-duration, CPU, request, and RSS deltas changed sign across
cycles or remained within the broad variation established by spike 1.15.
Tuned request medians were lower than direct in four of five cycles, but the
paired median difference was only 0.182 ms. Tuned peak RSS was lower than
bypassed RSS in all five cycles, but it was not consistently lower than
direct RSS.

The repeatable behavioral difference was GC policy: tuned `jaz` enabled
10-second periodic GC and produced more GC pauses than both other modes in all
five cycles. The absolute additional pause time remained small for this
workload, but it is observable evidence of the selected tuning rather than a
performance victory.

The results do not justify a required CI assertion that one launcher is
faster, smaller, or more efficient. They do justify assertions that the
requested mode was actually used, the expected settings took effect, and all
functional and diagnostic evidence remained available.

## Failure policy

In addition to all section 1.15 failures, required CI must fail on:

- inability to download, verify, extract, or execute the pinned `jaz`;
- a package or version mismatch;
- inability to substitute the launcher through Liberty `server.env`;
- a `jaz` mode without a supervising `jaz` process;
- a direct mode with a `jaz` process;
- missing or invalid tuned-mode `JAZ_DRY_RUN=1` evidence;
- tuned-mode flags that do not show the expected tuning;
- bypass-mode flags that retain tuned heap or GC settings;
- a user-provided tuning option in the comparison workload;
- failure to relay Liberty output or start/stop status;
- a surviving Java or `jaz` process after cleanup;
- any difference in WAR, Liberty runtime, readiness condition, requests, JFR
  profile, or diagnostic protocol between modes.

Do not fail solely because one mode has better or worse startup, latency, CPU,
heap, RSS, or GC measurements. Interpret those measurements against the 1.15
noise floor and require repeated paired evidence before claiming a performance
winner.

## Reproduction

From the repository root:

```bash
1-trick-out-01-remove-before-merge/\
spike_1_16_java_vs_jaz/run-spike.sh
```

`RUN_COUNT=1` may be used only for harness development. The resolved
experiment uses the five repetitions imported from the 1.15 contract.

## Proposed text for the plan's Resolution field

Use the non-containerized workload, bounds, request protocol, and redacted JFR
configuration from spike 1.15 by reference rather than redefining them.
Install and checksum-pin `jaz` 1.0.4 from the Microsoft Ubuntu 24.04 package
repository without modifying the runner package database. Build and deploy
the WAR and Open Liberty runtime once, then compare direct `java`,
`JAZ_BYPASS=1`, and normal tuned `jaz` in five alternating-order cycles on the
same runner, restoring a pristine `defaultServer` before every launch.

Substitute `jaz` through Open Liberty `server.env` using a Java home that
mirrors the real JDK and overrides only `bin/java`; a minimal launcher-only
Java home omits JDK metadata Liberty needs for Java 17 module options. Keep
Maven, `jcmd`, and other tooling on the real JDK. Set
`JAZ_EXIT_WITHOUT_FLUSH=1`, capture tuned-mode `JAZ_DRY_RUN=1` output, preserve
launcher and child-JVM process evidence, and verify effective settings with
`jcmd VM.command_line` and `jcmd VM.flags`. Continue to use server-PID-specific
`-Xlog` GC output and start the bounded JFR dynamically after warm-up.

The spike's 15 launches all passed. Bypassed `jaz` retained default heap and
GC policy but still enabled native-memory tracking and an error-file location.
Tuned `jaz` selected an approximately 10.0–10.5 GB maximum heap, heap-free
ratios of 10/50, time-based G1 heap sizing, native-memory tracking, and
10-second periodic GC. It produced more GC pauses in all five paired cycles,
but startup, total duration, CPU, request latency, and RSS differences were
inconsistent or within the spike 1.15 noise floor. Therefore use the
three-mode job to prove launcher integration, effective tuning, diagnostics,
functional equivalence, and cleanup; do not fail CI or select a winner based
on performance differences alone. Fail on installation or checksum failure,
launcher substitution failure, suppressed or unverifiable tuning, artifact
or workload mismatch, missing GC/JFR/JVM/process evidence, functional failure,
or incomplete cleanup. Evaluate `jaz` under actual AKS pod limits in the
separate Azure deployment thread.
