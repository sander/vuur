#define N_PADS 12
#define MAX_VARIATION 12

#define ENABLE_PREVIEW false
#define ENABLE_BONUS_POINTS false

#define FADE_INTERVAL 500
#define PT_INTERVAL 100

#define PREVIEW_DURATION 500

// Commands
#define ADD_PT 1
#define ADD_BONUS_PT 2
#define TOUCH_RECORD 3
#define TOUCH_DURATION 4
#define STOP 5

Vuur *vuur = new Vuur;

void VuSetup() {
  vuur->stopDuration = 1000;
  vuur->maxPoints = 100;
  
  vuur->doubleTapInterval = 500;
  vuur->doubleTapPad = 11;
  vuur->touchRecordInterval = 1000;
  
  int config[4 * 12] = { // TODO define type padConfig
    A6, 16, 43, 100,
    A3, 26, 83, 100,
    A2, 34, 71, 83,
    A9, 48, 57, 75,
    A0, 96, 44, 78,
    A1, 148, 64, 91,
    A4, 167, 87, 93,
    A12, 169, 91, 82,
    A10, 192, 94, 85,
    A8, 207, 95, 89,
    A5, 215, 95, 91,
    A6, 223, 96, 93
  };
  vuur->setPads(config);

  vuur->variation = 2;
  vuur->center = 6.5;

  vuur->lastPreviewed = -1;

  vuur->nTouched = 0;
  vuur->doubleTapState = 0;
  vuur->doubleTapTime = 0;
}

int lastPoints = 0;

int hue = 0;
int saturation = 0;
int brightness = 0;

void VuLoop() {  
  int hue, saturation, brightness;

  VuFade();

  vuur->update();
  
  Breakout404.ceiling->enabled = true;

  // Check intensity
  float fraction = vuur->fraction();

  Pad *pad = vuur->winning();
  if (pad) {
    hue = pad->hue;
    saturation = pad->saturation;
    brightness = pad->brightness;
  } 
  else {
    hue = 0;
    saturation = 0;
    brightness = 255;
  }

  // Set ceiling
  if (fraction < 0.1) {
    Breakout404.ceiling->intensity = 200; // no fade, is ugly
    Breakout404.ceiling->cct = 255;
  } 
  else {
    Breakout404.ceiling->intensity = 20;
    Breakout404.ceiling->cct = 128;
  }

  // Set coves based on fraction
  vuur->width = 8.0 * fraction;
  for (int i = 0; i < 16; i++) {
    float distanceFactor = 1.0 - vuur->distances[i] / vuur->width;
    Breakout404.coves[i]->hue = hue;
    Breakout404.coves[i]->saturation = saturation;
    Breakout404.coves[i]->brightness = (int)(fraction * (float)brightness * distanceFactor);
    if (Breakout404.coves[i]->brightness < 0) Breakout404.coves[i]->brightness = 0;
    if (fraction > 0.1) {
      Breakout404.coves[i]->variation = (int)(((float)vuur->variation / (float)MAX_VARIATION) * 127.0);
      Breakout404.coves[i]->speed = 200;
    } 
    else {
      Breakout404.coves[i]->variation = 0;
      Breakout404.coves[i]->speed = 0;
    }
  }

  // Preview
  if (ENABLE_PREVIEW && millis() - vuur->lastPreview < PREVIEW_DURATION) {
    //Serial.print("previewing ");
    //Serial.println(vuur->lastPreviewed);
    Pad *preview = vuur->pads[vuur->lastPreviewed];
    Breakout404.solime->hue = preview->hue;
    Breakout404.solime->saturation = preview->saturation;
    Breakout404.solime->brightness = preview->brightness;
  } 
  else {
    Breakout404.solime->hue = 0;
    Breakout404.solime->saturation = 0;
    Breakout404.solime->brightness = 0;
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

void VuAddPoints(Pad *pad) {
  if (millis() - pad->ptAdded > PT_INTERVAL) {
    pad->ptAdded = millis();
    pad->points += (vuur->nTouched < 3 || !ENABLE_BONUS_POINTS) ? 1 : 3;
    pad->points -= min(0, vuur->totalPoints() - vuur->maxPoints);

    /*
  if (millis() - vuur->lastPreview > PREVIEW_DURATION || vuur->lastPreviewed != arg) {
     vuur->lastPreviewed = arg;
     vuur->lastPreview = millis();
     }
     */
  }
}

void VuSetVariation(int arg) {
  vuur->variation = 5 - max(5, (int)((float)arg / 1000.0));
}

float VuFraction() {
  return vuur->fraction();
}



