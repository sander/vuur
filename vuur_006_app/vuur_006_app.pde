// Configuration

// Screen size and layout (x, y, width, height)
final int WIDTH = 1440;
final int HEIGHT = 900;
final int[] SENSOR_DISPLAY = {
  10, 10, 580, 580
};
final int[] MESSAGE_DISPLAY = {
  10, 600, 1420, 200
};

// Time intervals are in milliseconds

// How long to wait before marking a pad as untouched
final int TOUCH_COOLDOWN = 100;

// How long a pad needs to sense a high value before it is considered touched
final int TOUCH_TIMEOUT = 200;

// How long to wait before adding another point
final int ADD_POINT_INTERVAL = 200;

// How long to wait before removing a point
final int FADE_INTERVAL = 1000;

// How many taps are needed before activating the 'alternate' mode
final int TAP_AMOUNT = 3;

// Time interval within which TAP_AMOUNT taps need to be done
final int TAP_TIMEOUT = 2000;

// During a long press, how long to wait before the action is applied
final int APPLY_TIMEOUT = 3000;

final int MESSAGE_INTERVAL = 100;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Where to store the sensor calibration
final String CALIBRATION_FILE = "calibration.dump";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

long paramsLastSent = 0;

import processing.serial.*;
import ili.lithne.*;

Lithne lithne;
final NodeManager nm = new NodeManager();

Serial arduino;
Serial lithneSerial;

int max;
float threshold;

class Pad {
  int min;
  int max;
  long lastSense;

  // Store the last measured sensor values
  int value;
}
final int nPads = 16;
Pad[] pads = new Pad[nPads];

// Use to draw on screen
PFont font = createFont("AvenirNext-DemiBold", 14);

// Set to true once sensor data has come in
boolean receiving = false;

class State {
  static final int RUNNING = 0;
  static final int CALIBRATE_NOT_TOUCHED = 1;
  static final int CALIBRATE_TOUCHED = 2;
}
int state;

// Message, the values of which are sent to Lithne on send_to_lithne
class VuurMessage {
  int on = 0;          // Send signals to Breakout 404?
  int hue1 = 222;      // Main effect color
  int sat1 = 143;
  int bri1 = 255;
  int hue2 = 0;        // Secondary effect color
  int sat2 = 0;
  int bri2 = 0;
  int phue = 0;        // Preview color
  int psat = 0;
  int pbri = 0;
  int alternate = 0;   // Show alternating secondary effect color? 1 or 0
  int animate = 0;     // Instead of using the secondary color,
  // animate and animate with the dimmed main color
  int center = 200;    // Center of light effect in room, 0-255 mapped to 0.0-8.0
  int vary = 0;        // Ignored
  int width = 100;     // Width of light effect, 0-255 mapped to 0.0-8.0
  int breathe = 0;     // Preview breathe duration between 0 (0 s) and 100 (2 s)
  int blink = 0;       // Ignored
  int ceiling = 1;     // Enable main ceiling light? 1 or 0

  boolean update = true;

  int[] toArray() {
    int[] array = {
      on, 
      hue1, sat1, bri1, 
      hue2, sat2, bri2, 
      phue, psat, pbri, 
      alternate, animate, 
      center, vary, width, 
      breathe, blink, ceiling
    };
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
    String message = toString();
    lithneSerial.write(message);
    sent += 1;
    // TODO log("message", message);
  }
}
VuurMessage message = new VuurMessage();

// Points between 0 (no effect) and 100 (full effect)
byte points = 0;

// Draw on screen? Very inefficient, disable for long-term usage
boolean drawing = true;

// Which point coordinates is the preview based on
float[] preview = {
  -1.0, -1.0
};

// Amount of messages sent
int sent = 0;

int touch_time = 0;
int touch_start_time = 0;
int touch_end_time = 0;
int touch_amount = 0;
int touch_amount_time = 0;
float touch_distance = 0;
int last_touch_position = -1;
int last_touch_duration = 0;
int[][] last_touch_durations = {
};
int swipe_time = 0;
int points_changed = 0;

int sense_time = 0;
int last_sense_position = 0;
int sense_amount = 0;
int sense_amount_time = 0;
int sense_start_time = 0;

String cached_mode = null;
String cached_status = null;
IntList cached_sensed_points = null;
IntList cached_touch_points = null;
IntList cached_activated_points = null;
IntList previous_activated_points = null;

float[] center = null;
float[] previous_center = null;

int[] values = new int[16];

boolean hasRun = false;

char parameterArray[] = {
  // Local Indrect
  2, // 2 colors
  0, // col 1: yellow
  128, // col 2: red
  255, // sat 1: full
  255, // sat 2: full
  255, // bright 1: full
  255, // bright 2: full
  10, // var
  0, // spd

  // Peripheral Indirect
  2, // 2 colors
  0, // col 1: blue
  0, // col 2: red
  0, // sat 1: full
  0, // sat 2: full
  0, // bright 1: full
  0, // bright 2: full
  15, // var
  0, // spd

  // Local Direct
  1, // 1 colors
  42, // col 1: yellow
  0, // col 2: red
  255, // sat 1: full
  255, // sat 2: full
  255, // bright 1: full
  255, // bright 2: full
  5, // var
  0, // spd

  // Peripheral Direct
  1, // 1 colors
  42, // col 1: yellow
  0, // col 2: red
  255, // sat 1: full
  255, // sat 2: full
  255, // bright 1: full
  255, // bright 2: full
  5, // var
  0, // spd

  255
};

void setup() {
  size(WIDTH, HEIGHT);

  colorMode(HSB, 255, 255, 255);

  lithne = new Lithne(this, "/dev/tty.usbmodem1413", 115200);
  lithne.enableDebug();
  lithne.begin();

  nm.addNode("00 13 a2 00 40 79 ce 37", "Color Coves");
  nm.addNode("00 13 a2 00 40 79 ce 25", "CCT Ceiling Tiles");
  nm.addNode("00 13 a2 00 40 79 ce 24", "Solime");

  arduino = new Serial(this, "/dev/tty.usbmodem1421", 115200);
  lithneSerial = new Serial(this, "/dev/tty.usbmodem1411", 115200);

  // Initialise calibration values
  for (int i = 0; i < nPads; i++)
    pads[i] = new Pad();
  try {
    JSONObject json = loadJSONObject(CALIBRATION_FILE);
    JSONArray min = json.getJSONArray("min");
    JSONArray max = json.getJSONArray("max");
    for (int i = 0; i < nPads; i++) {
      pads[i].min = min.getInt(i);
      pads[i].max = max.getInt(i);
    }
    threshold = json.getFloat("threshold");
    state = State.RUNNING;
  }
  catch (NullPointerException e) {
    threshold = 0.3;
    state = State.CALIBRATE_NOT_TOUCHED;
  }

  resetCache();

  background(0);

  log("time", millis());
}

void draw() {
  update();

  if (read_values()) {
    switch (state) {
    case State.CALIBRATE_NOT_TOUCHED:
      set_minima();
      break;
    case State.CALIBRATE_TOUCHED:
      set_maxima();
    }
  }

  if (drawing) {
    draw_palette();
    draw_sensed();
    draw_activated();
    draw_message();
    draw_status();
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

void receive_from_lithne() {
  println("receiving from lithne");
  if (lithneSerial.available() > 0)
    log("from lithne", lithneSerial.readStringUntil(10));
}

void log(String key, String value) {
  print("LOG");
  print(millis());
  print(": ");
  print(key);
  print(": ");
  println(value);
}

void log(String key, int value) {
  log(key, Integer.toString(value));
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

void resetCache() {
  cached_sensed_points = null;
  cached_touch_points = null;
  cached_activated_points = null;
}

void update() {
  resetCache();
  message.update = false;

  updateSensed();
  updateTouched();
  updateActivated();

  if (message.on == 1) {
    if (!hasRun) {
      setUserLocation(250, 480);
      //setUserLocation(250, 480);
      sendParamArray();
      hasRun = true;
    }
  }

  if (state == State.RUNNING) {
    if (touching())
      on_touch();
    fade_out();

    // TODO set width etc.
    message.bri1 = round(255.0 / 100.0 * points);
    int ceiling = message.ceiling;
    message.ceiling = (points < 20) ? 1 : 0;
    if (ceiling != message.ceiling)
      message.update = true;

    // TODO comment out for actual running; this slows things down.
    //receive_from_lithne();

    if (message.update) {      
      parameterArray[1] = char(message.hue1);
      parameterArray[3] = char(message.sat1);
      parameterArray[5] = char(message.bri1);

      parameterArray[2] = char(message.hue2);
      parameterArray[4] = char(message.sat2);
      parameterArray[6] = char(message.bri2);

      parameterArray[36] = char(int(map(message.width, 0, 255, 110, 255)));

      parameterArray[0] = parameterArray[9] = char(message.alternate + 1);

      /* TODO
       Message msg  =  new Message();
       msg.setFunction("setCCTParameters");
       msg.setScope("Breakout404");
       msg.toXBeeAddress64( nm.getXBeeAddress64("CCT Ceiling Tiles") );
       for (int i = 0; i < 5; i++) {
       msg.addArgument(i);
       msg.addArgument(1);
       msg.addArgument((message.ceiling == 1) ? 255 : 10);
       msg.addArgument((message.ceiling == 1) ? 50 : 200);
       }
       lithne.send(msg);
       */
    }
  }

  if (state == State.RUNNING && message.on == 1 && message.update == true) {
    if (millis() - paramsLastSent > MESSAGE_INTERVAL) {
      sendParamArray();
      paramsLastSent = millis();
    }
  }
}

void updateSensed() {
  IntList sp = sensed_points();
  if (sp.size() > 0) {
    sense_time = millis();
    if (sense_amount == 0) {
      sense_start_time = millis();
    }
  }
  if (sp.size() >= sense_amount) {
    sense_amount = sp.size();
    sense_amount_time = millis();
  }
  else if (sense_amount > 0 && millis() - sense_amount_time > 300) {
    sense_amount -= 1;
  }
}

String charArrayToString(char[] arr) {
  StringBuffer result = new StringBuffer();
  for (int i = 0; i < arr.length; i++) {
    result.append( int(arr[i]) );
    result.append('\t');
  }
  return result.toString();
}

String arrayToString(int[] arr) {
  StringBuffer result = new StringBuffer();
  for (int i = 0; i < arr.length; i++) {
    result.append( arr[i] );
    result.append('\n');
  }
  return result.toString();
}
String intListToString(IntList arr) {
  StringBuffer result = new StringBuffer();
  for (int i = 0; i < arr.size(); i++) {
    result.append(arr.get(i));
    result.append('\n');
  }
  return result.toString();
}

boolean intListsEqual(IntList a, IntList b) {
  if (a.size() != b.size())
    return false;
  for (int i = 0; i < a.size(); i++)
    if (a.get(i) != b.get(i))
      return false;
  return true;
}

void updateActivated() {
  IntList ap = activated_points();
  if (ap.size() == 0 && previous_activated_points != null && previous_activated_points.size() > 0) {
    on_activated_end();
  }

  if (previous_activated_points == null || !intListsEqual(previous_activated_points, ap)) {
    // TODO log("activated", intListToString(ap));
  }

  if (touching() && millis() - touch_start_time > APPLY_TIMEOUT) {
    message.hue1 = message.phue;
    message.sat1 = message.psat;
    message.bri1 = message.pbri;
  }

  previous_activated_points = ap;
}

void updateTouched() {
  IntList tp = touch_points();
  if (tp.size() > 0) {
    // Currently certainly touching
    touch_time = millis();
    last_touch_position = tp.get(tp.size() - 1);
    if (touch_amount == 0)
      touch_start_time = millis();
  }
  if (tp.size() >= touch_amount) {
    // Increasing the touch amount
    touch_amount = tp.size();
    touch_amount_time = millis();
  }
  else if (touch_amount > 0 && millis() - touch_amount_time > TOUCH_TIMEOUT) {
    // Decreasing the touch amount
    touch_amount -= 1;
    if (touch_amount == 0) {
      if (millis() - touch_end_time > TOUCH_COOLDOWN) {
        touch_end_time = millis();
        last_touch_duration = millis() - touch_start_time;
        /* TODO
         int[][] newLast_touch_durations = new int[max(last_touch_durations + 1, TAP_AMOUNT)];
         int i;
         if
         last_touch_durations = last_touch_durations.unshift([@last_touch_duration, millis]).slice(0, TAP_AMOUNT)
         */
      }
    }
  }
  if (tp.size() > 1) {
    touch_distance = 0;
    for (int index = 0; index < tp.size(); index++) {
      int j = index + 1;
      while (j < tp.size ()) {
        float d = distance(tp.get(index), tp.get(j));
        if (d > touch_distance)
          touch_distance = d;
        j += 1;
      }
    }
  }
}

boolean touching() {
  return touch_amount > 0;
}

float distance(int a, int b) {
  int[] pa = {
    a % 4, a / 4
  };
  int[] pb = {
    b % 4, b / 4
  };
  return sqrt((pa[0] - pb[0])^2 + (pa[1] - pb[1])^2);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

void on_activated_end() {
  message.hue1 = message.phue;
  message.sat1 = message.psat;
  message.bri1 = message.pbri;

  message.phue = 0;
  message.psat = 0;
  message.pbri = 0;
  message.breathe = (points == 0) ? 0 : ((points == 100) ? 1 : 100 - points);
  message.sendToLithne();

  // TODO Is this ok?
  //@message[:alternate] = if @last_touch_durations.length == TAP_AMOUNT and millis - @last_touch_durations[-1][1] < TAP_TIMEOUT then 1 else 0 end

  int default_width = 30;
  float max_activated = 3.0;
  message.width = default_width + int(previous_activated_points.size() / max_activated * (255.0 - default_width));

  message.update = true;
}

void on_touch() {
  if (millis() - points_changed > ADD_POINT_INTERVAL && points < 100)
    add_points(1);
  float[] point = center;
  if (point != null && point != preview) {
    preview = point;
    color c = center_color();
    message.phue = round(hue(c));
    message.psat = round(saturation(c));
    message.pbri = round(brightness(c));
    println();
    println(message.phue);
    println(message.psat);
    println(message.pbri);
    message.breathe = 0;
    message.sendToLithne();
    message.update = true;
  }
}

void fade_out() {
  if (millis() - points_changed > FADE_INTERVAL && points > 0)
    add_points(-1);
}

void add_points(int pts) {
  points += pts;
  points_changed = millis();
  if (message.pbri == 0)
    message.breathe = (points == 0) ? 0 : ((points == 100) ? 1 : 100 - points);
  if (points == 0)
    message.breathe = 0;
  message.update = true;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

boolean read_values() {
  byte[] vals = null;
  while (arduino.available () > 0)
    vals = arduino.readBytesUntil(10);
  if (vals != null && !vals.equals("")) {
    int[] numbers = new int[16];
    String[] items = new String(vals).split("\t");
    if (receiving) {
      for (int i = 0; i < max(nPads, items.length - 1); i++)
        numbers[i] = int(items[i + 1]);
    }
    receiving = true;
    values = numbers;
    return true;
  }
  else {
    return false;
  }
}

void log_values() {
  println(arrayToString(values));
  /* TODO
   if (state == State.RUNNING) {
   puts @values.each_with_index.map { |v, i|
   if @min[i] and @max[i]
   map(v.to_f, @min[i], @max[i], 0, 1).round(2)
   else
   v
   end
   }.inspect
   } else {
   puts @values.inspect
   }
   */
}

void set_minima() {
  for (int i = 0; i < values.length; i++)
    if (pads[i].min == 0 || values[i] > pads[i].min)
      pads[i].min = values[i];
}

void set_maxima() {
  for (int i = 0; i < values.length; i++)
    if (pads[i].max == 0 || values[i] > pads[i].max)
      pads[i].max = values[i];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

void draw_palette() {
  noStroke();
  fill(0);
  rect(0, 0, SENSOR_DISPLAY[0] + SENSOR_DISPLAY[2], SENSOR_DISPLAY[1] + SENSOR_DISPLAY[3]);
  pushMatrix();
  translate(SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]);
  int width = 10;
  int size = SENSOR_DISPLAY[3] / 4;
  for (int i = 0; i < nPads; i++) {
    pushMatrix();
    translate(i / 4 * size, i % 4 * size);
    stroke(100);
    strokeWeight(width);
    rect(width / 2, width / 2, size - width, size - width);

    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    textFont(font);
    text(i, size / 2, size / 2);
    fill(0);

    popMatrix();
  }
  popMatrix();
}

void draw_sensed() {
  int size = SENSOR_DISPLAY[3] / 4;
  pushMatrix();
  translate(SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]);
  IntList sp = sensed_points();
  for (int i = 0; i < sp.size(); i++) {
    int p = sp.get(i);
    pushMatrix();
    translate(p / 4 * size, p % 4 * size);
    noStroke();
    fill(255);
    rect(0, 0, size, size);
    popMatrix();
  }
  popMatrix();
}

void draw_activated() {
  int size = SENSOR_DISPLAY[3] / 4;
  pushMatrix();
  translate(SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]);
  IntList ap = activated_points();
  for (int i = 0; i < ap.size(); i++) {
    int p = ap.get(i);
    ellipseMode(CENTER);
    stroke(255);
    strokeWeight(2);
    noFill();
    ellipse((p / 4 + 0.5) * size, (p % 4 + 0.5) * size, 20, 20);
  }
  if (center != null) {
    ellipseMode(CENTER);
    fill(center_color());
    stroke(0);
    strokeWeight(5);
    ellipse(center[0] * size, center[1] * size, 20, 20);
  }
  popMatrix();
}

String status() {
  StringBuilder s = new StringBuilder();
  s.append(state);
  s.append('\n');
  if (!receiving)
    s.append(" not");
  s.append("receiving values\nthreshold: ");
  s.append(threshold);
  s.append("\n<<<");
  s.append(points);
  s.append(" points>>>\n");
  s.append(touch_amount);
  s.append(" touches\nlast touch duration: ");
  s.append(last_touch_duration);
  s.append("\ndistance: ");
  s.append(touch_distance);
  s.append("\nmessages sent: ");
  s.append(sent);
  return s.toString();
}

void draw_status() {
  String st = status();
  if (cached_status == null || !st.equals(cached_status)) {
    int x = SENSOR_DISPLAY[0] + SENSOR_DISPLAY[2] + 30;
    int y = 10;
    int w = width - x;
    int h = SENSOR_DISPLAY[3];
    fill(0);
    noStroke();
    rect(x, SENSOR_DISPLAY[1], w, h);
    fill(255);
    textSize(12);
    textAlign(LEFT, TOP);
    textFont(font);
    text(st, x, y);
    cached_status = st;
  }
}

void draw_message() {
  pushMatrix();
  translate(MESSAGE_DISPLAY[0], MESSAGE_DISPLAY[1]);

  // background
  noStroke();
  fill(40);
  rect(0, 0, MESSAGE_DISPLAY[2], MESSAGE_DISPLAY[3]);

  int width = (MESSAGE_DISPLAY[2] - 20) / 18;

  noStroke();
  fill(message.hue1, message.sat1, message.bri1);
  rect(15 + width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20);
  fill(message.hue2, message.sat2, message.bri2);
  rect(15 + 3 * width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20);
  fill(message.phue, message.psat, message.pbri);
  rect(15 + 5 * width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20);

  textSize(12);
  textAlign(CENTER, CENTER);
  textFont(font);
  fill(255);
  text("on\n" + Integer.toString(message.on), 10 + 0.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("alternate\n" + Integer.toString(message.alternate), 10 + 9.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("animate\n" + Integer.toString(message.animate), 10 + 10.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("center\n" + Integer.toString(message.center), 10 + 11.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("vary\n" + Integer.toString(message.vary), 10 + 12.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("width\n" + Integer.toString(message.width), 10 + 13.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("breathe\n" + Integer.toString(message.breathe), 10 + 14.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("blink\n" + Integer.toString(message.blink), 10 + 15.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("ceiling\n" + Integer.toString(message.ceiling), 10 + 16.5 * width, MESSAGE_DISPLAY[3] / 2);
  popMatrix();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

IntList sensed_points() {
  if (cached_sensed_points != null)
    return cached_sensed_points;
  else {
    IntList points = new IntList();
    if (values.length != 0) {
      for (int i = 0; i < values.length; i++) {
        if (pads[i].min != 0 && pads[i].max != 0 && values[i] != 0) {
          float value = map(float(values[i]), pads[i].min, pads[i].max, 0.0, 1.0);
          if (value >= threshold) {
            points.append(i);
            pads[i].lastSense = millis();
          }
        }
      }
    }
    return cached_sensed_points = points;
  }
}

IntList touch_points() {
  if (cached_touch_points != null)
    return cached_touch_points;

  IntList tryPoints = new IntList();
  for (int i = 0; i < 16; i++)
    tryPoints.append(i);
  IntList sensed = sensed_points();
  int i = 0;
  IntList points = new IntList();
  while (i < tryPoints.size ()) {
    int point = tryPoints.get(i);
    if (sensed.hasValue(point)) {
      points.append(point);
      /* TODO
       EIGHBORS[point].each do |neighbor|
       try.delete neighbor if sensed.include? neighbor and neighbor > point
       end
       */
    }
    i++;
  }
  for (int j = 3; j < points.size(); j++)
    points.remove(j);
  return points;
}

IntList activated_points() {
  if (cached_activated_points != null)
    return cached_activated_points;

  IntList points = new IntList();
  IntList sensed = sensed_points();
  for (int i = 0; i < 16; i++)
    if (millis() - pads[i].lastSense < TOUCH_TIMEOUT)
      points.append(i);
  float f = 1.0 / points.size();
  center = new float[2];
  center[0] = center[1] = 0.0;
  for (int i = 0; i < points.size(); i++) {
    float[] pos = position(points.get(i));
    center[0] += f * pos[0];
    center[1] += f * pos[1];
  }
  previous_center = center;
  if (center[0] == 0.0 && center[1] == 0.0)
    center = null;
  return cached_activated_points = points;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

float[] position(int i) {
  float[] result = {
    (i / 4) + 0.5, (i % 4) + 0.5
  };
  return result;
}

color center_color() {
  println("x: " + (center[0] / 4.0) + ", y: " + (center[1] / 4.0));
  int[] hsb = xyToHSB(
    map(center[0], 0.5, 3.5, 0.0, 1.0),
    map(center[1], 0.5, 3.5, 0.0, 1.0)
   );
  return color(hsb[0], hsb[1], hsb[2]);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

void keyPressed() {
  switch (key) {
  case ' ':
    switch (state) {
    case State.CALIBRATE_NOT_TOUCHED:
      state = State.CALIBRATE_TOUCHED;
      for (int i = 0; i < nPads; i++)
        pads[i].max = pads[i].min + 1;
      break;
    case State.CALIBRATE_TOUCHED:
      state = State.RUNNING;
      JSONObject json = new JSONObject();
      JSONArray min = new JSONArray();
      JSONArray max = new JSONArray();
      for (int i = 0; i < nPads; i++) {
        min.setInt(i, pads[i].min);
        max.setInt(i, pads[i].max);
      }
      json.setJSONArray("min", min);
      json.setJSONArray("max", max);
      json.setFloat("threshold", threshold);
      saveJSONObject(json, CALIBRATION_FILE);
      break;
    case State.RUNNING:
      state = State.RUNNING;
      for (int i = 0; i < nPads; i++) {
        pads[i].min = pads[i].max = 0;
      }
      state = State.CALIBRATE_NOT_TOUCHED;
      break;
    }
    break;
  case 'o':
    message.on = 1 - message.on;
    break;
    /* TODO
     when 'm'
     puts 'min: ' + @min.inspect
     puts 'max: ' + @max.inspect
     */
  case 'r':
    points = 0;
    break;
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
  case '9':
    threshold = (int(key) - 48) / 10.0;
    break;
  case 'd':
    drawing = !drawing;
    cached_status = null;
    cached_mode = null;
    background(0);
    break;
  }
}

/////////////

int[] xyToHSB(float x, float y) // Range 0-1
{
  int[] hsb = {
    255, 255, 255
  };

  // First calc saturation based on the distance to the centre.
  float dx = abs(x - 0.5);
  float dy = abs(y - 0.5);
  float d = sqrt( pow(dx, 2)+pow(dy, 2)  );
  d = constrain(d, 0, 0.7); // d may go up to 0.7 or so, so we take the horizontal max dist as max.
  // If we wish to start desaturation not from the edge, but further inwards, this value may be reduced; for instance to 3 or 2
  float sat = map(d, 0, 0.5, 0, 255); // map distance to centre to the saturation
  hsb[1] = int(sat); // Saturation: 
  //println("Calculated d:" + d + ", and based Saturation on that: " + sat);
  // Now calculate the color
  // This is based on the angular position of the XY in relation to the centre

  PVector vect = new PVector(x-0.5, y-0.5);

  float heading = vect.heading();
  float ang = degrees(heading);
  if ( ang < 0 ) { 
    ang += 360;
  }
  float hue = map(ang, 0, 360, 0, 255);
  hsb[0] = int(hue);
  //println("Calculated a:" + ang + " based on heading: "+heading+", and based Hue on that: " + hue);

  // We keep max bright because this is calced later on
  return hsb;
}

/////////////////////////////////////////

void sendParamArray()
{
  setLightParameters( parameterArray );
}

void setLightParameters( char paramArray[] )
{
  Message msg  =  new Message();
  msg.toXBeeAddress64( nm.getXBeeAddress64("Color Coves") );
  msg.setFunction( "sizedParameters" );
  msg.setScope( "Breakout404" );  

  for (int i = 0; i < paramArray.length; i++)
  {
    msg.addByte(paramArray[i]);
  }

  //println("SENDING NEW MSG: " + msg.toString());
  lithne.send( msg );

  log("parameters", charArrayToString(paramArray));
}

void setUserLocation( int x, int y )
{
  Message msg  =  new Message();
  msg.toXBeeAddress64( nm.getXBeeAddress64("Color Coves") );
  msg.setFunction( "setUserLocation" );
  msg.setScope( "Breakout404" );  

  msg.addArgument(x);
  msg.addArgument(y);


  //println("SENDING NEW MSG: " + msg.toString());
  lithne.send( msg );
}

