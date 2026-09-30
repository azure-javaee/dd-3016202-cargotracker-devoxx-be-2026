# Spike 1.9: compiler diagnostics and type-system evidence

## Result

Cargo Tracker can enforce the full Java 17 compiler warning set with
`-Xlint:all -Werror` after a small, bounded cleanup. The existing main sources
produce 14 warnings in two categories:

| Category | Count | Disposition |
| --- | ---: | --- |
| `serial` | 12 | Add explicit `serialVersionUID` values equal to the classes' current generated values. |
| `rawtypes` | 2 | Add the missing generic type information. |

No warning category needs a permanent baseline or suppression. After the 14
source corrections, both 95 main sources and 11 test sources compile cleanly
under `-Xlint:all -Werror`.

## Scope and environment

- Experiment baseline: `cf19be6029aad88ce792e544cc4dd8135867723f`
- Microsoft OpenJDK: 17
- Maven Wrapper: 3.9.9
- Maven Compiler Plugin: 3.14.0
- Java release: 17
- Java EE API: `javax:javaee-api:7.0`
- Open Liberty profile: disabled for every compiler run with
  `-P!openliberty`
- Open Liberty runtime created or started: no

All source and POM changes were made in full scratch clones. The campaign
worktree's application source was not modified.

## Method

The repeatable harness in `run-spike.sh`:

1. Clones the experiment baseline into isolated scratch repositories.
2. Adds `showWarnings`, `-Xlint` options, and `-Werror` only to each scratch
   POM.
3. Runs the compiler-only validation tier:

   ```bash
   ./mvnw \
     -Dmaven.repo.local=<isolated-repository> \
     '-P!openliberty' \
     -DskipTests \
     clean compile
   ```

4. Records all warning locations in `warnings.tsv`.
5. Proves each observed category fails independently under `-Werror`.
6. Proves the clean subset
   `-Xlint:all,-rawtypes,-serial -Werror` passes before source cleanup.
7. Applies the proposed bounded source cleanup in a scratch clone.
8. Proves `clean test-compile` passes with full `-Xlint:all -Werror`.
9. Compiles an isolated invented-API fixture and preserves the resulting
   `cannot find symbol` diagnostic.

## Observed warnings

### `rawtypes`

1. `SampleVoyages.getAll()` constructs `new ArrayList(ALL.values())`.
   `new ArrayList<>(ALL.values())` preserves behavior and removes the raw type.
2. `ChangeDestinationDialog.handleReturn` accepts raw `SelectEvent`.
   `SelectEvent<?>` preserves its unused-event behavior and removes the raw
   type.

These are local type corrections with no API migration or dependency change.

### `serial`

Twelve classes implement `Serializable` without declaring a
`serialVersionUID`. Adding an arbitrary value such as `1L` could break
compatibility with objects serialized by the current classes. The spike
therefore used `serialver` to derive each current generated UID, added those
exact values, recompiled, and verified that all resulting explicit UIDs equal
the originals.

The derived values are retained in
`inventories/generated-serial-version-uids.txt`; the post-change values are in
`inventories/explicit-serial-version-uids.txt`.

## Enforcement recommendation

In the implementation issue:

1. Apply `proposed-warning-fixes.patch`.
2. Configure `maven-compiler-plugin` with:

   ```xml
   <configuration>
     <showWarnings>true</showWarnings>
     <compilerArgs>
       <arg>-Xlint:all</arg>
       <arg>-Werror</arg>
     </compilerArgs>
   </configuration>
   ```

3. Keep compilation as a distinct required CI check, separate from static
   analyzers and Open Liberty integration:

   ```bash
   ./mvnw '-P!openliberty' -DskipTests clean compile
   ```

4. Also retain a validation path that reaches `testCompile`; the spike proved
   all 11 existing test sources are clean under the same policy.
5. Do not add Error Prone, NullAway, or another compiler replacement in this
   campaign. Javac already supplies a clean, deterministic type-system gate
   without introducing Java EE 7 or annotation-processing compatibility risk.

## Controlled failure evidence

The isolated fixture calls a nonexistent method:

```java
return cargo.agentInventedMethod("not-real");
```

Javac rejects it with:

```text
cannot find symbol
  symbol:   method agentInventedMethod(java.lang.String)
  location: variable cargo of type org.eclipse.cargotracker.domain.model.cargo.Cargo
```

The complete fixture and diagnostic are retained in
`inventories/type-failure.txt` and
`logs/20260929-1811-99-type-failure-job-logs.txt`.

## Rollback

If full warning enforcement causes an unforeseen downstream incompatibility,
retain `showWarnings` and `-Xlint:all`, temporarily remove `-Werror`, and record
the exact new warning as evidence. Do not broadly disable `-Xlint` categories.
The 14 source corrections are independently safe to retain because the
generic fixes preserve behavior and the explicit serialization UIDs preserve
the current generated values.

## Paste-ready Section 1.9 resolution

Enable the full javac warning set rather than a reduced subset. On experiment
baseline `cf19be6029aad88ce792e544cc4dd8135867723f`, `-Xlint:all` reported 14
warnings: 12 `serial` warnings and two `rawtypes` warnings. Both categories
failed independently under `-Werror`; disabling exactly those categories made
the remaining full warning set pass.

All 14 warnings fit in one small implementation issue and require no permanent
baseline. Correct the raw `ArrayList` construction in `SampleVoyages` with the
diamond operator and change `ChangeDestinationDialog.handleReturn` to accept
`SelectEvent<?>`. Add explicit `serialVersionUID` fields to the 12 serializable
classes, using the current generated values captured by `serialver` rather
than arbitrary `1L` values so existing serialization identities are
preserved.

After those corrections, both 95 main sources and 11 test sources compiled
successfully with `-Xlint:all -Werror`. Configure
`maven-compiler-plugin` with `showWarnings`, `-Xlint:all`, and `-Werror`, and
keep `./mvnw '-P!openliberty' -DskipTests clean compile` as a distinct named
CI compilation check. Preserve a path that also reaches `testCompile`. Do not
add Error Prone, NullAway, or another compiler replacement during this
campaign.

The controlled failure fixture called nonexistent
`Cargo.agentInventedMethod(String)` and javac rejected it with a precise
`cannot find symbol` diagnostic. The repeatable harness, warning inventory,
proposed source patch, UID compatibility evidence, and logs are in
`1-trick-out-01-remove-before-merge/spike_1_9_compiler_options/`.
