/*
  CapacitiveSense.h v.04 - Capacitive Sensing Library for 'duino / Wiring
  Copyright (c) 2008 Paul Bagder  All rights reserved.
  Version 04 by Paul Stoffregen - Arduino 1.0 compatibility, issue 146 fix
  vim: set ts=4:
*/

// ensure this library description is only included once
#ifndef CapacitiveSensor_h
#define CapacitiveSensor_h

#include "Arduino.h"

// library interface description
class CapacitiveSensor
{
  // user-accessible "public" interface
  public:
  // methods
	CapacitiveSensor(uint16_t sendPin, uint16_t receivePin);
	long capacitiveSensorRaw(uint16_t samples);
	long capacitiveSensor(uint16_t samples);
	void set_CS_Timeout_Millis(unsigned long timeout_millis);
	void reset_CS_AutoCal();
	void set_CS_AutocaL_Millis(unsigned long autoCal_millis);
  // library-accessible "private" interface
  private:
  // variables
	int error;
	unsigned long  leastTotal;
	unsigned int   loopTimingFactor;
	unsigned long  CS_Timeout_Millis;
	unsigned long  CS_AutocaL_Millis;
	unsigned long  lastCal;
	unsigned long  total;
	uint16_t sBit;   // send pin's ports and bitmask
	volatile uint16_t *sReg;
	volatile uint16_t *sOut;
	uint16_t rBit;    // receive pin's ports and bitmask 
	volatile uint16_t *rReg;
	volatile uint16_t *rIn;
	volatile uint16_t *rOut;
  // methods
	int SenseOneCycle(void);
};

#endif

