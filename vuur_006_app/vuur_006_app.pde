import processing.serial.*;
import ili.lithne.*;

long paramsLastSent = 0;
long lithneLastSent = 0;

Lithne lithne;
final NodeManager nm = new NodeManager();

Serial arduino;
Serial lithneSerial;

int max;
float threshold;

int lastCenterMove;

class Pad {
  int min;
  int max;
  long lastSense;
  long senseStart;
  long senseStop;
  boolean activated;

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

// Send signals to Breakout 404?
boolean on = false;

int size = 100;

// Message, the values of which are sent to Lithne on send_to_lithne
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
VuurMessage message = new VuurMessage();

// Points between 0 (no effect) and 100 (full effect)
byte points = 0;

// Draw on screen? Very inefficient, disable for long-term usage
boolean drawing = true;

// Which point coordinates is the preview based on
/*
float[] preview = {
 -1.0, -1.0
 };
 */

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

Point center;
Point preview;

int[] values = new int[16];

boolean hasRun = false;

int fadeInterval;

String timeString;
PrintWriter writer;
PrintWriter table;

void setup() {
  size(WIDTH, HEIGHT);

  colorMode(HSB, 255, 255, 255);

  initBreakout();

  arduino = new Serial(this, "/dev/tty.usbmodem1421", 115200);
  lithneSerial = new Serial(this, "/dev/tty.usbmodem1411", 115200);
  
  fadeInterval = DEFAULT_FADE_INTERVAL;

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

  center = new Point();
  center.indicatorColor = 255;
  center.velocity = VELOCITY;
  
  preview = new Point();
  preview.indicatorColor = 0;
  preview.velocity = PREVIEW_VELOCITY;

  timeString = "" + (System.currentTimeMillis() / 1000);

  table = createWriter("../data/table-" + timeString + ".csv");

  addColumn("Log key");
  addColumn("Timestamp");
  addColumn("Sending to Breakout");
  addColumn("Some pads activated");
  for (int i = 0; i < 16; i++) {
    addColumn("Pad " + i + " activated");
  }
  addColumn("Color hue");
  addColumn("Color saturation");
  addColumn("Color brightness");
  addColumn("Preview hue");
  addColumn("Preview saturation");
  addColumn("Preview brightness");
  addColumn("Breathe");
  addColumn("Points");
  addColumn("Width");
  addColumn("Effect brightness");
  addColumn("Ceiling");
  addColumn("Loudness");
  addColumn("Motion");
  addColumn("Fade interval");
  for (int i = 0; i < 37; i++) {
    addColumn("sizedParameter " + i);
  }
  table.println();

  writer = createWriter("../data/log-" + timeString + ".txt");
  log("time", timeString);
}

void addColumn(String name, boolean comma) {
  table.print('"' + name + '"' + (comma ? "," : ""));
}
void addColumn(String name) {
  addColumn(name, true);
}

void draw() {
  update();

  if (millis() - lastRegistered > REGISTER_INTERVAL) {
    Message msg = new Message();
    msg.setFunction("registerSensorListener");
    msg.setScope("Breakout404");
    msg.toXBeeAddress64(Lithne.BROADCAST); // TODO ?
    lithne.send(msg);
    lastRegistered = millis();
    log("register", "");
  }

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

void log(String key, String value) {
  String line = System.currentTimeMillis() + ": " + key + ": " + value;
  writer.println(line);
  println(line);

  table.print("\"" + key + "\",");
  long[] row = new long[3 + 16 + 6 + 8 + 37];
  int n = 0;
  row[n++] = System.currentTimeMillis();
  row[n++] = int(on);
  row[n++] = int(activated_points().size() > 0);
  for (int i = 0; i < nPads; i++)
    row[n++] = int(pads[i].activated);
  row[n++] = message.hue1;
  row[n++] = message.sat1;
  row[n++] = message.bri1;
  row[n++] = message.phue;
  row[n++] = message.psat;
  row[n++] = message.pbri;
  row[n++] = message.breathe;
  row[n++] = points;
  row[n++] = size;
  row[n++] = round(float(message.bri1) / 100.0 * points);
  row[n++] = int(points < CEILING_THRESHOLD);
  row[n++] = loudness;
  row[n++] = motion;
  row[n++] = fadeInterval;
  for (int i = 0; i < 37; i++) {
    row[n++] = parameterArray[i];
  }
  addRows(row);
  table.println();
}

void addRows(long[] values) {
  for (int i = 0; i < values.length; i++) {
    table.print(values[i] + ",");
  }
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

boolean reset = false;

void update() {
  int previousPoints = points;

  resetCache();

  updateSensed();
  updateTouched();
  updateActivated();

  if (reset) {
    add_points(-points);
    reset = false;
  }

  if (on && !hasRun) {
    setUserLocation(250, 480);
    sendParamArray();
    hasRun = true;
    setCeiling(false);
  }

  if (state == State.RUNNING) {
    if (touching())
      on_touch();
    fade_out();

    int brightness = round(float(message.bri1) / 100.0 * points);
    size = int(map(points, 0, 100, 0, 255));

    if (points < CEILING_THRESHOLD && previousPoints >= CEILING_THRESHOLD) {
      setCeiling(false);
    } 
    else if (points >= CEILING_THRESHOLD && previousPoints < CEILING_THRESHOLD) {
      setCeiling(true);
    }

    if (message.update) {
      parameterArray[1] = char(message.hue1);
      parameterArray[3] = char(message.sat1);
      parameterArray[5] = char(brightness);

      parameterArray[10] = parameterArray[1];
      parameterArray[12] = parameterArray[3];
      parameterArray[14] = parameterArray[5];

      parameterArray[2] = char(0);
      parameterArray[4] = char(0);
      parameterArray[6] = char(0);

      parameterArray[36] = char(int(map(size, 0, 255, 100, 255)));

      parameterArray[0] = parameterArray[9] = 1;
    }
  }

  if (state == State.RUNNING && on && message.update == true) {
    if (millis() - paramsLastSent > MESSAGE_INTERVAL) {
      sendParamArray();
      message.update = false;
      paramsLastSent = millis();
    }
  }
  
  if (message.isSent == false && millis() - lithneLastSent > LITHNE_MESSAGE_INTERVAL) {
    message.actuallySendToLithne();
    lithneLastSent = millis();
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

void updateActivated() {
  IntList ap = activated_points();
  if (ap.size() == 0 && previous_activated_points != null && previous_activated_points.size() > 0) {
    on_activated_end();
  }

  if (previous_activated_points == null || !intListsEqual(previous_activated_points, ap)) {
    log("activated", intListToString(ap));
  }

  if (touching() && millis() - touch_start_time > APPLY_TIMEOUT && message.pbri > 0) {
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
  if (message.pbri > 0) {
    message.hue1 = message.phue;
    message.sat1 = message.psat;
    message.bri1 = message.pbri;
  }

  message.phue = 0;
  message.psat = 0;
  message.pbri = 0;
  if (points > 20)
    message.breathe = (points == 0) ? 0 : ((points == 100) ? 1 : 100 - points);
  else
    message.breathe = 0;
  message.sendToLithne();

  // TODO Is this ok?
  //@message[:alternate] = if @last_touch_durations.length == TAP_AMOUNT and millis - @last_touch_durations[-1][1] < TAP_TIMEOUT then 1 else 0 end

  //int default_width = 30;
  //float max_activated = 3.0;
  //size = default_width + int(previous_activated_points.size() / max_activated * (255.0 - default_width));
  //size = int(255.0 * (float(points) / 255.0)); 

  message.update = true;
}

void on_touch() {
  if (millis() - points_changed > ADD_POINT_INTERVAL && points < 100)
    add_points(1);
  if (preview.updated) {
    color c = preview.getColor();
    message.phue = round(hue(c));
    message.psat = round(saturation(c));
    message.pbri = round(brightness(c));
    message.breathe = 0;
    message.sendToLithne();
    preview.updated = false;
  }
  if (center.updated) {
    color c2 = center.getColor();
    message.hue1 = round(hue(c2));
    message.sat1 = round(saturation(c2));
    message.bri1 = round(brightness(c2));
    message.update = true;
    center.updated = false;
  }
}

void fade_out() {
  if (millis() - points_changed > fadeInterval && points > 0) {
    add_points(-1);
    message.sendToLithne();
  }
}

void add_points(int pts) {
  points += pts;
  points_changed = millis();
  if (message.pbri == 0) {
    if (points > CEILING_THRESHOLD)
      message.breathe = (points == 0) ? 0 : ((points == 100) ? 1 : 100 - points);
    else
      message.breathe = 0;
  }
  if (points == 0)
    message.breathe = 0;
  message.sendToLithne();
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
    fill(150);
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
  preview.draw(size);
  center.draw(size);
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

  int width = (MESSAGE_DISPLAY[2] - 20) / 15;

  noStroke();
  fill(message.hue1, message.sat1, message.bri1);
  rect(15 + width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20);
  fill(message.phue, message.psat, message.pbri);
  rect(15 + 3 * width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20);

  textSize(12);
  textAlign(CENTER, CENTER);
  textFont(font);
  fill(255);
  text("on\n" + Boolean.toString(on), 10 + 0.5 * width, MESSAGE_DISPLAY[3] / 2);
  /*
  text("center\n" + Integer.toString(message.center), 10 + 9.5 * width, MESSAGE_DISPLAY[3] / 2);
   text("vary\n" + Integer.toString(message.vary), 10 + 10.5 * width, MESSAGE_DISPLAY[3] / 2);
   */
  text("size\n" + Integer.toString(size), 10 + 11.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("breathe\n" + Integer.toString(message.breathe), 10 + 12.5 * width, MESSAGE_DISPLAY[3] / 2);
  //text("blink\n" + Integer.toString(message.blink), 10 + 13.5 * width, MESSAGE_DISPLAY[3] / 2);
  //text("ceiling\n" + Integer.toString(message.ceiling), 10 + 14.5 * width, MESSAGE_DISPLAY[3] / 2);
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
            if (pads[i].senseStart == 0)
              pads[i].senseStart = millis();
            //pads[i].senseStop = millis();
          } 
          else {
            if (pads[i].senseStart != 0) {
              pads[i].senseStart = 0;
              pads[i].senseStop = millis();
            }
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
    if ((pads[i].activated && millis() - pads[i].lastSense < TOUCH_TIMEOUT) || // actief en te kort geleden voor timeout, hou actief
    (pads[i].senseStart != 0 && millis() - pads[i].senseStart > TOUCH_TIMEOUT)) { // voldoende lang geleden begonnen met sensen
      points.append(i);
      pads[i].activated = true;
    } 
    else {
      pads[i].activated = false;
    }

  if (points.size() > 0) {
    preview.moveTo(points);
    center.moveTo(points);
  }
  return cached_activated_points = points;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

float[] position(int i) {
  float[] result = {
    (i / 4) + 0.5, (i % 4) + 0.5
  };
  return result;
}

