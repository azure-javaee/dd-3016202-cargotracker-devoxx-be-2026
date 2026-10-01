package org.eclipse.cargotracker.architecture;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

class LayeringTest {

  private static final String ROOT = "src/main/java/org/eclipse/cargotracker/";

  @Test
  void domainAndInterfaceBoundariesHaveNoNewLeaks() throws IOException {
    Path sourceRoot = Path.of(ROOT);
    List<String> violations = new ArrayList<>();
    try (Stream<Path> files = Files.walk(sourceRoot)) {
      for (Path file : files.filter(path -> path.toString().endsWith(".java")).toList()) {
        String source = Files.readString(file);
        String relative = sourceRoot.relativize(file).toString().replace('\\', '/');
        if (relative.startsWith("domain/") && !relative.equals("domain/model/cargo/BookingBackingBean.java")) {
          addImports(violations, relative, source, "application.", "interfaces.");
        }
        if (relative.startsWith("interfaces/booking/web/")) {
          addImports(violations, relative, source, "domain.", "application.");
        }
      }
    }

    Set<String> knownLegacyFiles =
        Set.of("domain/model/voyage/SampleVoyages.java");
    Set<String> allKnownLegacyFiles =
        knownLegacyFiles.stream().collect(Collectors.toSet());
    assertEquals(
        Set.of(),
        violations.stream()
            .map(violation -> violation.substring(0, violation.indexOf(" -> ")))
            .filter(path -> !allKnownLegacyFiles.contains(path))
            .collect(Collectors.toSet()));
  }

  private static void addImports(
      List<String> violations, String relative, String source, String... forbidden) {
    for (String line : source.lines().filter(line -> line.startsWith("import ")).toList()) {
      for (String prefix : forbidden) {
        if (line.contains("org.eclipse.cargotracker." + prefix)) {
          violations.add(relative + " -> " + prefix);
        }
      }
    }
  }
}
