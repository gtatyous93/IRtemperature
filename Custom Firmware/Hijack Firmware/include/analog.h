/*
 *  This file is part of hijack-infinity.
 *
 *  hijack-infinity is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  hijack-infinity is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with hijack-infinity.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __ANALOG_H__
#define __ANALOG_H__

#include "config.h"

#if defined(MSP430FR5969) || defined(MSP430F1611)

#include <stdint.h>
#include "msp430.h"
#include <inttypes.h>
#include <stddef.h>
#include "adc.h"
#include "reference.h"
#include "hardware.h"
 
enum analog_inputEnum {
	analog_input_vcc,
	analog_input_extTemp,
	analog_input_in1,
	analog_input_in2
};

// Initializes the ADC machinery and
// prepares for sampling.
void analog_init(void);

// Synchronously reads an input
uint16_t analog_readInput(enum analog_inputEnum input);

void analog_sampleAll(void);

#endif

#endif