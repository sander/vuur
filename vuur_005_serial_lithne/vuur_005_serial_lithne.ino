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

const unsigned long REGISTER_INTERVAL = 50000;
unsigned long lastRegistered = 0;

enum Phase {
  DUMMY,
  SET_USER_LOCATION,
  RUN
};
int phase = 0;
boolean sendUpdate = true;
boolean updateCeiling = true;
int prevCeiling = 1;

const unsigned long SEND_INTERVAL = 50;
unsigned long lastSend = 0;

char parameterArray[] = {
  // Local Indrect
  1, // 2 colors
  42, // col 1: yellow
  0, // col 2: red
  255, // sat 1: full
  255, // sat 2: full
  255, // bright 1: full
  255, // bright 2: full
  10, // var
  130, // spd
 
  // Peripheral Indirect
  1, // 2 colors
  127, // col 1: blue
  0, // col 2: red
  255, // sat 1: full
  0, // sat 2: full
  0, // bright 1: full
  0, // bright 2: full
  15, // var
  40, // spd
 
  // Local Direct (ignored)
  1, // 1 colors
  42, // col 1: yellow
  0, // col 2: red
  255, // sat 1: full
  255, // sat 2: full
  255, // bright 1: full
  255, // bright 2: full
  5, // var
  40, // spd
 
  // Peripheral Direct (ignored)
  1, // 1 colors
  42, // col 1: yellow
  0, // col 2: red
  255, // sat 1: full
  255, // sat 2: full
  255, // bright 1: full
  255, // bright 2: full
  5, // var
  40, // spd
};

void setup() {
  Serial.begin(115200);
    
  Lithne.begin(115200, Serial1);
  Lithne.addNode(COORDINATOR, XBeeAddress64(0x00000000, 0x00000000));
  Lithne.addNode(BROADCAST  , XBeeAddress64(0x00000000, 0x0000FFFF));   
  Lithne.addNode(1, XBeeAddress64(0x0013A200, 0x4079CE37/*40*/)); // color coves
  Lithne.addNode(2, XBeeAddress64(0x0013A200, 0x4079CE25)); // cct tiles
  Lithne.addNode(9, XBeeAddress64(0x0013A200, 0x4079CE24)); // solime
  Lithne.addScope("Breakout404");  
  
  lastSend = millis();
  
  lamp->setAnimationType(QUADRATIC, true, true);

  // TODO handle ceiling and solime
}

void loop() {
  if (read()) {
    parameterArray[1] = msg[HUE1];
    parameterArray[3] = msg[SAT1];
    parameterArray[5] = msg[BRI1];
    
    sendUpdate = true;
  }
  
  if (Lithne.available()) {
    processLithneMessage();
  }
  
  if (msg[CEILING] != prevCeiling) {
    updateCeiling = true;
    prevCeiling = msg[CEILING];
  }

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
  
  /*
  float center = 8.0 * (float)msg[CENTER] / 255.0;
  float width = 8.0 * (float)msg[WIDTH] / 255.0;
  while (ColorCove *cove = Breakout404.nextColorCove()) {
    int id = cove->id;
    boolean first = !msg[ALTERNATE] || (id % 2);
    float distance = max(1.0 - abs( ((id < 8) ? center : 8 - center) - (float)(id % 8) ) / width, 0);
    cove->hue = msg[first ? HUE1 : HUE2];
    cove->saturation = msg[first ? SAT1 : SAT2];
    cove->brightness = (int)((float)msg[first ? BRI1 : BRI2] * distance);
    
    if (msg[ANIMATE]) {
      int time = random(50, 200);
      cove->hue2 = cove->hue;
      cove->saturation2 = cove->saturation;
      cove->brightness2 = 40;
      cove->time = time;
      cove->time2 = time;
    } else {
      cove->time = cove->time2 = 0;
    }
  }
  */

  update();
  
  if (millis() - lastRegistered > REGISTER_INTERVAL) {
    Lithne.setFunction("registerSensorListener");
    Lithne.setRecipient(34);
    Lithne.setScope("Breakout404");
    Lithne.send();
    lastRegistered = millis();
    Serial.println("register: ");
  }
}

boolean read() {
  while (Serial.available()) {
    for (int i = 0; i < MESSAGE_LENGTH; i++) {
      msg[i] = Serial.parseInt();
      Serial.read();
      return true;
    }
  }
  return false;
}

void processLithneMessage() {
  if (Lithne.functionIs("motion")) {
    Serial.print("motion: ");
    Serial.println(Lithne.getArgument(0));
  } else if (Lithne.functionIs("loudness")) {
    Serial.print("loudness: ");
    Serial.println(Lithne.getArgument(0));
  }
}

void update() {
  lamp->update();

  analogWrite(lamp->getChannelRed(), lamp->getRed());
  analogWrite(lamp->getChannelGreen(), lamp->getGreen());
  analogWrite(lamp->getChannelBlue(), lamp->getBlue());

  if (msg[ON]) {
    if (millis() - lastSend > SEND_INTERVAL) {
      switch (phase) {
        case DUMMY:
        case SET_USER_LOCATION:
          setUserLocation(250, 500);
          phase++;
          break;
        case RUN:
          if (sendUpdate) {
            sendParamArray();
            sendUpdate = false;
          } else if (updateCeiling) {
            sendCeiling();
            updateCeiling = false;
          }
          break;
      }
    }
  }
}

void sendParamArray() {
  setLightParameters( parameterArray );
}
 
void setLightParameters( char paramArray[] ) {
  Lithne.setFunction("lightParameters");
  Lithne.setScope("Breakout404");
  Lithne.setRecipient(1);
  for (int i = 0; i < 36; i++) {
    Lithne.addByte(paramArray[i]);
  }
  send();
}

void setCeiling() {
  
    if (msg[CEILING]) {
      Breakout404.ceiling->intensity = 150;
      Breakout404.ceiling->cct = 50;
    } else {
      Breakout404.ceiling->intensity = 0;
      Breakout404.ceiling->cct = 200; 
    }
}

void setUserLocation(int x, int y) {
  Lithne.setFunction("setUserLocation");
  Lithne.setScope("Breakout404");
  Lithne.setRecipient(BROADCAST);
  Lithne.addArgument(x);
  Lithne.addArgument(y);
  send();
}

void send() {
  Lithne.send();
  Serial.println("sent");
  lastSend = millis();
}
