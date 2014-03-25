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

  Debouncer<Boolean> activatedDebouncer;

  Pad() {
    activatedDebouncer = new Debouncer<Boolean>();
    activatedDebouncer.delay = TOUCH_TIMEOUT;
  }

  boolean isActivated() {
    return activatedDebouncer.get();
  }
  
  boolean updateActivated(boolean value) {
    activatedDebouncer.update(value);
    if (activatedDebouncer.get()) {
      activated = true;
      activatedDuringInteraction = true;
      return true;
    } else {
      activated = false;
      return false;
    }
  }
}

