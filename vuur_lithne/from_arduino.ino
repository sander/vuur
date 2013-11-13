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
    Serial6.read();
    Serial6.read();
    if (VuIsStopped()) return;
    switch (cmd) {
      case ADD_PT:
        // add point to pad
        Serial.println("add point to pad");
        VuAddPoints(arg);
        break;
      case ADD_BONUS_PT:
        // add point to pad
        Serial.println("add bonus point to pad");
        VuAddBonusPoints(arg);
        break;
      case TOUCH_RECORD:
        // add point to pad
        Serial.println("record");
        VuSetTouchRecord(arg);
        break;
      case TOUCH_DURATION:
        // add point to pad
        Serial.println("touch duration");
        VuSetVariation(arg);
        break;
      case STOP:
        Serial.println("stopping for 1s");
        VuStop();
        break;
      default:
        //Serial.print("unknown cmd: ");
        //Serial.print(cmd);
        //Serial6.read();
        //Serial6.read();
        while (Serial6.available())
          Serial.print(Serial6.read());
        Serial.println();
        break;
    }
  }
}
