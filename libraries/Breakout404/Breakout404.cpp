#include <Lithne.h>

#include "Breakout404.h"

const bool debug = false;

void Breakout404Class::fun(int rec, String name) {
  if (debug) {
    Serial.print("fun " + name + " @ ");
    Serial.println(rec);
  }
  Lithne.setFunction(name);
  Lithne.setScope("Breakout404");
  Lithne.setRecipient(rec);
}

void Breakout404Class::arg(int a) {
  if (debug) {
    Serial.print("\targ ");
    Serial.println(a);
  }
  Lithne.addArgument(a);
}

void Breakout404Class::snd() {
  if (debug) Serial.println("\tsent");
  Lithne.send();
}

Breakout404Class::Breakout404Class() {
  Lithne.begin(115200, Serial1);
  Lithne.addNode(COORDINATOR, XBeeAddress64(0x00000000, 0x00000000));
  Lithne.addNode(BROADCAST  , XBeeAddress64(0x00000000, 0x0000FFFF));   
  Lithne.addNode(1, XBeeAddress64(0x0013A200, 0x4079CE37/*40*/)); // color coves
  Lithne.addNode(2, XBeeAddress64(0x0013A200, 0x4079CE25)); // cct tiles
  Lithne.addNode(3, XBeeAddress64(0x0013A200, 0x4079CE26)); // blinds
  Lithne.addNode(9, XBeeAddress64(0x0013A200, 0x4079CE24)); // solime

  Lithne.addScope("Breakout404");

  for (int i = 0; i < nCoves; i++) {
    coves[i] = new ColorCove;
    coves[i]->id = i;
    coves[i]->hue = 0;
    coves[i]->saturation = 0;
    coves[i]->brightness = 0;
    coves[i]->variation = 0;
    coves[i]->speed = 0;
    coves[i]->time = 0;
    coves[i]->time2 = 0;
    coves[i]->hue2 = 0;
    coves[i]->saturation2 = 0;
    coves[i]->brightness2 = 0;
  }
  ceiling = new Ceiling;
  solime = new Solime;

  currentUpdate = 0;
  lastSend = 0;
}

void Breakout404Class::update() {
  // this is needed to not overload the connection...
  // at least if we do just 1 msg per loop, something seems to catch errors
  if (millis() - lastSend > interval) {
    lastSend = millis();

    if (updateCoveHSB()) return;
    //if (updateCoveParametrics()) return;
    //if (updateCovePingpong()) return;
    if (updateCeiling()) return;
    if (updateSolime()) return;

    currentUpdate++;
  }
}

bool Breakout404Class::updateSolime() {
  if (solime->updated != currentUpdate) {
    fun(9, "setAllHSB");
    arg(solime->hue);
    arg(solime->saturation);
    arg(solime->brightness);
    snd();
    solime->updated = currentUpdate;
    return true;
  } 
  else {
    return false;
  }
}

bool useParametrics(ColorCove *cove) {
  return cove->variation != 0 && cove->brightness != 0;
}

bool usePingpong(ColorCove *cove) {
  return !useParametrics(cove);
}

bool Breakout404Class::updateCoveHSB() {
  ColorCove *updating[maxUpdateCoveHSB];
  int n = 0;
  for (int i = 0; i < nCoves && n < maxUpdateCoveHSB; i++) {
    ColorCove *cove = coves[i];
    if (cove->updated != currentUpdate /*&& !useParametrics(cove)*/) {
      updating[n++] = cove;
      cove->updated = currentUpdate;
    }
  }

  if (n) {
    fun(1, "setHSB");
    for (int i = 0; i < n; i++) {
      arg(updating[i]->id);
      arg(updating[i]->hue);
      arg(updating[i]->saturation);
      arg(updating[i]->brightness);
    }
    snd();
    return true;
  } 
  else {
    return false;
  }
}

bool Breakout404Class::updateCoveParametrics() {
  ColorCove *updating[maxUpdateParametrics];
  int n = 0;
  for (int i = 0; i < nCoves && n < maxUpdateParametrics; i++) {
    ColorCove *cove = coves[i];
    if (cove->updated != currentUpdate && useParametrics(cove)) {
      updating[n++] = cove;
      cove->updated = currentUpdate;
    }
  }

  if (n) {
    fun(1, "parametrics");
    for (int i = 0; i < n; i++) {
      arg(updating[i]->id);
      arg(updating[i]->hue);
      arg(updating[i]->saturation);
      arg(updating[i]->brightness);
      arg(updating[i]->variation);
      arg(updating[i]->speed);
    }
    snd();
    return true;
  } 
  else {
    return false;
  }
}

bool Breakout404Class::updateCovePingpong() {
  ColorCove *updating[maxUpdatePingpong];
  int n = 0;
  for (int i = 0; i < nCoves && n < maxUpdatePingpong; i++) {
    ColorCove *cove = coves[i];
    if (cove->updated != currentUpdate && usePingpong(cove)) {
      updating[n++] = cove;
      cove->updated = currentUpdate;
    }
  }

  if (n) {
    fun(1, "pingpong");
    for (int i = 0; i < n; i++) {
      if (updating[i]->time && updating[i]->time2) {
        arg(updating[i]->id);
        arg(updating[i]->hue);
        arg(updating[i]->hue2);
        arg(updating[i]->saturation);
        arg(updating[i]->saturation2);
        arg(updating[i]->brightness);
        arg(updating[i]->brightness2);
        arg(updating[i]->time);
        arg(updating[i]->time2);
      } else {
        arg(updating[i]->id);
        arg(updating[i]->hue);
        arg(updating[i]->hue);
        arg(updating[i]->saturation);
        arg(updating[i]->saturation);
        arg(updating[i]->brightness);
        arg(updating[i]->brightness);
        arg(1000);
        arg(1000);
      }
    }
    snd();
    return true;
  } 
  else {
    return false;
  }
}

bool Breakout404Class::updateCeiling() {
  if (ceiling->updated != currentUpdate) {
    fun(2, "setCCTParameters");
    for (int i = 0; i < 5; i++) {
      arg(i);
      arg(ceiling->enabled ? 1 : 0);
      arg(ceiling->intensity);
      arg(ceiling->cct);
    }
    snd();
    ceiling->updated = currentUpdate;
    return true;
  } 
  else {
    return false;
  }
}

ColorCove *Breakout404Class::nextColorCove() {
  if (_colorCoveIterator == nCoves) {
    _colorCoveIterator = 0;
    return NULL;
  } else {
    return coves[_colorCoveIterator++];
  }
}

Breakout404Class Breakout404;
