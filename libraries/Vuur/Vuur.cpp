#include "Vuur.h"

HSBColor::HSBColor(int hueDeg, float saturationFrac, float brightnessFrac) {
  hue = (int)( (float)hueDeg / 360.0 * 255.0 );
  saturation = (int)( saturationFrac * 255.0 );
  brightness = (int)( brightnessFrac * 255.0 );
}

Pad::Pad(Vuur *vuur, int _id, int pinNumber) {
  _vuur = vuur;

  id = _id;
  points = 0;
  pin = TouchPin(pinNumber);
  pin.setThreshold(2);
  pin.calibrate();

  lastUpdate = millis();
  touchStart = 0;
  ptAdded = 0;
  touchDuration = 0;

  touched = false;
  untouched = false;
}

Vuur::Vuur() {
  int ports[] = {D0, D1, D2};
  for (int i = 0; i < nMonoLEDs; i++) {
    mono[i] = new LED(ports[i], true);
    mono[i]->setAnimationType(QUADRATIC, true, true);
    mono[i]->intensityTo(255, 0);
  }

  rgb = new ColorLamp(D10, D11, D12, false);
  rgb->intensityTo(255, 0);
  rgb->saturationTo(0, 0);

  int pins[] = {A6, A3, A2, A9, A0, A1, A4, A12, A10, A8, A5, A6};
  for (int i = 0; i < nPads; i++)
    pads[i] = new Pad(this, i, pins[i]);

  lastTouched = NULL;
  winning = NULL;

  stopDuration = 1000;
  doubleTapInterval = 500;
  touchRecordInterval = 1000;
  maxPoints = 0;
  doubleTapPad = -1;

  variation = 0;
  touchRecord = 0;

  width = 0.0;
  fraction = 0.0;
  for (int i = 0; i < 16; i++)
    distances[i] = 0.0;

  touchRecordTime = 0;
  doubleTapTime = 0;

  nTouched = 0;
  doubleTapState = 0;
  doubleTapped = false;

  _stopped = 0;
  _iterator = 0;
  _center = 0;
}

void Vuur::setCenter(float center) {
  _center = center;
  for (int i = 0; i < 16; i++) {
    distances[i] = abs( ((i < 8) ? center : 8 - center) - (float)(i % 8) );
  }
}

float Vuur::center() {
  return _center;
}

void Vuur::update() {
  doubleTapped = false;
  int newNTouched = 0;
  for (int i = 0; i < nPads; i++) {
    Pad *pad = pads[i];
    pad->untouched = false;
    boolean touched = pad->pin.touched();
    boolean newValue = touched != pad->touched;
    pad->touched = touched;
    if (touched) {
      newNTouched++;
      lastTouched = pad;

      if (newValue) {
        pad->touchStart = millis();
        if (i == doubleTapPad) {
          if (doubleTapState == 0 ||
              millis() - doubleTapTime >= doubleTapInterval) {
            doubleTapState = 1;
            doubleTapTime = millis();
          } 
          else if (doubleTapState == 2 &&
                   millis() - doubleTapTime < doubleTapInterval) {
            doubleTapState = 3;
            doubleTapTime = millis();
          }
        }
      }
    } 
    else if (newValue) {
      pad->touchDuration = millis() - pad->touchStart;
      pad->untouched = true;

      if (i == doubleTapPad && millis() - doubleTapTime < doubleTapInterval) {
        if (doubleTapState == 1) {
          doubleTapState = 2;
          doubleTapTime = millis();
        }
        else if (doubleTapState == 3) {
          doubleTapped = true;
          doubleTapState = 0;
          doubleTapTime -= doubleTapInterval;
        }
      }
    }
  }
  nTouched = newNTouched;
  if (newNTouched > touchRecord) {
    touchRecord = newNTouched;
  } 
  if (newNTouched >= touchRecord) {
    touchRecordTime = millis();
  } 
  else if (touchRecord > 0 &&
           millis() - touchRecordTime > touchRecordInterval) {
    touchRecordTime = millis();
    touchRecord--;
  }

  winning = NULL;
  int highest = 0;
  for (int i = 0; i < nPads; i++) {
    int points = pads[i]->points;
    if (points > highest) {
      winning = pads[i];
      highest = points;
    }
  }

  fraction = _fraction();

  rgb->update();
  for (int i = 0; i < nMonoLEDs; i++) {
    if (!mono[i]->isAnimating()) {
      mono[i]->intensityTo(rgb->getRed(), 0);
    }
    mono[i]->update();
  }

  analogWrite(rgb->getChannelRed(), 255 - rgb->getRed());
  analogWrite(rgb->getChannelGreen(), 255 - rgb->getGreen());
  analogWrite(rgb->getChannelBlue(), 255 - rgb->getBlue());
}

Pad *Vuur::nextPad() {
  if (_iterator == nPads) {
    _iterator = 0;
    return NULL;
  } else {
    return pads[_iterator++];
  }
}

int Vuur::totalPoints() {
  int pts = 0;
  for (int i = 0; i < nPads; i++) {
    pts += pads[i]->points;
  }
  return pts;
}

bool Vuur::stopped() {
  return (millis() - _stopped < stopDuration);
}

void Vuur::reset() {
  variation = 0;
  touchRecord = 0;
  for (int i = 0; i < nPads; i++) {
    pads[i]->points = 0;
  }
  _stopped = millis();
}

float Vuur::_fraction() {
  return (float)totalPoints() / (float)maxPoints;
}

void Vuur::setRGB(HSBColor *color, int time) {
  rgb->hsbTo(color->hue, color->saturation, color->brightness, time);
}

void Pad::addPoints(int add) {
  lastUpdate = millis();
  if (add > 0) ptAdded = lastUpdate;
  points += add;
  points -= max(0, _vuur->totalPoints() - _vuur->maxPoints);
}

unsigned long timeSince(unsigned long time) {
  return millis() - time;
}

void Pad::listenToDoubleTap() {
  _vuur->doubleTapPad = id;
}

bool Pad::doubleTapped() {
  return _vuur->doubleTapped;
}
