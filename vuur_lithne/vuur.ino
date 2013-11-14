#include <LED.h>

#define N_PADS 12
#define MAX_POINTS 100
#define MAX_VARIATION 12
#define ENABLE_PREVIEW 1
#define DOUBLE_TAP_PAD 11

#define FADE_INTERVAL 500
#define PT_INTERVAL 100
#define TOUCH_RECORD_INTERVAL 1000
#define DOUBLE_TAP_INTERVAL 500

#define STOP_DURATION 1000
#define PREVIEW_DURATION 500

// Commands
#define ADD_PT 1
#define ADD_BONUS_PT 2
#define TOUCH_RECORD 3
#define TOUCH_DURATION 4
#define STOP 5

struct Pad {
  TouchPin pin;
  int points;
  int hue;
  int saturation;
  int brightness;
  unsigned long lastUpdate;
  boolean touched;
  unsigned long touchStart;
};

struct Vuur {
  Pad *pads[N_PADS];
  float fraction;
  int variation;
  int touchRecord;
  float center;
  float width;
  unsigned long stopped;
  int lastPreviewed;
  unsigned long lastPreview;
  
  unsigned long ptAdded[N_PADS];
  unsigned long nTouchedRecordTime;
  unsigned long doubleTapTime;
  
  int nTouched;
  int nTouchedRecord;
  int doubleTapState;
};

Vuur *vuur;
float distances[16];

void VuSetup() {
  vuur = new Vuur();
  
  vuur->pads[0] = (Pad *)VuCreatePad(A7, 16, 83, 100);
  vuur->pads[1] = (Pad *)VuCreatePad(A3, 26, 83, 100);
  vuur->pads[2] = (Pad *)VuCreatePad(A2, 34, 71, 83);
  vuur->pads[3] = (Pad *)VuCreatePad(A9, 48, 57, 75);
  vuur->pads[4] = (Pad *)VuCreatePad(A0, 96, 44, 78);
  vuur->pads[5] = (Pad *)VuCreatePad(A1, 148, 64, 91);
  vuur->pads[6] = (Pad *)VuCreatePad(A4, 167, 87, 93);
  vuur->pads[7] = (Pad *)VuCreatePad(A12, 179, 91, 82);
  vuur->pads[8] = (Pad *)VuCreatePad(A14, 192, 94, 85);
  vuur->pads[9] = (Pad *)VuCreatePad(A8, 207, 95, 89);
  vuur->pads[10] = (Pad *)VuCreatePad(A5, 215, 95, 91);
  vuur->pads[11] = (Pad *)VuCreatePad(A6, 223, 96, 93);
  
  vuur->variation = 2;
  vuur->center = 6.5;
  
  vuur->lastPreviewed = -1;
  
  vuur->nTouched = 0;
  vuur->nTouchedRecord = 0;
  vuur->nTouchedRecordTime = 0;
  vuur->doubleTapState = 0;
  vuur->doubleTapTime = 0;
  
  for (int i = 0; i < 16; i++) {
    distances[i] = abs(((i < 8) ? vuur->center : 8 - vuur->center) - (float)(i % 8));
  }
}

int lastPoints = 0;

void VuLoop() {
  int hue, saturation, brightness;
  
  VuFade();
  
  VuHandleTouch();
  
  // Check intensity
  float fraction = (float)VuTotalPoints() / (float)MAX_POINTS;
  if (fraction < 0) fraction = 0.0;
  if (fraction > 1) fraction = 1.0;
  
  if (vuur->fraction != fraction) {
    vuur->fraction = fraction;
    
    Serial.println(fraction);
  }
    
  void *winning = VuWinningPad();
  if (winning) {
    Pad *pad = (Pad *)winning;
    hue = pad->hue;
    saturation = pad->saturation;
    brightness = pad->brightness;
  } else {
    hue = 0;
    saturation = 0;
    brightness = 255;
  }
  
  // Set ceiling
  if (fraction < 0.1) {
    ceiling->enabled = true;
    ceiling->intensity = 200; // no fade, is ugly
    ceiling->cct = 255;
  } else {
    ceiling->enabled = true;
    ceiling->intensity = 50;
    ceiling->cct = 128;
  }

  // Set coves based on fraction
  vuur->width = 8.0 * fraction;
  for (int i = 0; i < 16; i++) {
    float distanceFactor = 1.0 - distances[i] / vuur->width;
    coves[i]->hue = (int)(fraction * 255);//hue;
    coves[i]->saturation = saturation;
    coves[i]->brightness = (int)(fraction * (float)brightness * distanceFactor);
    if (coves[i]->brightness < 0) coves[i]->brightness = 0;
    if (fraction > 0.1) {
      coves[i]->variation = (int)(((float)vuur->variation / (float)MAX_VARIATION) * 127.0);
      coves[i]->speed = 200;
    } else {
      coves[i]->variation = 0;
      coves[i]->speed = 0;
    }
  }
  
  // Preview
  if (ENABLE_PREVIEW && millis() - vuur->lastPreview < PREVIEW_DURATION) {
    //Serial.print("previewing ");
    //Serial.println(vuur->lastPreviewed);
    Pad *preview = vuur->pads[vuur->lastPreviewed];
    solime->hue = preview->hue;
    solime->saturation = preview->saturation;
    solime->brightness = preview->brightness;
  } else {
    solime->hue = 0;
    solime->saturation = 0;
    solime->brightness = 0;
  }
}

void VuHandleTouch() {
  int newNTouched = 0;
  for (int i = 0; i < N_PADS; i++) {
    Pad *pad = vuur->pads[i];
    boolean touched = pad->pin.touched();
    boolean newValue = touched != pad->touched;
    pad->touched = touched;
    if (touched) {
        newNTouched++;
        
        if (millis() - vuur->ptAdded[i] > PT_INTERVAL) {
          vuur->ptAdded[i] = millis();
          if (vuur->nTouched < 3) {
            VuAddPoints(i);
          } else {
            VuAddBonusPoints(i);
          }
        }
        
        if (newValue) {
          pad->touchStart = millis();
          if (i == DOUBLE_TAP_PAD) {
            if (vuur->doubleTapState == 0 || millis() - vuur->doubleTapTime >= DOUBLE_TAP_INTERVAL) {
              vuur->doubleTapState = 1;
              vuur->doubleTapTime = millis();
            } else if (vuur->doubleTapState == 2 && millis() - vuur->doubleTapTime < DOUBLE_TAP_INTERVAL) {
              vuur->doubleTapState = 3;
              vuur->doubleTapTime = millis();
            }
          }
        }
    } else if (newValue) {
      VuSetVariation(millis() - pad->touchStart);
      
      if (i == DOUBLE_TAP_PAD && millis() - vuur->doubleTapTime < DOUBLE_TAP_INTERVAL) {
        if (vuur->doubleTapState == 1) {
          vuur->doubleTapState = 2;
          vuur->doubleTapTime = millis();
        } else if (vuur->doubleTapState == 3) {
          VuStop();
          vuur->doubleTapState = 0;
          vuur->doubleTapTime -= DOUBLE_TAP_INTERVAL;
        }
      }
    }
  }
  vuur->nTouched = newNTouched;
  if (newNTouched > vuur->nTouchedRecord) {
    vuur->nTouchedRecord = newNTouched;
    vuur->nTouchedRecordTime = millis();
    VuSetTouchRecord(vuur->nTouchedRecord);
  } else if (newNTouched == vuur->nTouchedRecord) {
    vuur->nTouchedRecordTime = millis();
  } else if (vuur->nTouchedRecord > 0 && millis() - vuur->nTouchedRecordTime > TOUCH_RECORD_INTERVAL) {
    vuur->nTouchedRecordTime = millis();
    vuur->nTouchedRecord--;
    VuSetTouchRecord(vuur->nTouchedRecord);
  }
}

void VuFade() {
  for (int i = 0; i < N_PADS; i++) {
    Pad *pad = vuur->pads[i];
    if (millis() - pad->lastUpdate > FADE_INTERVAL) {
      if (pad->points > 0) {
        pad->points -= 1;
        pad->lastUpdate = millis();
      }
    }
  }
}

int VuTotalPoints() {
  int pts = 0;
  for (int i = 0; i < N_PADS; i++) {
    pts += vuur->pads[i]->points;
  }
  return pts;
}

void * VuWinningPad() {
  Pad *winning;
  int highest = 0;
  for (int i = 0; i < N_PADS; i++) {
    int points = vuur->pads[i]->points;
    if (points > highest) {
      winning = vuur->pads[i];
      highest = points;
    }
  }
  return winning;
}

void * VuCreatePad(int pin, int hueDeg, int saturationPerc, int brightnessPerc) {
  Pad *pad = new Pad();
  pad->points = 0;
  pad->pin = TouchPin(pin);
  pad->hue = (int)( (float)hueDeg / 360.0 * 255.0 );
  pad->saturation = (int)( (float)saturationPerc / 100.0 * 255.0 );
  pad->brightness = (int)( (float)brightnessPerc / 100.0 * 255.0 );
  pad->lastUpdate = millis();
  pad->touched = false;
  return pad;
}

void VuAddPoints(int arg) {
  vuur->pads[arg]->points++;
  
  if (millis() - vuur->lastPreview > PREVIEW_DURATION || vuur->lastPreviewed != arg) {
    vuur->lastPreviewed = arg;
    vuur->lastPreview = millis();
  }
}

void VuAddBonusPoints(int arg) {
  vuur->pads[arg]->points += 3;
  
  if (millis() - vuur->lastPreview > PREVIEW_DURATION || vuur->lastPreviewed != arg) {
    vuur->lastPreviewed = arg;
    vuur->lastPreview = millis();
  }
}

void VuSetTouchRecord(int arg) {
  vuur->touchRecord = arg;
}

void VuSetVariation(int arg) {
  vuur->variation = 5 - max(5, (int)((float)arg / 1000.0));
}

float VuFraction() {
  return vuur->fraction;
}

void VuStop() {
  vuur->fraction = 0.0;
  vuur->variation = 0;
  vuur->touchRecord = 0;
  for (int i = 0; i < N_PADS; i++) {
    vuur->pads[i]->points = 0;
  }
  vuur->stopped = millis();
}

boolean VuIsStopped() {
  return (millis() - vuur->stopped < STOP_DURATION);
}
