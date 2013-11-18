#include <ColorLamp.h>
#include <HardwareTouch.h>
#include <LED.h>
#include <Lithne.h>

void setup() {
  Serial.begin(9600);

  setup404();  
  VuSetup();
  LedSetup();
}

void loop() {
  VuLoop();
  update404();
  LedLoop();
}

