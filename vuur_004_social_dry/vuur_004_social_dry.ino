#include <Breakout404.h>
#include <HardwareTouch.h>
#include <LED.h>
#include <Lithne.h>
#include <Vuur.h>

const unsigned int fadeInterval = 10000;
const unsigned int addPointInterval = 100;
const int previewChangeTime = 500;
const unsigned int alternateTime = 500;

const int maxVariation = 12;
const int doubleTapPad = 11;
const boolean enableBonusPoints = false;

Vuur *vuur;

/*
HSBColor *palette[Vuur::nPads] = {
 new HSBColor( 16, 0.43, 1.00), new HSBColor( 26, 0.83, 1.00),
 new HSBColor( 34, 0.71, 0.83), new HSBColor( 48, 0.57, 0.75),
 new HSBColor( 96, 0.44, 0.78), new HSBColor(148, 0.64, 0.91),
 new HSBColor(167, 0.87, 0.93), new HSBColor(169, 0.91, 0.82),
 new HSBColor(192, 0.94, 0.85), new HSBColor(207, 0.95, 0.89),
 new HSBColor(215, 0.95, 0.91), new HSBColor(223, 0.96, 0.93)
 };
 */
HSBColor *palette[Vuur::nPads] = {
  new HSBColor( 50, 1.00, 1.00), new HSBColor( 98, 0.93, 0.90),
  new HSBColor(145, 0.92, 0.97), new HSBColor( 24, 1.00, 1.00),
  new HSBColor( 73, 1.00, 1.00), new HSBColor(190, 0.93, 0.84),
  new HSBColor(217, 0.92, 0.77), new HSBColor(  0, 1.00, 1.00),
  new HSBColor(317, 1.00, 1.00), new HSBColor(275, 0.88, 0.92),
  new HSBColor(214, 0.93, 0.93), new HSBColor(302, 0.46, 1.00)
  };

HSBColor *primary = NULL;
HSBColor *secondary = NULL;
int previewing = 0;
boolean warningOn = true;

boolean alternated = true;
unsigned int alternatedTime = 0;

int lastColors[2] = {
  -1, -1};

void setup() {
  Serial.begin(9600);

  vuur = new Vuur;

  vuur->maxPoints = 100;
  vuur->variation = 0;
  vuur->setCenter(6.5);
  vuur->touchRecordInterval = 20000;
  vuur->pads[doubleTapPad]->listenToDoubleTap();

  Breakout404.ceiling->enabled = true;
  Breakout404.solime->brightness = 0;
}

void loop() {
  vuur->update();

  vuur->fraction = 0.5;

  vuur->width = 8.0 * vuur->fraction;
  
  HSBColor *color = new HSBColor(50, 1.00, 1.00);
  while (ColorCove *cove = Breakout404.nextColorCove()) {
    float distance = max(1.0 - vuur->distances[cove->id] / vuur->width, 0);

    cove->hue = color->hue;
    cove->saturation = color->saturation;
    cove->brightness = (int)(vuur->fraction * (float)color->brightness * distance);
    
    cove->hue2 = cove->hue;
    cove->saturation2 = cove->saturation;
    cove->brightness2 = 0;
    
    cove->time = random(300, 600);
    cove->time2 = random(100, 200);
    /*
    cove->brightness = 0;
    cove->brightness2 = 0;
    cove->time = 0;
    */
  }
  
  //Breakout404.ceiling->intensity = 0;

  Breakout404.update();
} 

