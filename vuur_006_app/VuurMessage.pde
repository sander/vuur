class VuurMessage {
  int hue1 = 222;      // Main effect color
  int sat1 = 143;
  int bri1 = 255;
  int phue = 0;        // Preview color
  int psat = 0;
  int pbri = 0;
  int breathe = 0;     // Preview breathe duration between 0 (0 s) and 100 (2 s)
  
  boolean isSent = false;

  boolean update = true;

  int[] toArray() {
    int[] array = {
      hue1, sat1, bri1, 
      phue, psat, pbri, 
      breathe
    };
    //array[5] = round(float(array[5]) * 0.5);
    return array;
  }

  String toString() {
    StringBuilder sbStr = new StringBuilder();
    int[] array = toArray();
    for (int i = 0; i < array.length; i++) {
      if (i > 0)
        sbStr.append('\t');
      sbStr.append(array[i]);
    }
    sbStr.append('\n');
    return sbStr.toString();
  }

  void sendToLithne() {
    isSent = false;
  }
  
  void actuallySendToLithne() {
    String message = toString();
    lithneSerial.write(message);
    sent += 1;
    //log("message", message);
    isSent = true;
  }
}
