/*
 CapacitiveSense.h v.04 - Capacitive Sensing Library for 'duino / Wiring
 Copyright (c) 2009 Paul Bagder  All right reserved.
 Version 04 by Paul Stoffregen - Arduino 1.0 compatibility, issue 146 fix
 vim: set ts=4:
 */

#include "Arduino.h"

#include "DoubleHardwareTouch.h"

uint8_t getBitFromBitField( uint8_t input ) // Function taken from WInterrupt.c; required for XMega
{
  switch(input)
  {
  case 0x1:
  	return 0;
  case 0x2:
  	return 1;
  case 0x4:
    return 2;
  case 0x8:
	 return 3;
  case 0x10:
	 return 4;
  case 0x20:
    return 5;
  case 0x40:
    return 6;
  case 0x80:
    return 7;
  default:
    return 0;
  }
}

// Constructor /////////////////////////////////////////////////////////////////
// Function that handles the creation and setup of instances

CapacitiveSensor::CapacitiveSensor(uint16_t sendPin, uint16_t receivePin)
{
	uint16_t sPort, rPort;

	// initialize this instance's variables
	 Serial.begin(9600);		// for debugging
	error = 1;
	loopTimingFactor = 310;		// determined empirically -  a hack
  // TODO(sander) check this
	
	CS_Timeout_Millis = (2000 * (float)loopTimingFactor * (float)F_CPU) / 16000000;
	CS_AutocaL_Millis = 20000;
    
	 Serial.print("timwOut =  ");
	 Serial.println(CS_Timeout_Millis);
	
	// get pin mapping and port for send Pin - from PinMode function in core

  /*
	sBit =  digitalPinToBitMask(sendPin);			// get send pin's ports and bitmask
	sPort = digitalPinToPort(sendPin);
	sReg = portModeRegister(sPort);
	sOut = portOutputRegister(sPort);				// get pointer to output register   
  */

  sBit = digitalPinToBitMask(sendPin);
  sPortRegister = portRegister(digitalPinToPort(sendPin));
  sPinCtrl = (uint8_t*)&sPortRegister->PIN0CTRL;

  rBit = digitalPinToBitMask(receivePin);
  rPortRegister = portRegister(digitalPinToPort(receivePin));
  rPinCtrl = (uint8_t*)&rPortRegister->PIN0CTRL;
  rBitFromBitField = getBitFromBitField(rBit);
  /*
	rBit = digitalPinToBitMask(receivePin);			// get receive pin's ports and bitmask 
	rPort = digitalPinToPort(receivePin);
	rReg = portModeRegister(rPort);
	rIn  = portInputRegister(rPort);
   	rOut = portOutputRegister(rPort);
    */

  Serial.print("send");
  Serial.println(sBit);
  //Serial.println(&(sPortRegister->DIRSET));
  Serial.println(*sPinCtrl);
	
	// get pin mapping and port for receive Pin - from digital pin functions in Wiring.c
    noInterrupts();
	//*sReg |= sBit;              // set sendpin to OUTPUT 
  sPortRegister->DIRSET = sBit;
  //sPortRegister->OUTCLR = sBit; // dont need to make input low
    interrupts();
	leastTotal = 0x0FFFFFFFL;   // input large value for autocalibrate begin
	lastCal = millis();         // set millis for start
}

// Public Methods //////////////////////////////////////////////////////////////
// Functions available in Wiring sketches, this library, and other libraries

long CapacitiveSensor::capacitiveSensor(uint16_t samples)
{
	total = 0;
	if (samples == 0) return 0;
	if (error < 0) return -1;            // bad pin


	for (uint16_t i = 0; i < samples; i++) {    // loop for samples parameter - simple lowpass filter
		if (SenseOneCycle() < 0)  return -2;   // variable over timeout
}

		// only calibrate if time is greater than CS_AutocaL_Millis and total is less than 10% of baseline
		// this is an attempt to keep from calibrating when the sensor is seeing a "touched" signal

		if ( (millis() - lastCal > CS_AutocaL_Millis) && abs(total  - leastTotal) < (int)(.10 * (float)leastTotal) ) {

			// Serial.println();               // debugging
			// Serial.println("auto-calibrate");
			// Serial.println();
			// delay(2000); */

			leastTotal = 0x0FFFFFFFL;          // reset for "autocalibrate"
			lastCal = millis();
		}
		/*else{                                // debugging 
			Serial.print("  total =  ");
			Serial.print(total);

			Serial.print("   leastTotal  =  ");
			Serial.println(leastTotal);

			Serial.print("total - leastTotal =  ");
			x = total - leastTotal ;
			Serial.print(x);
			Serial.print("     .1 * leastTotal = ");
			x = (int)(.1 * (float)leastTotal);
			Serial.println(x);   
		} */

	// routine to subtract baseline (non-sensed capacitance) from sensor return
	if (total < leastTotal) leastTotal = total;                 // set floor value to subtract from sensed value         
	return(total - leastTotal);

}

long CapacitiveSensor::capacitiveSensorRaw(uint16_t samples)
{
	total = 0;
	if (samples == 0) return 0;
	if (error < 0) return -1;                  // bad pin - this appears not to work

	for (uint16_t i = 0; i < samples; i++) {    // loop for samples parameter - simple lowpass filter
		if (SenseOneCycle() < 0)  return -2;   // variable over timeout
	}

	return total;
}


void CapacitiveSensor::reset_CS_AutoCal(void){
	leastTotal = 0x0FFFFFFFL;
}

void CapacitiveSensor::set_CS_AutocaL_Millis(unsigned long autoCal_millis){
	CS_AutocaL_Millis = autoCal_millis;
}

void CapacitiveSensor::set_CS_Timeout_Millis(unsigned long timeout_millis){
	CS_Timeout_Millis = (timeout_millis * (float)loopTimingFactor * (float)F_CPU) / 16000000;  // floats to deal with large numbers
}

// Private Methods /////////////////////////////////////////////////////////////
// Functions only available to other functions in this library

int CapacitiveSensor::SenseOneCycle(void)
{
    noInterrupts();
	//*sOut &= ~sBit;        // set Send Pin Register low
  sPortRegister->OUTCLR = sBit;
	
	//*rReg &= ~rBit;        // set receivePin to input
  rPortRegister->DIRCLR = rBit;

	//*rOut &= ~rBit;        // set receivePin Register low to make sure pullups are off
  rPortRegister->OUTCLR = rBit;
	
	//*rReg |= rBit;         // set pin to OUTPUT - pin is now LOW AND OUTPUT
	//*rReg &= ~rBit;        // set pin to INPUT 
  rPortRegister->DIRSET = rBit;
  rPortRegister->DIRCLR = rBit;



	//*sOut |= sBit;         // set send Pin High
  sPinCtrl[sBitFromBitField] |= PORT_OPC_PULLUP_gc;
  //sPortRegister->DIRSET = sBit; //?????
    interrupts();

	while ( !(rPortRegister->IN & rBit)  && (total < CS_Timeout_Millis) ) {  // while receive pin is LOW AND total is positive value
	//while ( !(*rIn & rBit)  && (total < CS_Timeout_Millis) ) {  // while receive pin is LOW AND total is positive value
		total++;
	}
    
	if (total > CS_Timeout_Millis) {
		return -2;         //  total variable over timeout
	}
   
	// set receive pin HIGH briefly to charge up fully - because the while loop above will exit when pin is ~ 2.5V 
    noInterrupts();
	//*rOut  |= rBit;        // set receive pin HIGH - turns on pullup 
    rPinCtrl[rBitFromBitField] |= PORT_OPC_PULLUP_gc;
    //rPortRegister->OUTCLR = rBit;

	//*rReg |= rBit;         // set pin to OUTPUT - pin is now HIGH AND OUTPUT
    rPortRegister->DIRSET = rBit;

	//*rReg &= ~rBit;        // set pin to INPUT 
    rPortRegister->DIRCLR = rBit;

	//*rOut  &= ~rBit;       // turn off pullup
    //rPortRegister->OUTCLR = rBit; //?
    rPortRegister->DIRSET = rBit; //?

	//*sOut &= ~sBit;        // set send Pin LOW
    sPortRegister->OUTCLR = sBit;

    interrupts();

	while ( (/**rIn & rBit*/ (rPortRegister->IN & rBit)) && (total < CS_Timeout_Millis) ) {  // while receive pin is HIGH  AND total is less than timeout
	//while ( (*rIn & rBit) && (total < CS_Timeout_Millis) ) {  // while receive pin is HIGH  AND total is less than timeout
		total++;
	}
	// Serial.println(total);

	if (total >= CS_Timeout_Millis) {
		return -2;     // total variable over timeout
	} else {
		return 1;
	}
}


