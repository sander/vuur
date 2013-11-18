#define N_LEDS 3

LED *leds[3];
ColorLamp *lamp = new ColorLamp(D10, D11, D12, false); 

void LedSetup() {
  leds[0] = new LED(D0, true);
  leds[1] = new LED(D1, true);
  leds[2] = new LED(D2, true);
  
  for (int i = 0; i < N_LEDS; i++) {
    leds[i]->setAnimationType(QUADRATIC, true, true);
    leds[i]->intensityTo(255, 0);
  }
  
  lamp->intensityTo(255, 0);
  lamp->saturationTo(0, 0);
}

void LedLoop() {
  lamp->update();

  for (int i = 0; i < N_LEDS; i++) {
    if (!leds[i]->isAnimating()) {
      leds[i]->intensityTo(lamp->getRed(), 0);
    }
    leds[i]->update();
  }
  
  analogWrite(lamp->getChannelRed(), 255 - lamp->getRed());
  analogWrite(lamp->getChannelGreen(), 255 - lamp->getGreen());
  analogWrite(lamp->getChannelBlue(), 255 - lamp->getBlue());
}
