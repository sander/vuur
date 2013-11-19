#include <Breakout404.h>
#include <HardwareTouch.h>
#include <LED.h>
#include <Lithne.h>
#include <Vuur.h>

const unsigned int fadeInterval = 500;
const unsigned int addPointInterval = 100;
const int previewChangeTime = 100;

const int maxVariation = 12;
const int doubleTapPad = 11;
const boolean enableBonusPoints = true;

Vuur *vuur;

HSBColor *palette[Vuur::nPads] = {
  new HSBColor( 16, 0.43, 1.00), new HSBColor( 26, 0.83, 1.00),
  new HSBColor( 34, 0.71, 0.83), new HSBColor( 48, 0.57, 0.75),
  new HSBColor( 96, 0.44, 0.78), new HSBColor(148, 0.64, 0.91),
  new HSBColor(167, 0.87, 0.93), new HSBColor(169, 0.91, 0.82),
  new HSBColor(192, 0.94, 0.85), new HSBColor(207, 0.95, 0.89),
  new HSBColor(215, 0.95, 0.91), new HSBColor(223, 0.96, 0.93)
};

void setup() {
  Serial.begin(9600);
  
  vuur = new Vuur;

  vuur->maxPoints = 100;
  vuur->variation = 0;
  vuur->setCenter(6.5);
  vuur->pads[doubleTapPad]->listenToDoubleTap();
  
  Breakout404.ceiling->enabled = true;
  Breakout404.solime->brightness = 0;
}

void loop() {
  vuur->update();
  
  vuur->setRGB(palette[vuur->lastTouched->id], previewChangeTime);

  while (Pad *pad = vuur->nextPad()) {
    if (pad->touched && timeSince(pad->ptAdded) > addPointInterval)
      pad->addPoints((vuur->nTouched < 3 || !enableBonusPoints) ? 1 : 3);
    else if (pad->points > 0 && timeSince(pad->lastUpdate) > fadeInterval)
      pad->addPoints(-1);
      
    if (pad->untouched)
      vuur->variation = max(5, (int)((float)pad->touchDuration / 1000.0));
  }
  
  if (vuur->fraction < 0.1) {
    Breakout404.ceiling->intensity = 200;
    Breakout404.ceiling->cct = 255;
  } else {
    Breakout404.ceiling->intensity = 20;
    Breakout404.ceiling->cct = 128;
  }
  
  HSBColor *color = vuur->winning ? palette[vuur->winning->id] : new HSBColor(0, 0.0, 1.0);
  
  vuur->width = 8.0 * vuur->fraction;
  while (ColorCove *cove = Breakout404.nextColorCove()) {
    float distance = max(1.0 - vuur->distances[cove->id] / vuur->width, 0);
    cove->hue = color->hue;
    cove->saturation = color->saturation;
    cove->brightness = (int)(vuur->fraction * (float)color->brightness * distance);
    if (vuur->fraction > 0.1) {
      cove->variation = (int)( ((float)vuur->variation / (float)maxVariation) * 127.0 );
      cove->speed = 200;
    } else {
      cove->variation = 0;
      cove->speed = 0;
    }
  }
  
  if (vuur->pads[doubleTapPad]->doubleTapped()) vuur->reset();
  
  //Breakout404.update();
}

