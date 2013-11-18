#include "Vuur.h"

Pad::Pad(int pinNumber, int hueDeg, int saturationPerc, int brightnessPerc) {
  points = 0;
  pin = TouchPin(pinNumber);
  pin.setThreshold(2);
  pin.calibrate();
  hue = (int)( (float)hueDeg / 360.0 * 255.0 );
  saturation = (int)( (float)saturationPerc / 100.0 * 255.0 );
  brightness = (int)( (float)brightnessPerc / 100.0 * 255.0 );
  lastUpdate = millis();
  touched = false;
  ptAdded = 0;
}

Vuur::Vuur() {
  for (int i = 0; i < 16; i++) {
    distances[i] = abs( ((i < 8) ? center : 8 - center) - (float)(i % 8) );
  }
}

void Vuur::setPads(int config[4 * nPads]) {
  for (int i = 0; i < nPads; i++) {
    pads[i] = new Pad(config[i * 4],
                      config[i * 4 + 1],
                      config[i * 4 + 2],
                      config[i * 4 + 3]);
  }
}

void Vuur::update() {
  int newNTouched = 0;
  for (int i = 0; i < nPads; i++) {
    Pad *pad = pads[i];
    boolean touched = pad->pin.touched();
    boolean newValue = touched != pad->touched;
    pad->touched = touched;
    if (touched) {
      newNTouched++;

      // TODO do in loop
      //lamp->hsbTo(pad->hue, pad->saturation, pad->brightness, 100);

      // TODO
      //VuAddPoints(pad);

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
      // TODO
      //VuSetVariation(millis() - pad->touchStart);

      if (i == doubleTapPad && millis() - doubleTapTime < doubleTapInterval) {
        if (doubleTapState == 1) {
          doubleTapState = 2;
          doubleTapTime = millis();
        } 
        else if (doubleTapState == 3) {
          stop();
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
}

Pad *Vuur::winning() {
  int winning = -1;
  int highest = 0;
  for (int i = 0; i < nPads; i++) {
    int points = pads[i]->points;
    if (points > highest) {
      winning = i;
      highest = points;
    }
  }
  if (winning > -1) {
    return pads[winning];
  } else {
    return NULL;
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

void Vuur::stop() {
  variation - 0;
  touchRecord = 0;
  for (int i = 0; i < nPads; i++) {
    pads[i]->points = 0;
  }
  _stopped = millis();
}

float Vuur::fraction() {
  float fraction = (float)totalPoints() / (float)maxPoints;
}
