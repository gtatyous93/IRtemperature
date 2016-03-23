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

#include "utility.h"

#if defined(MSP430FR5969) || defined(MSP430F1611)

void delay(register uint16_t delayCycles) {
#ifdef __GNUC__
	__asm__ (
		"    sub   #20, %[delayCycles]\n"
		"1:  sub   #4, %[delayCycles] \n"
		"    nop                      \n"
		"    jc    1b                 \n"
		"    inv   %[delayCycles]     \n"
		"    rla   %[delayCycles]     \n"
		"    add   %[delayCycles], r0 \n"
		"    nop                      \n"
		"    nop                      \n"
		"    nop                      \n"
		:                                 // no output
		: [delayCycles] "r" (delayCycles) // input
		:                                 // no memory clobber
	);
#else
	__asm(
		"    sub   #20,r12\n"
		"    sub   #4,r12\n"
		"    nop\n"
		"    jc    $-4\n"
		"    inv   r12\n"
		"    rla   r12\n"
		"    add   r12,r0\n"
		"    nop\n"
		"    nop\n"
		"    nop\n"
	);
#endif
	//   ret provided by C
}

void util_disableWatchdog(void) {
	WDTCTL = WDTPW + WDTHOLD;
}

void util_boardInit(void) {

#ifdef MSP430FR5969
	// Sets all the pins as inputs with
	// enabled pull-down resistor for power
	// savings.
	P1DIR = 0;
	P1OUT = 0;
	P1REN = 0xFF;

	P2DIR = 0;
	P2OUT = 0;
	P2REN = 0xFF;

	P3DIR = 0;
	P3OUT = 0;
	P3REN = 0xFF;

	P4DIR = 0;
	P4OUT = 0;
	P4REN = 0xFF;

	PJDIR = 0;
	PJOUT = 0;
	PJREN = 0xFF;

	// Password enabled clock register access
	CSCTL0_H = 0xA5;

	// Set DCO= 16MHz
	CSCTL1 = DCOFSEL_4 | DCORSEL;

	// Sets up clocks, analog attached to low-frequency osc.
	// system bus and master clock to digital osc.
	CSCTL2 = SELA__VLOCLK + SELS__DCOCLK + SELM__DCOCLK;

	// No clock division.
	CSCTL3 = DIVA__1 + DIVS__1 + DIVM__1;

	// Turn off some extra osc.
	CSCTL4 = LFXTOFF | HFXTOFF;

	CSCTL5 &= ~(LFXTOFFG | HFXTOFFG);
#endif

#ifdef MSP430F1611

	// Pin setup determiend from TinyOS.

	P1SEL = 0;
	P2SEL = 0;
	P3SEL = 0;
	P4SEL = 0;
	//P5SEL = 0x20; // output SMCLK on P5.5
    P5SEL = 0;
	P6SEL = 0;

	P1OUT = 0x00;
	P1DIR = 0x00;

	P2OUT = 0x00;
	P2DIR = 0x00;

	P3OUT = 0x00;
	P3DIR = 0x00;

	P4OUT = 0x00;
	P4DIR = 0x00;

	P5OUT = 0x00;

	//P5DIR = 0x20;
	P5DIR = 0x00;

	P6OUT = 0x00;
	P6DIR = 0x00;

	
	// NEW LOW POWER STUFF
	P1DIR = 0b11111111;

	//P2DIR = 0b11101011;
	P2DIR = 0b11010110;
	//P2DIR = 0b01000011;
	P3DIR = 0b11111111;
	P4DIR = 0b11111111;
	P5DIR = 0b11111111;
	P6DIR = 0b11111111;
	
	// END NEW LOW POWER STUFF

	P1IE = 0;
	P2IE = 0;

	// Setup Clocks
    // BCSCTL1
    // .XT2OFF = 1; disable the external oscillator for SCLK and MCLK
    // .XTS = 0; set low frequency mode for LXFT1
    // .DIVA = 0; set the divisor on ACLK to 1
    // .RSEL, do not modify
    
	BCSCTL1 = XT2OFF | (BCSCTL1 & (RSEL2|RSEL1|RSEL0));

    BCSCTL1 |= RSEL0 + RSEL1 + RSEL2;

    BCSCTL2 |= DIVS_3;

    DCOCTL |= DCO0 + DCO1 + DCO2;

    _BIS_SR(OSCOFF);
    // BCSCTL2
    // .SELM = 0; select DCOCLK as source for MCLK
    // .DIVM = 0; set the divisor of MCLK to 1
    // .SELS = 0; select DCOCLK as source for SCLK
    // .DIVS = 2; set the divisor of SCLK to 4
    // .DCOR = 1; select internal resistor for DCO
    //BCSCTL2 = DIVS1 | DCOR;

#endif
	
}

void util_enableInterrupt(void) {
	__enable_interrupt();
}

void util_disableInterrupt(void) {
	__disable_interrupt();
}

void util_delayMs(uint16_t ms) {
	while (ms--) {
		__delay_cycles(16000000 / 1000);
	}
}

void util_delayCycles (uint16_t cycles) {
	cycles &= ~0x8;
	while (cycles-=8) {
		__delay_cycles(8);
	}
}

#endif