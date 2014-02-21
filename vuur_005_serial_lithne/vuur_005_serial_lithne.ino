#include <Breakout404.h>
#include <ColorLamp.h>
#include <LED.h>
#include <Lithne.h>

// Both lamps will take the values provided to lamp.
//ColorLamp *lamp = new ColorLamp(D11, D12, D14, false);
//ColorLamp *lamp2 = new ColorLamp(D2, D1, D3, false);
ColorLamp *lamp = new ColorLamp(D2, D0, D1, false);

String input = "";
boolean complete = false;

boolean on = false;

const int MESSAGE_LENGTH = 18;
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

const int PREVIEW_CHANGE_TIME = 500;
boolean warningOn = true;

void setup() {
  Serial.begin(115200);
  
  lamp->setAnimationType(QUADRATIC, true, true);

  Breakout404.ceiling->enabled = true;
  Breakout404.solime->brightness = 0;
}

void loop() {
  read();
  
  if (msg[CEILING]) {
    Breakout404.ceiling->intensity = 150;
    Breakout404.ceiling->cct = 50;
  } 
  else {
    Breakout404.ceiling->intensity = 0;
    Breakout404.ceiling->cct = 200;
  }
  //Serial.print("ceiling: ");
  //Serial.println(Breakout404.ceiling->intensity);
  //Serial.print("on: ");
  //Serial.println(msg[ON]);
  //Serial.print("hue1: ");
  //Serial.println(msg[HUE1]);

  if (!lamp->isAnimating()) {
    
    if (msg[BREATHE] && !msg[CEILING]) {
      int duration = (int)((1 - (float)msg[BREATHE] / 100.0) * 2000.0);
      lamp->hsbTo(msg[HUE1], msg[SAT1], (int)(/*msg[BREATHE] **/ 100 * 2.55 * ((warningOn = !warningOn) ? 0.8 : 0.4)), duration);
    } else if (msg[PHUE] || msg[PSAT] || msg[PBRI]) {
      lamp->hsbTo(msg[PHUE], msg[PSAT], msg[PBRI], PREVIEW_CHANGE_TIME, true);
    } else {
      lamp->hsbTo(msg[HUE1], msg[SAT1], 0, PREVIEW_CHANGE_TIME, true);
    }
  }
  
  float center = 8.0 * (float)msg[CENTER] / 255.0;
  float width = 8.0 * (float)msg[WIDTH] / 255.0;
  while (ColorCove *cove = Breakout404.nextColorCove()) {
    int id = cove->id;
    boolean first = !msg[ALTERNATE] || (id % 2);
    float distance = max(1.0 - abs( ((id < 8) ? center : 8 - center) - (float)(id % 8) ) / width, 0);
    cove->hue = msg[first ? HUE1 : HUE2];
    cove->saturation = msg[first ? SAT1 : SAT2];
    cove->brightness = (int)((float)msg[first ? BRI1 : BRI2] * distance);
    // TODO set other pingpong values
  }
  Serial.print("hue: ");
  Serial.println(Breakout404.coves[7]->brightness);

  update();
}

void read() {
  while (Serial.available())
    for (int i = 0; i < MESSAGE_LENGTH; i++) {
      msg[i] = Serial.parseInt();
      Serial.read();
      /*
      Serial.print(i);
      Serial.print(": ");
      Serial.println(msg[i]);

      */
    }
}

void update() {
  lamp->update();

  analogWrite(lamp->getChannelRed(), lamp->getRed());
  analogWrite(lamp->getChannelGreen(), lamp->getGreen());
  analogWrite(lamp->getChannelBlue(), lamp->getBlue());

/*
  analogWrite(lamp2->getChannelRed(), 255 - lamp->getRed());
  analogWrite(lamp2->getChannelGreen(), 255 - lamp->getGreen());
  analogWrite(lamp2->getChannelBlue(), 255 - lamp->getBlue()); 
  */

  if (msg[ON])
    Breakout404.update();
}
