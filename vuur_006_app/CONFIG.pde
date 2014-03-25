// Configuration

// Screen size and layout (x, y, width, height)
final int WIDTH = 800;//1440;
final int HEIGHT = 600;//900;
final int[] SENSOR_DISPLAY = {
  10, 10, 400, 400
  //10, 10, 580, 580
};
final int[] MESSAGE_DISPLAY = {
  //10, 600, 1420, 200
  10, 420, 780, 170
};

// Time intervals are in milliseconds

// How long to wait before marking a pad as untouched
final int TOUCH_COOLDOWN = 100;

// How long a pad needs to sense a high value before it is considered touched
final int TOUCH_TIMEOUT = 300;

// How long to wait before adding another point
final int ADD_POINT_INTERVAL = 200;

// How long to wait before removing a point
final int DEFAULT_FADE_INTERVAL = 2000;

// How many taps are needed before activating the 'alternate' mode
final int TAP_AMOUNT = 3;

// Time interval within which TAP_AMOUNT taps need to be done
final int TAP_TIMEOUT = 2000;

// During a long press, how long to wait before the action is applied
final int APPLY_TIMEOUT = 0;//TODO 3000;

final int MESSAGE_INTERVAL = 100;

// Where to store the sensor calibration
final String CALIBRATION_FILE = "calibration.dump";

final int CEILING_THRESHOLD = 20;

// How many milliseconds does it take to go from the top left to the top right?
final float MIN_VELOCITY = 0.001;
final float MAX_VELOCITY = 0.100;

final float PREVIEW_VELOCITY = 0.08;

final int LITHNE_MESSAGE_INTERVAL = 20;

final boolean USE_HUB = true;
