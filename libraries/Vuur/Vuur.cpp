#include "Vuur.h"

Pad::Pad(int pinNumber, int hueDeg, int saturationPerc, int brightnessPerc) {
  points = 0;
  pin = TouchPin(pinNumber);
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
