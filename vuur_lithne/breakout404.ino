//const int lithneDelay = 1000;

void setupLithne() {
  Lithne.begin(115200, Serial1);
  Lithne.addNode(COORDINATOR, XBeeAddress64(0x00000000, 0x00000000));
  Lithne.addNode(BROADCAST  , XBeeAddress64(0x00000000, 0x0000FFFF));   
  Lithne.addNode(1, XBeeAddress64(0x0013A200, 0x4079CE37)); // color coves
  Lithne.addNode(2, XBeeAddress64(0x0013A200, 0x4079CE25)); // cct ceiling tiles
  Lithne.addNode(3, XBeeAddress64(0x0013A200, 0x4079CE26)); // blinds
  Lithne.addNode(9, XBeeAddress64(0x0013A200, 0x4079CE24)); // solime
  
  Lithne.addScope("Breakout404");
}

/*
void setAllCoves(int hue, int saturation, int brightness) {
  Lithne.setFunction("setAllHSB");
  Lithne.setScope("Breakout404");
  Lithne.setRecipient(9);
  Lithne.addArgument(hue);
  Lithne.addArgument(saturation);
  Lithne.addArgument(brightness);
  Lithne.send();
  //delay(lithneDelay);
}

void setSolime(int hue, int saturation, int brightness) {
  // Doesn't work!
  Lithne.setFunction("setAllHSB");
  Lithne.setScope("Breakout404");
  Lithne.setRecipient(3);
  Lithne.addArgument(hue);
  Lithne.addArgument(saturation);
  Lithne.addArgument(brightness);
  Lithne.send();
  //delay(lithneDelay);
}

void setFullCeiling(int state, int intensity, int cct) {
  Lithne.setFunction("setCCTParameters");
  Lithne.setScope("Breakout404");
  Lithne.setRecipient(2);
  for (int i = 0; i < 5; i++) {
    Lithne.addArgument(i);
    Lithne.addArgument(state);
    Lithne.addArgument(intensity);
    Lithne.addArgument(cct);
  }
  Lithne.send();
  //delay(lithneDelay);
}

void setCoveParametrics(int id, int hue, int saturation, int brightness, int variation, int speed) {
  Lithne.setFunction("parametrics");
  Lithne.setScope("Breakout404");
  Lithne.setRecipient(9);
  Lithne.addArgument(id);
  Lithne.addArgument(hue);
  Lithne.addArgument(saturation);
  Lithne.addArgument(brightness);
  Lithne.addArgument(variation);
  Lithne.addArgument(speed);
  Lithne.send();
  //delay(lithneDelay);
}
*/
