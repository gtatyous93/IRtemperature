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

#include <inttypes.h>
#include <stdio.h>

#include "pal.h"
#include "codingStateMachine.h"
#include "framingEngine.h"
#include "packet.h"
#include "utility.h"

 #include "interrupt.h"
#include "i2c.h"


#include "f1611_timer.h"

#define PREAMBLE_BIT_COUNT 5;
uint32_t i2c_receive_message;
uint64_t timerB_transmit_message;

enum {idle, transmit,preamble,ready} tx_state;
void translate_message(void)
{
	int i;
	for(i=0;i<=32;i++)
	{
		if(i2c_receive_message&(0x1<<i)) 	timerB_transmit_message = (timerB_transmit_message << 2) | 2;
		else								timerB_transmit_message = (timerB_transmit_message << 2) | 1;
	}
}
int packetReady = 0;

void periodic_callback(void)
{
	//Keep track of the position in the current frame being sent (10, 01) using a frame index.
	//Keep track of the number being translated
	static int packet_index = 0;
	packet_index ^= 1;
	//P4OUT = packet_index;
	TBCCTL0 = packet_index << 2;
	/*
	switch(tx_state)
	{
	case idle:
		break;
	case ready:
		tx_state = preamble;
		packet_index = PREAMBLE_BIT_COUNT;
		translate_message();
		break;
	case preamble:
		P4OUT = 1;
		//TBCCTL0 = (1<<4);
		if(packet_index-->0) tx_state = transmit;
		break;
	case transmit:
		TBCCTL0 = 0x4&(timerB_transmit_message >> (packet_index-2)) ;
		P4OUT = 0x1&(timerB_transmit_message >> (packet_index)) ;
		if(packet_index-->0) tx_state = preamble;
		break;
	}
	*/

}

void capture_callback(uint16_t arg)
{

}

void delay2(void)
{
	volatile int i = 10;
	while(i-->0){}
}

int main ()
{
	int i = 0;
	int count = 0;
	WDTCTL = WDTPW | WDTHOLD;	// Stop watchdog timer
	//initializeSystem();
	//interrupt_init();
	//i2c_init();
	P3DIR = 1<<3;
	while(1)
 	{
		delay2();
 		P3OUT = 1<<3;
 		delay2();
		P3OUT = 0;

 	}
	__bis_SR_register(GIE);
	timer_init();
	timer_start();
    timer_setPeriodicCallback(&periodic_callback);
    //timer_setCaptureCallback(&capture_callback);
    i2c_receive_message = 0xAAAA;
 	P4OUT = 1;


    while (1)
	{
		i = 3;
		while(i-->0)
		{
			//i2c_receive_message |= i2c_receive_byte(0)<<(8*1);

		}
		if(tx_state == idle) tx_state = ready;
	}

}

