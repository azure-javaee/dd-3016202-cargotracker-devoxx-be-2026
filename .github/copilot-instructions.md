---
applyTo:
  - "**/*.java"
  - "**/*.kt"
  - "**/*.groovy"
  - "**/pom.xml"
  - "**/.mvn/**"
  - "**/mvnw"
  - "**/mvnw.cmd"
  - "**/build.gradle"
  - "**/build.gradle.kts"
  - "**/settings.gradle"
  - "**/settings.gradle.kts"
  - "**/gradlew"
  - "**/gradlew.bat"
---

# Cargo Tracker compatibility contract

- Use Java 17 only. The Maven compiler release is fixed at 17.
- Keep the application on Java EE 7 and `javax.*`; do not migrate production
  code or dependencies to Jakarta EE.
- The application is a WAR named `cargo-tracker.war`, deployed by Open
  Liberty with the `javaee-7.0` feature at `/cargo-tracker`.
- Run Maven Wrapper commands from `demo/`, for example:
  `./mvnw '-P!openliberty' -DskipTests clean compile`.
- Keep Open Liberty as the only supported application server. Do not replace
  it with Spring, Payara, WildFly, Tomcat, or another runtime.
- Do not make broad dependency upgrades or ban tool-only dependencies without
  understanding their scope.
- Before proceeding, run the relevant Maven checks and keep required CI green.
- Update `1-trick-out-01-remove-before-merge/evidence-matrix.md` after
  implementation and validation, but before the issue is considered complete
  or the next serial issue begins.

## Maven execution

Whenever invoking `mvn` or `./mvnw`, pipe both streams through `tee` to a
`YYYYMMDD-HHMM-job-logs.txt` file, inspect that exact file, and do not use
background `&` plus `tail -f` or guessed log names. In CI, preserve the same
tee-to-log discipline and use the repository's configured Java environment.
