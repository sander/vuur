struct LampInfo {
  int updated;
};

struct ColorCove {
  LampInfo *info;
  int id;
  int hue;
  int saturation;
  int brightness;
  int variation;
  int speed;
};

struct Ceiling {
  LampInfo *info;
  boolean enabled;
  int intensity;
  int cct;
};

struct Solime {
  LampInfo *info;
  int hue;
  int saturation;
  int brightness;
};

const int nCoves = 16;
const int maxUpdateParametrics = 2;
const int maxUpdateCoveHSB = 4;
const unsigned long interval = 500;

ColorCove *coves[nCoves];
Ceiling *ceiling;
Solime *solime;

int currentUpdate;
unsigned long lastSend = 0;

void setup404() {
  Lithne.begin(115200, Serial1);
  Lithne.addNode(COORDINATOR, XBeeAddress64(0x00000000, 0x00000000));
  Lithne.addNode(BROADCAST  , XBeeAddress64(0x00000000, 0x0000FFFF));   
  Lithne.addNode(1, XBeeAddress64(0x0013A200, 0x4079CE37)); // color coves
  Lithne.addNode(2, XBeeAddress64(0x0013A200, 0x4079CE25)); // cct ceiling tiles
  Lithne.addNode(3, XBeeAddress64(0x0013A200, 0x4079CE26)); // blinds
  Lithne.addNode(9, XBeeAddress64(0x0013A200, 0x4079CE24)); // solime

  Lithne.addScope("Breakout404");

  for (int i = 0; i < nCoves; i++)
    coves[i] = (ColorCove *)createColorCove(i);
  ceiling = (Ceiling *)createCeiling();
  solime = (Solime *)createSolime();

  currentUpdate = 0;
}

void update404() {
  // this is needed to not overload the connection... at least if we do just 1 msg per loop, something seems to catch errors
  if (millis() - lastSend > interval) {
    lastSend = millis();

    if (update404CoveHSB()) return;
    if (update404CoveParametrics()) return;
    if (update404Ceiling()) return;
    if (update404Solime()) return;

    currentUpdate++;
  }
}

boolean update404Solime() {
  if (solime->info->updated != currentUpdate) {
    fun(9, "setAllHSB");
    arg(solime->hue);
    arg(solime->saturation);
    arg(solime->brightness);
    snd();
    solime->info->updated = currentUpdate;
    return true;
  } 
  else {
    return false;
  }
}

boolean update404CoveHSB() {
  ColorCove *updating[maxUpdateCoveHSB];
  int n = 0;
  for (int i = 0; i < nCoves && n < maxUpdateCoveHSB; i++) {
    ColorCove *cove = coves[i];
    if (cove->info->updated != currentUpdate && (cove->variation == 0 || cove->brightness == 0)) {
      updating[n++] = cove;
      cove->info->updated = currentUpdate;
    }
  }

  if (n) {
    fun(1, "setHSB");
    for (int i = 0; i < n; i++) {
      arg(updating[i]->id);
      arg(updating[i]->hue);
      arg(updating[i]->saturation);
      arg(updating[i]->brightness);
    }
    snd();
    return true;
  } 
  else {
    return false;
  }
}

boolean update404CoveParametrics() {
  ColorCove *updating[maxUpdateParametrics];
  int n = 0;
  for (int i = 0; i < nCoves && n < maxUpdateParametrics; i++) {
    ColorCove *cove = coves[i];
    if (cove->info->updated != currentUpdate && (cove->variation != 0 && cove->brightness != 0)) {
      updating[n++] = cove;
      cove->info->updated = currentUpdate;
    }
  }

  if (n) {
    fun(1, "setHSB");

    for (int i = 0; i < n; i++) {
      arg(updating[i]->id);
      arg(updating[i]->hue);
      arg(updating[i]->saturation);
      arg(updating[i]->brightness);
    }
    // TODO why did i comment this?
    /*
    fun(1, "parametrics");
     for (int i = 0; i < n; i++) {
     arg(updating[i]->id);
     arg(updating[i]->hue);
     arg(updating[i]->saturation);
     arg(updating[i]->brightness);
     arg(updating[i]->variation);
     arg(updating[i]->speed);
     }
     */
    snd();
    return true;
  } 
  else {
    return false;
  }
}

boolean update404Ceiling() {
  if (ceiling->info->updated != currentUpdate) {
    fun(2, "setCCTParameters");
    for (int i = 0; i < 5; i++) {
      arg(i);
      arg(ceiling->enabled ? 1 : 0);
      arg(ceiling->intensity);
      arg(ceiling->cct);
    }
    snd();
    ceiling->info->updated = currentUpdate;
    return true;
  } 
  else {
    return false;
  }
}

void ColorCove_set(void* coveRef, int hue, int saturation, int brightness, int variation, int speed) {
  ColorCove *cove = (ColorCove *)coveRef;
  cove->hue = hue;
  cove->saturation = saturation;
  cove->brightness = brightness;
  cove->variation = variation;
  cove->speed = speed;
}

void * createLampInfo() {
  LampInfo *info = new LampInfo();
  info->updated = 0;
  return info;
}

void * createColorCove(int id) {
  ColorCove *cove = new ColorCove();
  cove->info = (LampInfo *)createLampInfo();
  cove->id = id;
  cove->hue = 0;
  cove->saturation = 0;
  cove->brightness = 0;
  cove->variation = 0;
  cove->speed = 0;
  return cove;
}

void * createCeiling() {
  Ceiling *ceiling = new Ceiling();
  ceiling->info = (LampInfo *)createLampInfo();
  ceiling->enabled = false;
  ceiling->intensity = 0;
  ceiling->cct = 0;
  return ceiling;
}

void * createSolime() {
  Solime *solime = new Solime();
  solime->info = (LampInfo *)createLampInfo();
  solime->hue = 0;
  solime->saturation = 0;
  solime->brightness = 0;
  return solime;
}

