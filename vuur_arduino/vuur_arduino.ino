#define TRIANGLE_PINS {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
#define N_TRIANGLES 12

#define TouchStatus byte
#define IDLE 0
#define UNKNOWN 1
#define TOUCHED 2

#define touchstart 0
#define touchend 1
#define touchmove 2

#define PT_INTERVAL 100
#define TOUCH_RECORD_INTERVAL 1000
#define DOUBLE_TAP_INTERVAL 500

#define ADD_PT 1
#define ADD_BONUS_PT 2
#define TOUCH_RECORD 3
#define TOUCH_DURATION 4
#define STOP 5

const int triangle_pins[] = TRIANGLE_PINS;
unsigned long touch_start[N_TRIANGLES];
unsigned long touch_end[N_TRIANGLES];
unsigned long touch_lost[N_TRIANGLES];
unsigned long pt_added[N_TRIANGLES];
TouchStatus last_status[N_TRIANGLES];
int n_touched = 0;
int n_touched_record = 0;
unsigned long n_touched_record_time = 0;
int double_tap_id = -1;
int double_tap_state = 0;
unsigned long double_tap_time = 0;

void setup() {
  Serial.begin(9600);
}

void loop() {
  int new_n_touched = 0;
  for (int i = 0; i < N_TRIANGLES; i++) {
    int pin = triangle_pins[i];
    int value = readCapacitivePin(pin);
    TouchStatus status = value_to_touch_status(value);
    if (status == TOUCHED) {
      new_n_touched++;
    }
    if (status != last_status[i]) {
      set_touch_status(i, status);
      switch (status) {
        case TOUCHED:
          maybe_add_pt(i);
          
          // handle double tap
          if (double_tap_state == 0 || millis() - double_tap_time >= DOUBLE_TAP_INTERVAL || double_tap_id != i) {
            double_tap_id = i;
            double_tap_state = 1;
            double_tap_time = millis();
          } else if (double_tap_id == i && double_tap_state == 2 && millis() - double_tap_time < DOUBLE_TAP_INTERVAL) {
            double_tap_state = 3;
            double_tap_time = millis();
          }
          
          break;
        case IDLE:
          to_lithne(TOUCH_DURATION, (int)(touch_end[i] - touch_start[i]));
          
          // handle double tap
          if (double_tap_id == i) {
            if (millis() - double_tap_time < DOUBLE_TAP_INTERVAL) {
              if (double_tap_state == 1) {
                double_tap_state = 2;
                double_tap_time = millis();
              } else if (double_tap_state == 3) {
                to_lithne(STOP, double_tap_id);
                double_tap_state = 0;
                double_tap_time -= DOUBLE_TAP_INTERVAL;
              }
            }
          }
          
          break;
      }
    } else if (status == TOUCHED) {
      maybe_add_pt(i);
    }
  }
  n_touched = new_n_touched;
  if (n_touched > n_touched_record) {
    n_touched_record = n_touched;
    n_touched_record_time = millis();
    to_lithne(TOUCH_RECORD, n_touched_record);
  } else if (n_touched == n_touched_record) {
    n_touched_record_time = millis();
  } else if (n_touched_record > 0 && millis() - n_touched_record_time > TOUCH_RECORD_INTERVAL) {
    n_touched_record_time = millis();
    n_touched_record--;
    to_lithne(TOUCH_RECORD, n_touched_record);
  }
}

TouchStatus value_to_touch_status(int value) {
  if (value < 3) return IDLE;
  else /*if (value >= 2)*/ return TOUCHED;
}

void set_touch_status(int i, TouchStatus status) {
  if (status == IDLE) touch_end[i] = millis();
  else if (status == UNKNOWN) touch_lost[i] = millis();
  else if (status == TOUCHED) touch_start[i] = millis();
  last_status[i] = status;
}

void maybe_add_pt(int i) {
  if (millis() - pt_added[i] > PT_INTERVAL) {
    pt_added[i] = millis();
    if (n_touched < 3) {
      to_lithne(ADD_PT, i);
    } else {
      to_lithne(ADD_BONUS_PT, i);
    }
  }
}

void to_lithne(int command, int arg) {
  Serial.print(command);
  Serial.print('\t');
  Serial.print(arg);
  Serial.println();
}
