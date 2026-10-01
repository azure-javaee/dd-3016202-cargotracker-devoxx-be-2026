package org.eclipse.cargotracker.interfaces.booking.facade;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Date;
import java.util.List;
import org.eclipse.cargotracker.domain.model.cargo.Cargo;
import org.eclipse.cargotracker.domain.model.cargo.Itinerary;
import org.eclipse.cargotracker.domain.model.cargo.Leg;
import org.eclipse.cargotracker.domain.model.cargo.RouteSpecification;
import org.eclipse.cargotracker.domain.model.cargo.TrackingId;
import org.eclipse.cargotracker.domain.model.location.SampleLocations;
import org.eclipse.cargotracker.domain.model.voyage.SampleVoyages;
import org.eclipse.cargotracker.interfaces.booking.facade.dto.CargoRoute;
import org.eclipse.cargotracker.interfaces.booking.facade.dto.RouteCandidate;
import org.eclipse.cargotracker.interfaces.booking.facade.internal.assembler.CargoRouteDtoAssembler;
import org.eclipse.cargotracker.interfaces.booking.facade.internal.assembler.ItineraryCandidateDtoAssembler;
import org.junit.jupiter.api.Test;

class BookingFacadeDtoTest {

  @Test
  void cargoRoutePreservesDeadlineAndRouteShape() {
    Date deadline = new Date();
    Cargo cargo =
        new Cargo(
            new TrackingId("ABC123"),
            new RouteSpecification(
                SampleLocations.HONGKONG, SampleLocations.STOCKHOLM, deadline));
    Itinerary itinerary =
        new Itinerary(
            List.of(
                new Leg(
                    SampleVoyages.v100,
                    SampleLocations.HONGKONG,
                    SampleLocations.NEWYORK,
                    new Date(deadline.getTime() - 1000),
                    deadline)));
    cargo.assignToRoute(itinerary);

    CargoRoute route = new CargoRouteDtoAssembler().toDto(cargo);

    assertEquals("ABC123", route.getTrackingId());
    assertFalse(route.getArrivalDeadline().isEmpty());
    assertEquals(1, route.getLegs().size());
    assertEquals("V100", route.getLegs().get(0).getVoyageNumber());
  }

  @Test
  void routeCandidateAssemblerRoundTripsTypedBoundary() {
    Date now = new Date();
    Itinerary itinerary =
        new Itinerary(
            List.of(
                new Leg(
                    SampleVoyages.v100,
                    SampleLocations.HONGKONG,
                    SampleLocations.NEWYORK,
                    now,
                    new Date(now.getTime() + 1000))));

    RouteCandidate candidate = new ItineraryCandidateDtoAssembler().toDTO(itinerary);

    assertEquals(1, candidate.getLegs().size());
    assertEquals("CNHKG", candidate.getLegs().get(0).getFromUnLocode());
    assertEquals("USNYC", candidate.getLegs().get(0).getToUnLocode());
  }
}
