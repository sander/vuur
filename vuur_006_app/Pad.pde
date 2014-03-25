class Pad {
  int min;
  int max;
  long lastSense;
  long senseStart;
  long senseStop;
  boolean activated;
  int onTheSpotPreviousMin;
  boolean activatedDuringInteraction;

  // Store the last measured sensor values
  int value;
}
