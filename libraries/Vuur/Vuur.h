#ifndef Vuur_h
#define Vuur_h

#include <ColorLamp.h>
#include <HardwareTouch.h>
#include <LED.h>

#include "Arduino.h"

class HSBColor {
public:
  HSBColor(int hueDeg, float saturationFrac, float brightnessFrac);

  int hue;
  int saturation;
  int brightness;
};

class Vuur;

class Pad {
public:
  Pad(Vuur *vuur, int id, int pinNumber);

  int id;
  TouchPin pin;

  int points;

  unsigned long lastUpdate;
  unsigned long touchStart;
  unsigned long ptAdded;
  unsigned long touchDuration;

  bool touched;
  bool untouched;

  bool doubleTapped();
  void addPoints(int points);
  void listenToDoubleTap();

private:
  Vuur *_vuur;
};

class Vuur {
public:
  static const int nMonoLEDs = 3;
  static const int nPads = 12;

  Vuur();

  LED *mono[nMonoLEDs];
  ColorLamp *rgb;
  Pad *pads[nPads];

  Pad *lastTouched;
  Pad *winning;

  unsigned int stopDuration;
  unsigned int doubleTapInterval;
  unsigned int touchRecordInterval;
  int maxPoints;
  int doubleTapPad;

  int variation;
  int touchRecord;

  float width;
  float fraction;
  float distances[16];

  unsigned long touchRecordTime;
  unsigned long doubleTapTime;

  int nTouched;
  int doubleTapState;
  bool doubleTapped;

  void addPoints(Pad *pad, int points);
  void setRGB(HSBColor *color, int time);
  void setCenter(float center);
  void reset();
  void update();
  Pad *nextPad();
  int totalPoints();
  bool stopped();
  float center();

private:
  unsigned long _stopped;
  int _iterator;
  float _center;
  float _fraction();
};

unsigned long timeSince(unsigned long time);

#endif
