class Surface {
  Pad[] pads;

  IntList cached_activated_points;

  Surface(Pad[] pads) {
    this.pads = pads;
  }

  int numberOfActivatedPadsDuringInteraction() {
    int n = 0;
    for (int i = 0; i < pads.length; i++)
      if (pads[i].activatedDuringInteraction)
        n++;
    return n;
  }

  IntList activated() {
    if (cached_activated_points != null)
      return cached_activated_points;

    IntList points = new IntList();
    IntList sensed = sensed_points();

    for (int i = 0; i < 16; i++)
      if (pads[i].updateActivated(sensed.hasValue(i)))
        points.append(i);
    return cached_activated_points = points;
  }

  void resetCache() {
    cached_activated_points = null;
  }
}

