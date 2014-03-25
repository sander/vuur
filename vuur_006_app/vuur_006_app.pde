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

boolean onTheSpotCalibration = false;
boolean recalibrateMaximaOnTheSpot = true;

final int nPads = 16;
Pad[] pads = new Pad[nPads];
Surface surface = new Surface(pads); 

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
boolean on = true;

int size = 100;

// Message, the values of which are sent to Lithne on send_to_lithne
VuurMessage message = new VuurMessage();

// Points between 0 (no effect) and 100 (full effect)
byte points = 0;

// Draw on screen? Very inefficient, disable for long-term usage
boolean drawing = true;

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
IntList previous_activated_points = null;

Point center;
Point center2;
Point preview;
boolean alternateCenter;
Debouncer<Boolean> debouncedTouching = new Debouncer<Boolean>();

int[] values = new int[16];

boolean hasRun = false;

int fadeInterval;

void setup() {
  size(WIDTH, HEIGHT);

  colorMode(HSB, 255, 255, 255);

  initBreakout();

  if (USE_HUB) {
    arduino = new Serial(this, "/dev/tty.usbmodem1a12421", 115200);
    lithneSerial = new Serial(this, "/dev/tty.usbmodem1a12411", 115200);
  } 
  else {
    arduino = new Serial(this, "/dev/tty.usbmodem1421", 115200);
    lithneSerial = new Serial(this, "/dev/tty.usbmodem1411", 115200);
  }

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

  center2 = new Point();
  center2.indicatorColor = 100;

  preview = new Point();
  preview.indicatorColor = 0;
  preview.velocity = PREVIEW_VELOCITY;

  initLog();
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
      break;
    case State.RUNNING:
      if (recalibrateMaximaOnTheSpot)
        set_maxima();
      break;
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

void resetCache() {
  cached_sensed_points = null;
  cached_touch_points = null;
  surface.resetCache();
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
    //setUserLocation(250, 480);
    //setUserLocation(250, 100);
    setUserLocation(270, 100);
    sendParamArray();
    hasRun = true;
    setCeiling(false);
  }

  if (state == State.RUNNING) {
    if (touching())
      on_touch();
    fade_out();

    if (debouncedTouching.update(touching()) && !debouncedTouching.get()) {
      alternateCenter = !alternateCenter;
      setFeedbackColor();
    }

    int brightness = round(float(message.bri1) / 100.0 * points);
    size = int(map(points, 0, 100, 0, 255));

    if (points < CEILING_THRESHOLD && previousPoints >= CEILING_THRESHOLD) {
      setCeiling(false);
    } 
    else if (points >= CEILING_THRESHOLD && previousPoints < CEILING_THRESHOLD) {
      setCeiling(true);
    }

    if (message.update) {
      color color1 = center.getColor();
      color color2 = center2.getColor();

      parameterArray[1] = parameterArray[10] = char(round(hue(color1)));
      parameterArray[3] = parameterArray[12] = char(round(saturation(color1)));
      parameterArray[5] = char(brightness);
      parameterArray[14] = char(brightness / 2);

      parameterArray[2] = parameterArray[11] = char(round(hue(color2)));
      parameterArray[4] = parameterArray[13] = char(round(saturation(color2)));
      parameterArray[6] = char(brightness);
      parameterArray[15] = char(brightness / 2);

      parameterArray[36] = char(int(map(size, 0, 255, 80, 255)));

      parameterArray[0] = parameterArray[9] = 2;
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
  IntList ap = surface.activated();

  if (ap.size() > 0) {
    preview.moveTo(ap);
    center.velocity = center2.velocity = map(surface.numberOfActivatedPadsDuringInteraction(), 0, surface.pads.length, MIN_VELOCITY, MAX_VELOCITY);
    ((Point)(alternateCenter ? center : center2)).moveTo(ap);
  }

  if (ap.size() == 0 && previous_activated_points != null && previous_activated_points.size() > 0) {
    on_activated_end();
  }

  if (previous_activated_points == null || !intListsEqual(previous_activated_points, ap)) {
    log("activated", intListToString(ap));
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
  message.phue = 0;
  message.psat = 0;
  message.pbri = 0;
  if (points > 20)
    message.breathe = (points == 0) ? 0 : ((points == 100) ? 1 : 100 - points);
  else
    message.breathe = 0;
  message.sendToLithne();
  
  preview.setTo(nextCenter());

  // TODO Is this ok?
  //@message[:alternate] = if @last_touch_durations.length == TAP_AMOUNT and millis - @last_touch_durations[-1][1] < TAP_TIMEOUT then 1 else 0 end

  //int default_width = 30;
  //float max_activated = 3.0;
  //size = default_width + int(previous_activated_points.size() / max_activated * (255.0 - default_width));
  //size = int(255.0 * (float(points) / 255.0));

  for (int i = 0; i < nPads; i++)
    pads[i].activatedDuringInteraction = false; 

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
    message.update = true;
    center.updated = false;
  }
  if (center2.updated) {
    message.update = true;
    center2.updated = false;
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
    // Format: millis\t and then 16 values separated by \t and then \n
    int[] numbers = new int[16];
    String[] items = new String(vals).trim().split("\t");
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

void setFeedbackColor() {
  color c = currentCenter().getColor();
  message.hue1 = round(hue(c));
  message.sat1 = round(saturation(c));
  message.bri1 = round(brightness(c));
  message.sendToLithne();
}

Point currentCenter() {
  return (alternateCenter ? center : center2);
}

Point nextCenter() {
  return (!alternateCenter ? center : center2);
}
