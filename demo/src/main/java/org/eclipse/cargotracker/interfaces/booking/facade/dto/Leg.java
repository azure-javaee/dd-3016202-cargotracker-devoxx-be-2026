package org.eclipse.cargotracker.interfaces.booking.facade.dto;

import java.io.Serializable;
import java.text.SimpleDateFormat;
import java.util.Date;
import org.eclipse.cargotracker.application.util.DateUtil;

/** DTO for a leg in an itinerary. */
public class Leg implements Serializable {

  private static final long serialVersionUID = 6476796480576183537L;
  private static final String DATE_FORMAT = "MM/dd/yyyy hh:mm a z";

  private final String voyageNumber;
  private final String fromUnLocode;
  private final String fromName;
  private final String toUnLocode;
  private final String toName;
  private final String loadTime;
  private final String unloadTime;

  public Leg(
      String voyageNumber,
      String fromUnLocode,
      String fromName,
      String toUnLocode,
      String toName,
      Date loadTime,
      Date unloadTime) {
    this.voyageNumber = voyageNumber;
    this.fromUnLocode = fromUnLocode;
    this.fromName = fromName;
    this.toUnLocode = toUnLocode;
    this.toName = toName;
    this.loadTime = new SimpleDateFormat(DATE_FORMAT).format(loadTime);
    this.unloadTime = new SimpleDateFormat(DATE_FORMAT).format(unloadTime);
  }

  public String getVoyageNumber() {
    return voyageNumber;
  }

  public String getFrom() {
    return fromName + " (" + fromUnLocode + ")";
  }

  public String getFromUnLocode() {
    return fromUnLocode;
  }

  public String getFromName() {
    return fromName;
  }

  public String getTo() {
    return toUnLocode + " (" + toName + ")";
  }

  public String getToName() {
    return toName;
  }

  public String getToUnLocode() {
    return toUnLocode;
  }

  public String getLoadTime() {
    return loadTime;
  }

  public String getLoadTimeDate() {
    return DateUtil.getDateFromDateTime(loadTime);
  }

  public String getLoadTimeTime() {
    return DateUtil.getTimeFromDateTime(loadTime);
  }

  public String getUnloadTime() {
    return unloadTime;
  }

  public String getUnloadTimeTime() {
    return DateUtil.getTimeFromDateTime(unloadTime);
  }

  public String getUnloadTimeDate() {
    return DateUtil.getDateFromDateTime(unloadTime);
  }

  @Override
  public String toString() {
    return "Leg{"
        + "voyageNumber="
        + voyageNumber
        + ", from="
        + fromUnLocode
        + ", to="
        + toUnLocode
        + ", loadTime="
        + loadTime
        + ", unloadTime="
        + unloadTime
        + '}';
  }
}
