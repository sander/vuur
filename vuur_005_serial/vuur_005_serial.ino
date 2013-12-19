#include <Breakout404.h>
#include <ColorLamp.h>
#include <LED.h>
#include <Lithne.h>

ColorLamp *lamp = new ColorLamp(D11, D12, D14, false);
ColorLamp * lamp2 = new ColorLamp(D2, D1, D3, false);

String input = "";
boolean complete = false;

boolean on = false;

#define MESSAGE_LENGTH 18
enum MessageKey {
  ON,
  HUE1, SAT1, BRI1,
  HUE2, SAT2, BRI2,
  PHUE, PSAT, PBRI,
  ALTERNATE,
  ANIMATE,
  CENTER,
  VARY,
  WIDTH,
  BREATHE,
  BLINK,
  CEILING
};
int msg[MESSAGE_LENGTH];

void setup() {
  Serial.begin(115200);

  Lithne.begin(115200, Serial1);

  Lithne.addNode(COORDINATOR, XBeeAddress64(0x00000000, 0x00000000));
  Lithne.addNode(BROADCAST  , XBeeAddress64(0x00000000, 0x0000FFFF));
  Lithne.addNode(1, XBeeAddress64(0x0013A200, 0x4079CE37)); // color coves

  Lithne.addScope("Breakout404");
}

void loop() {
  // Serial.println("test");
  //delay(100);


  /*
  while (Serial.available()) {
   char in = (char)Serial.read();
   //Serial.println("char");
   input += in;
   //Serial.print(in);
   if (in == '\n') complete = true;
   }
   */
  
  if (Serial.available()) {
    for (int i = 0; i < MESSAGE_LENGTH; i++) {
      msg[i] = Serial.parseInt();
      Serial.read();
    }
  }
  
  if (!lamp->isAnimating()) {
    /*
    //green
    msg[PHUE] = 90;
    msg[PSAT] = 220;
    msg[PBRI] = 255;
    */
    
    /*
    //blue
    msg[PHUE] = 140;
    msg[PSAT] = 255;
    msg[PBRI] = 255;
    */
    lamp->hsbTo(msg[PHUE], msg[PSAT], msg[PBRI], 200, true);
  }
  
  lamp->update();
  
  analogWrite(lamp->getChannelRed(),   255-lamp->getRed());
  analogWrite(lamp->getChannelGreen(), 255-lamp->getGreen());
  analogWrite(lamp->getChannelBlue(),  255-lamp->getBlue());
  
  analogWrite( lamp2->getChannelRed(),   255-lamp->getRed() );
  analogWrite( lamp2->getChannelGreen(), 255-lamp->getGreen() );
  analogWrite( lamp2->getChannelBlue(),  255-lamp->getBlue() ); 
/*
  if (complete) {
    on = !on;
    input = "";
    complete = false;

    Serial.println(on);

    if (on) {
      //on = false;
      //pingpong(5, 80, 80, 150, 150, 200, 255, 1000, 1000);
    } 
    else {
      //on = true;
      // pingpong(5, 80, 80, 150, 150, 0, 0, 1000, 1000);
    }
  }
  */
}

void pingpong(int lamp, int hue1, int hue2, int sat1, int sat2, int bri1, int bri2, int t1, int t2) {
  Lithne.setFunction("pingpong");
  Lithne.setRecipient(1); // 1
  Lithne.setScope("Breakout404");
  Lithne.addArgument(lamp);
  Lithne.addArgument(hue1);
  Lithne.addArgument(hue2);
  Lithne.addArgument(sat1);
  Lithne.addArgument(sat2);
  Lithne.addArgument(bri1);
  Lithne.addArgument(bri2);
  Lithne.addArgument(t1);
  Lithne.addArgument(t2);
  Lithne.send();
}


