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

const unsigned long SWITCH_TIME = 100;
const unsigned long PREVIEW_CHANGE_TIME = 500;
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
  if (msg[BREATHE] && !msg[CEILING])
    newMode = BREATHING;
  else if (msg[PBRI])
    newMode = PREVIEWING;

  int changeTime = (newMode != mode) ? SWITCH_TIME : 0;
  if (changeTime || !lamp->isAnimating()) {
    mode = newMode;
    int duration = (int)((1 - (float)msg[BREATHE] / 100.0) * (float)BREATHE_TIME);
    switch (mode) {
    case BREATHING:
      lamp->hsbTo(msg[HUE1], msg[SAT1], (int)(100 * 2.55 * ((warningOn = !warningOn) ? 0.8 : 0.4)), changeTime || duration);
      break;
    case PREVIEWING:
      lamp->hsbTo(msg[PHUE], msg[PSAT], msg[PBRI], changeTime || PREVIEW_CHANGE_TIME, true);
      break;
    case IDLE:
      lamp->hsbTo(msg[HUE1], msg[SAT1], 0, changeTime || PREVIEW_CHANGE_TIME, true);
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


