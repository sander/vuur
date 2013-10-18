#define ADD_PT 1
#define ADD_BONUS_PT 2
#define TOUCH_RECORD 3
#define TOUCH_DURATION 4
#define STOP 5

void FaSetup() {
  Serial6.begin(9600);
}

void FaLoop() {
  if (Serial6.available()) {
    int cmd = Serial6.parseInt();
    int arg = Serial6.parseInt();
    switch (cmd) {
      case ADD_PT:
        // add point to pad
        Serial.println("add point to pad");
        VuAddPoints(arg);
        Serial6.read();
        Serial6.read();
        break;
      case ADD_BONUS_PT:
        // add point to pad
        Serial.println("add bonus point to pad");
        VuAddBonusPoints(arg);
        Serial6.read();
        Serial6.read();
        break;
      case TOUCH_RECORD:
        // add point to pad
        Serial.println("record");
        VuSetTouchRecord(arg);
        Serial6.read();
        Serial6.read();
        break;
      case TOUCH_DURATION:
        // add point to pad
        Serial.println("touch duration");
        VuSetVariation(arg);
        Serial6.read();
        Serial6.read();
        break;
      default:
        Serial.print("unknown cmd: ");
        Serial.print(cmd);
        while (Serial6.available())
          Serial.print(Serial6.read());
        Serial.println();
        break;
    }
  }
}
