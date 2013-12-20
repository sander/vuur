#include <Breakout404.h>
#include <ColorLamp.h>
#include <LED.h>
#include <Lithne.h>

// Both lamps will take the values provided to lamp.
ColorLamp *lamp = new ColorLamp(D11, D12, D14, false);
ColorLamp *lamp2 = new ColorLamp(D2, D1, D3, false);

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

  Breakout404.ceiling->enabled = true;
  Breakout404.solime->brightness = 0;
}

void loop() {
  if (Serial.available()) {
    for (int i = 0; i < MESSAGE_LENGTH; i++) {
      msg[i] = Serial.parseInt();
      Serial.read();
    }
  }

  if (!lamp->isAnimating()) {
    if (msg[BREATHE])
      lamp->hsbTo(msg[HUE1], msg[SAT1], (int)(msg[BREATHE] * ((warningOn = !warningOn) ? 1.0 : 0.5)), (int)(1 - (float)msg[BREATHE] / 255.0 * 2000.0));
    else if (msg[PHUE] || msg[PSAT] || msg[PBRI])
      lamp->hsbTo(msg[PHUE], msg[PSAT], msg[PBRI], PREVIEW_CHANGE_TIME, true);
    else
      lamp->hsbTo(0, 0, 0, PREVIEW_CHANGE_TIME, true);
  }

  lamp->update();

  analogWrite(lamp->getChannelRed(), 255 - lamp->getRed());
  analogWrite(lamp->getChannelGreen(), 255 - lamp->getGreen());
  analogWrite(lamp->getChannelBlue(), 255 - lamp->getBlue());

  analogWrite(lamp2->getChannelRed(), 255 - lamp->getRed());
  analogWrite(lamp2->getChannelGreen(), 255 - lamp->getGreen());
  analogWrite(lamp2->getChannelBlue(), 255 - lamp->getBlue()); 

  if (msg[ON])
    Breakout404.update();
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



