#include <ColorLamp.h>
#include <LED.h>
#include <Lithne.h>

ColorLamp *lamp = new ColorLamp(D2, D0, D1, false);

String input = "";
boolean complete = false;

boolean on = false;

const int MESSAGE_LENGTH = 7;
enum MessageKey {
  HUE1, SAT1, BRI1,
  PHUE, PSAT, PBRI,
  BREATHE
};
int msg[MESSAGE_LENGTH];

const unsigned long SWITCH_TIME = 50;
const unsigned long PREVIEW_CHANGE_TIME = 300;
const unsigned long BREATHE_TIME = 2000;
boolean warningOn = true;

enum Mode {
  IDLE,
  BREATHING,
  PREVIEWING
};
int mode = IDLE;

void setup() {
  Serial.begin(115200);

  lamp->setAnimationType(QUADRATIC, true, true);

  lamp->hsbTo(255, 0, 255, 0, true);
}

void loop() {
  read();

  int newMode = IDLE;
  if (msg[BREATHE] != 0)
    newMode = BREATHING;
  else if (msg[PBRI] != 0)
    newMode = PREVIEWING;
    
  int changeTime = (newMode != mode) ? SWITCH_TIME : 0;
  mode = newMode;
  if (changeTime != 0 || !lamp->isAnimating()) {
    int duration = (int)((1 - (float)msg[BREATHE] / 100.0) * (float)BREATHE_TIME);
    int time;
    switch (mode) {
    case BREATHING:
      time = (changeTime) ? changeTime : duration;
      lamp->hsbTo(msg[HUE1], msg[SAT1], (int)(100 * 2.55 * ((warningOn = !warningOn) ? 0.8 : 0.2)), time, true);
      break;
    case PREVIEWING:
      time = (changeTime) ? changeTime : PREVIEW_CHANGE_TIME;
      lamp->hsbTo(msg[PHUE], msg[PSAT], msg[PBRI], time, true);
      break;
    case IDLE:
      time = (changeTime) ? changeTime : PREVIEW_CHANGE_TIME;
      lamp->hsbTo(msg[HUE1], msg[SAT1], 0, time, true);
      break;
    }
  }

  update();
}

boolean read() {
  while (Serial.available()) {
    for (int i = 0; i < MESSAGE_LENGTH; i++) {
      msg[i] = Serial.parseInt();
      Serial.read();
    }
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


