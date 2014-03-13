#include <ColorLamp.h>
#include <LED.h>
#include <Lithne.h>

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

const unsigned long PREVIEW_CHANGE_TIME = 500;
boolean warningOn = true;

void setup() {
  Serial.begin(115200);
  
  lamp->setAnimationType(QUADRATIC, true, true);
  
  lamp->hsbTo(255, 0, 255, 0, true);
}

void loop() {
  read();

  if (!lamp->isAnimating()) {
    
    if (msg[BREATHE] && !msg[CEILING]) {
      int duration = (int)((1 - (float)msg[BREATHE] / 100.0) * 2000.0);
      lamp->hsbTo(msg[HUE1], msg[SAT1], (int)(100 * 2.55 * ((warningOn = !warningOn) ? 0.8 : 0.4)), duration);
    } else if (msg[PHUE] || msg[PSAT] || msg[PBRI]) {
      lamp->hsbTo(msg[PHUE], msg[PSAT], msg[PBRI], PREVIEW_CHANGE_TIME, true);
    } else {
      lamp->hsbTo(msg[HUE1], msg[SAT1], 0, PREVIEW_CHANGE_TIME, true);
    }
    
    //lamp->hsbTo(msg[PHUE], msg[PSAT], msg[PBRI], PREVIEW_CHANGE_TIME, true);
  }

  update();
}

boolean read() {
  while (Serial.available()) {
    
    for (int i = 0; i < MESSAGE_LENGTH; i++) {
      msg[i] = Serial.parseInt();
      Serial.read();
    }
    
    //Serial.read();
    //msg[PHUE] = msg[PSAT] = msg[PBRI] = 255;
    return true;
  }
  return false;
}

void update() {
  lamp->update();

  analogWrite(lamp->getChannelRed(), lamp->getRed());
  analogWrite(lamp->getChannelGreen(), lamp->getGreen());
  analogWrite(lamp->getChannelBlue(), lamp->getBlue());
}
