#include <LED.h>

#define N_LEDS 3

LED *leds[3];

void LedSetup() {
  leds[0] = new LED(D0, true);
  leds[1] = new LED(D1, true);
  leds[2] = new LED(D2, true);
  
  for (int i = 0; i < N_LEDS; i++) {
    leds[i]->setAnimationType(QUADRATIC, true, true);
    leds[i]->intensityTo(255, 0);
  }
}

void LedLoop() {
  for (int i = 0; i < N_LEDS; i++) {
    if (!leds[i]->isAnimating()) {
      float fraction = VuFraction();
      leds[i]->intensityTo((int)(fraction * 255.0));
    }
    leds[i]->update();
  }
}
