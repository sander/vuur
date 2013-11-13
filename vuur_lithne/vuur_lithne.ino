#include <Lithne.h>

void setup() {
  Serial.begin(9600);
  
  FaSetup();
  setup404();  
  VuSetup();
  LedSetup();
}

void loop() {
  FaLoop();
  VuLoop();
  update404();
  LedLoop();
}
