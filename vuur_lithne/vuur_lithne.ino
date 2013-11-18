#include <Breakout404.h>
#include <ColorLamp.h>
#include <HardwareTouch.h>
#include <LED.h>
#include <Lithne.h>
#include <Vuur.h>

void setup() {
  Serial.begin(9600);

  VuSetup();
  LedSetup();
}

void loop() {
  VuLoop();
  LedLoop();
  
  Breakout404.update();
}

