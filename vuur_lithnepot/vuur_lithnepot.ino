#include <Lithne.h>

void setup() {
  Serial.begin(9600);
  
  FaSetup();
  
  setupLithne();
  setup404();
  
  VuSetup();
  LedSetup();
}

void loop() {
  //float value = readPotmeter();
  
  //int translated = (int)(value * 255.0);
  
  //test404();
  FaLoop();
  VuLoop();
  update404();
  LedLoop();
  
  //vuSetEnabled(translated);
  
    //setAllCoves(100, 0, 255);

  
  //vuLoop();
}
