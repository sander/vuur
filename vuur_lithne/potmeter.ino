const int potMinValue = 47;
const int potMaxValue = 1023;

int previousSensorValue = 0;

float readPotmeter() {
  int sensorValue = analogRead(A0);
  
  if (abs(sensorValue - previousSensorValue) < 5)
    sensorValue = previousSensorValue;
  
  previousSensorValue = sensorValue;

  float translated = (float)(potMaxValue - sensorValue) / (float)(potMaxValue - potMinValue);
  return max(0, min(1, translated));
}
