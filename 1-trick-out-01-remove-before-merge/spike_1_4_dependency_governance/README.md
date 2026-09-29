# Spike 1.4: Maven and dependency-governance rules

Date: 2026-09-29

Plan question:
`1-trick-out-01-remove-before-merge/trick-out-01-ignorance-reduction-plan.md`,
section 1.4.

## Decision

Add one Maven Enforcer `3.6.3` execution bound to `validate` with:

1. `requireJavaVersion` set to `[17,18)`.
2. `requireMavenVersion` set to `[3.9.9,4.0.0)`.
3. `requirePluginVersions`, after explicitly pinning:
   - `maven-clean-plugin` `3.2.0`;
   - `maven-resources-plugin` `3.3.1`.
4. `dependencyConvergence`.
5. `banDuplicatePomDependencyVersions`.
6. `bannedDependencies` for direct Jakarta, Spring, Payara, WildFly/JBoss,
   and Tomcat dependencies.
7. `requireNoRepositories`, allowing only repository ID `central`.

Do **not** add `requireUpperBoundDeps`. It passes, but
`dependencyConvergence` is the stricter selected graph invariant and makes the
upper-bound rule redundant for this campaign.

Do **not** validate, preserve, or accommodate Payara or any other application
server. Open Liberty is the only supported demo path. The bans on other
server families make that boundary explicit.

## What the spike established

The current Open Liberty graph is already clean:

- `dependencyConvergence` passes without exclusions;
- the stricter-scope `requireUpperBoundDeps` candidate also passes, confirming
  that there is no hidden lower-version selection;
- there are no duplicate dependency declarations;
- there are no direct dependencies from the prohibited migration or
  non-Liberty server families;
- the project and its parents do not add repositories outside Maven Central.

The current POM has one small reproducibility defect relevant to the demo:
Maven supplies implicit versions for `maven-clean-plugin` and
`maven-resources-plugin`. Pinning the versions already selected by Maven 3.9.9
fixes the defect without upgrading or modernizing anything.

The spike also showed why `requirePluginVersions` must remain strict:

- setting `banMavenDefaults=false` made the baseline green;
- but it also allowed a deliberately added, unversioned
  `build-helper-maven-plugin`;
- therefore the selected policy keeps strict checking, pins the two plugins
  used by the demo lifecycle, and explicitly exempts only the unused Maven
  defaults for `install`, `deploy`, and `site`.

With those two pins and three narrow exemptions, the selected plugin policy
passes. Adding an unversioned project plugin then fails with the plugin
coordinate and Maven-selected version.

## Candidate disposition

| Candidate | Result | Decision |
|---|---|---|
| `requireJavaVersion` | Baseline passes; impossible-range control fails | Select `[17,18)` |
| `requireMavenVersion` | Wrapper Maven 3.9.9 passes; impossible-range control fails | Select `[3.9.9,4.0.0)` |
| `requirePluginVersions` | Baseline identifies clean/resources defaults; selected policy passes; unversioned-plugin control fails | Select targeted strict policy |
| `dependencyConvergence` | Open Liberty graph passes without exclusions | Select |
| `requireUpperBoundDeps` | Open Liberty graph passes even with `test` and `provided` included | Reject as redundant |
| `banDuplicatePomDependencyVersions` | Baseline passes; duplicate control fails with exact coordinate | Select |
| `bannedDependencies` | Baseline passes; Jakarta control fails with exact coordinate | Select direct-dependency guard |
| `requireNoRepositories` | Baseline passes; repository control fails with POM and repository ID | Select POM-level guard |

No baseline dependency finding requires an exclusion. No tool false positive
was observed.

## Selected plugin-version policy

`requirePluginVersions` unexpectedly discovers the Maven defaults for
`install`, `deploy`, and `site` even though the configured phase list is
limited to the demo build lifecycle. Those phases are not used by the demo,
so the selected configuration:

- pins `maven-clean-plugin` `3.2.0`;
- pins `maven-resources-plugin` `3.3.1`;
- leaves the already explicit compiler, WAR, Surefire, Spotless, Liberty, and
  Cargo plugin versions unchanged;
- places only these unused defaults in `unCheckedPluginList`:
  - `org.apache.maven.plugins:maven-install-plugin`;
  - `org.apache.maven.plugins:maven-deploy-plugin`;
  - `org.apache.maven.plugins:maven-site-plugin`.

Do not use `banMavenDefaults=false`; the negative control proved it is too
permissive for this POM.

## Banned direct dependencies

Use `searchTransitive=false` and these patterns:

```text
jakarta.*:*
org.springframework*:*
fish.payara*:*
org.wildfly*:*
org.jboss.as:*
org.apache.tomcat*:*
```

This prevents an accidental Jakarta/Spring migration or addition of another
application server without turning historical transitive dependencies into
campaign work. Open Liberty dependencies remain allowed.

## Reproduction

Run from the repository root:

```bash
1-trick-out-01-remove-before-merge/spike_1_4_dependency_governance/run-spike.sh
```

The harness:

- copies `demo/pom.xml`; it never edits the application POM;
- tests only the default Open Liberty path;
- runs every rule independently;
- creates targeted failure controls;
- regenerates `generated-poms/`, `logs/`, and `run-summary.tsv`;
- exits nonzero if a case differs from its classified expectation.

The final run contains 15 expected outcomes.

## Proposed text for the plan's Resolution field

Select an Open Liberty-only Maven Enforcer policy. Bind Maven Enforcer `3.6.3`
to `validate` and enable `requireJavaVersion` `[17,18)`,
`requireMavenVersion` `[3.9.9,4.0.0)`, strict `requirePluginVersions`,
`dependencyConvergence`, `banDuplicatePomDependencyVersions`, narrowly scoped
direct `bannedDependencies`, and `requireNoRepositories`. Pin only the two
implicit lifecycle plugins used by the demo: `maven-clean-plugin` `3.2.0` and
`maven-resources-plugin` `3.3.1`. Exempt the unused Maven defaults for
`install`, `deploy`, and `site`; do not use `banMavenDefaults=false`, because
the spike proved that it permits an unversioned project plugin. Select
`dependencyConvergence` as the single dependency-graph invariant and omit
`requireUpperBoundDeps` as redundant; both passed the Open Liberty graph
without dependency exclusions, including test and provided scopes for the
upper-bound candidate. Ban direct Jakarta, Spring, Payara, WildFly/JBoss, and
Tomcat dependencies so Open Liberty remains the only supported application
server. The duplicate-dependency, banned-dependency, repository, Java/Maven
version, and unversioned-plugin negative controls all failed with actionable
messages. No dependency modernization, broad exclusion, Payara validation, or
other application-server accommodation is required.
