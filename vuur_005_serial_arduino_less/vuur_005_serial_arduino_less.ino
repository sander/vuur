#include <CapacitiveSensor.h>

const boolean AUTO_CALIBRATE = false;
const int N = 16;
CapacitiveSensor cs[N] = {
  CapacitiveSensor(12, A0),
  CapacitiveSensor(12, A1),
  CapacitiveSensor(12, A2),
  CapacitiveSensor(12, A3),
  CapacitiveSensor(12, A4),
  CapacitiveSensor(12, A5),
  CapacitiveSensor(12, 11),
  CapacitiveSensor(12, 10),
  CapacitiveSensor(12, 9),
  CapacitiveSensor(12, 8),
  CapacitiveSensor(12, 7),
  CapacitiveSensor(12, 6),
  CapacitiveSensor(12, 5),
  CapacitiveSensor(12, 4),
  CapacitiveSensor(12, 3),
  CapacitiveSensor(12, 2),
};

void setup() {
  Serial.begin(115200);
  if (!AUTO_CALIBRATE)
    for (int i = 0; i < N; i++)
      if (i != 9)
      cs[i].set_CS_AutocaL_Millis(0xFFFFFFFF);
}

void loop() {
  long start = millis();
  long total[N];
  total[0] = total[1] = 0;
  for (int i = 2; i < N; i++)
        if (i != 9)
    total[i] = cs[i].capacitiveSensor(2);

  Serial.print(millis() - start);
  for (int i = 0; i < N; i++) {
    Serial.print("\t");
    if (i == 9)
    Serial.print(-2);
    else
    Serial.print(total[i]);
  }
  Serial.println();

  delay(50);
}

