#ifndef Vuur_h
#define Vuur_h

#include <HardwareTouch.h>

#include "Arduino.h"

class Pad {
public:
  Pad(int pinNumber, int hueDeg, int saturationPerc, int brightnessPerc);

  TouchPin pin;
  int points;

  int hue;
  int saturation;
  int brightness;

  unsigned long lastUpdate;
  unsigned long touchStart;
  unsigned long ptAdded;

  boolean touched;
};

class Vuur {
public:
  static const int nPads = 12;

  Vuur();

  Pad *pads[nPads];

  int stopDuration;
  int maxPoints;

  int variation;
  int touchRecord;

  float center;
  float width;

  float distances[16];

  unsigned long lastPreview;
  unsigned long nTouchedRecordTime;
  unsigned long doubleTapTime;

  int lastPreviewed;

  int nTouched;
  int nTouchedRecord;
  int doubleTapState;

  void setPads(int config[4 * nPads]);

  void stop();

  Pad *winning();
  int totalPoints();
  bool stopped();
  float fraction();

private:
  unsigned long _stopped;
};

#endif
