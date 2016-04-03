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

#include "f1611_timer.h"

#ifdef MSP430F1611

#include "ptimer.h"
#include "ctimer.h"

#include "pal.h"

#include <msp430f1611.h>

timer_captureCallback *timer_captureCbPtr;
timer_periodicCallback *timer_periodicCbPtr;

void timer_init (int f) {
	__delay_cycles(1000);
	//////////////////////////////////
	// Comparator

    // Comp. A Int. Ref. enable on CA1
    CACTL1 = CARSEL+CAREF_2;
    // Comp. A Int. Ref. Select 2 : 0.5*Vcc
    // Comp. A Connect External Signal to CA0
    // Comp. A Enable Output Filter
    // enable comparator CA0 on P2.3 (P40 on epic)
	//CACTL2 = P2CA0+CAF;
	CACTL2 = P2CA0;
	// enable comparator
	CACTL1 |= CAON;

	///////////////////////////
	// TimerA - Capture Timer

	TACTL = TASSEL_2 + TACLR;
	TACCTL1 = CM_3 + CCIS_1 + CAP;// + CCIE;

	///////////////////////////
	// TimerB - Periodic Timer
//	P4SEL |= BIT0;
	P4DIR |= BIT0; //set as output
	P4SEL &= ~BIT0; //Set as GPIO

	//16 bit counter, SMCLK source(TBSSEL_2) / ACLK source(TBSSEL_1), interrupt enable, reset timer
	TBCTL = TBSSEL_2 + TBCLR + TBIE;

	//CCTL: no capture, compare mode, output set by OUT bit value, interrupt disabled (?)
	TBCCTL0 = CCIE;
	/*
	count up once per microsecond
	CCR0 = T/2, T = 2*CCR0
	f = 1/T = 1/(2*CCR0), CCR0 = 1/(2*f)
	*/
	//TBCCR0 = DELTAT*16;
	TBCCR0 = 1000000/(2*f);
}

void timer_start (void) {
	CACTL1 |= (CAON + CAREF_2);
	//TACTL |= MC_2;
	TBCTL |= MC_1; //up counting mode
}

void timer_setCaptureCallback (timer_captureCallback* cb) {
	timer_captureCbPtr = cb;
}

void timer_setPeriodicCallback (timer_periodicCallback* cb) {
	timer_periodicCbPtr = cb;
}

void timer_stop (void) {
	TACTL &= ~MC_2;
	TBCTL &= ~MC_1;
	CACTL1 &= ~(CAON + CAREF_2);
}

uint8_t timer_readCaptureLine (void) {
	return !(TACCTL1 & CCI);
}

#pragma vector = TIMERA1_VECTOR
__interrupt void Timer_A1 (void) {

	uint16_t captureReg = TAR;

	if (captureReg > 5) {
		TAR = 0;
		timer_captureCbPtr(captureReg);
	}

	TACCTL1 &= ~CCIFG;
}
/*
#pragma vector = TIMERB0_VECTOR
__interrupt void Timer_B0 (void)
*/
__attribute__((interrupt(TIMERB0_VECTOR))) void Timer_B0 (void)
{
	timer_periodicCbPtr();
	TBCTL |= TBIFG;
	TBCTL &= ~TBIFG;

	TBCCTL1 &= ~(COV);
	//TBIV |= TBIFG;

	//TBIV = ~0;
	//TBCCTL1 &= ~CCIFG;
	/*
	if (pendingTimerStop) {
		pendingStop = 0;
		pendingShutdown = 0;
		pendingTimerStop = 0;
		pendingStart = 1;
		_BIS_SR_IRQ(LPM3_bits);
	}
	*/
}


#endif
