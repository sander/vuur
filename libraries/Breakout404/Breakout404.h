#ifndef Breakout404_h
#define Breakout404_h

#include "Arduino.h"

class LightSource {
public:
  int updated;
};

class ColorCove : public LightSource {
public:
  int id;
  int hue;
  int saturation;
  int brightness;
  int variation;
  int speed;
};

class Ceiling : public LightSource {
public:
  boolean enabled;
  int intensity;
  int cct;
};

class Solime : public LightSource {
public:
  int hue;
  int saturation;
  int brightness;
};

class Breakout404Class {
public:
  Breakout404Class();
  void update();

private:
  const static int nCoves = 16;
  const static int maxUpdateParametrics = 2;
  const static int maxUpdateCoveHSB = 4;
  const static unsigned long interval = 500;

  int currentUpdate;
  unsigned long lastSend;

  void fun(int rec, String name);
  void arg(int a);
  void snd();

  bool updateCoveHSB();
  bool updateCoveParametrics();
  bool updateCeiling();
  bool updateSolime();

  int _colorCoveIterator;

public:
  ColorCove *coves[nCoves];
  Ceiling *ceiling;
  Solime *solime;

  ColorCove *nextColorCove();
};

extern Breakout404Class Breakout404;

#endif
