package org.eclipse.cargotracker.architecture;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

class LayeringTest {

  private static final String PACKAGE = "org.eclipse.cargotracker.";
  private static final Pattern DEPENDENCY =
      Pattern.compile("^\\s*(\\S+)\\s+->\\s+(\\S+)\\s+.*$");
  private static final Map<String, Set<String>> KNOWN_LEGACY_REFERENCES =
      Map.of(
          PACKAGE + "domain.model.cargo.BookingBackingBean",
          Set.of(
              PACKAGE + "interfaces.booking.facade.BookingServiceFacade",
              PACKAGE + "interfaces.booking.facade.dto.Location",
              PACKAGE + "application.util.DateUtil"),
          PACKAGE + "domain.model.voyage.SampleVoyages",
          Set.of(PACKAGE + "application.util.DateUtil"));

  @Test
  void domainAndInterfaceBoundariesHaveNoNewLeaks() throws IOException, InterruptedException {
    Process jdeps =
        new ProcessBuilder(
                Path.of(System.getProperty("java.home"), "bin", "jdeps").toString(),
                "-verbose:class",
                "-filter:none",
                "target/classes")
            .redirectErrorStream(true)
            .start();
    String output = new String(jdeps.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
    assertEquals(0, jdeps.waitFor(), output);

    assertEquals(
        Set.of(),
        output
            .lines()
            .map(LayeringTest::dependency)
            .filter(Objects::nonNull)
            .filter(LayeringTest::isForbidden)
            .filter(
                dependency ->
                    !KNOWN_LEGACY_REFERENCES
                        .getOrDefault(dependency.source(), Set.of())
                        .contains(dependency.target()))
            .collect(Collectors.toSet()));
  }

  private static Dependency dependency(String line) {
    var matcher = DEPENDENCY.matcher(line);
    return matcher.matches() ? new Dependency(matcher.group(1), matcher.group(2)) : null;
  }

  private static boolean isForbidden(Dependency dependency) {
    return dependency.source().startsWith(PACKAGE + "domain.")
            && (dependency.target().startsWith(PACKAGE + "application.")
                || dependency.target().startsWith(PACKAGE + "interfaces."))
        || dependency.source().startsWith(PACKAGE + "interfaces.booking.web.")
            && (dependency.target().startsWith(PACKAGE + "domain.")
                || dependency.target().startsWith(PACKAGE + "application."));
  }

  private record Dependency(String source, String target) {}
}
