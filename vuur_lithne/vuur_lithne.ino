#include <HardwareTouch.h>
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
