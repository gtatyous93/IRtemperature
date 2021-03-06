/*f
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


#include <MSP430F1611.h>
#include <inttypes.h>
#include <stdio.h>

/*
#include "pal.h"
#include "codingStateMachine.h"
#include "framingEngine.h"
#include "packet.h"
*/

#include "config.h"
#include "utility.h"

 #include "interrupt.h"
#include "i2c.h"


#include "f1611_timer.h"

#define PREAMBLE_BIT_COUNT 5;
uint32_t i2c_receive_message;
uint32_t timerB_transmit_message[2] = {0,0};

enum {idle, transmit_1,transmit_2,preamble,ready} tx_state = ready;


void delay2(void)
{
	volatile int i = 10;
	while(i-->0){}
}

void translate_message(void)
{
	int i;
	for(i=0;i<=32;i++)
	{
		if(i < 16)
		{
			if(i2c_receive_message&(0x1<<i)) 	timerB_transmit_message[0] = (timerB_transmit_message[0] << 2) | 2;
			else								timerB_transmit_message[0] = (timerB_transmit_message[0] << 2) | 1;
		}
		else
		{
			if(i2c_receive_message&(0x1<<i)) 	timerB_transmit_message[1] = (timerB_transmit_message[1] << 2) | 2;
			else								timerB_transmit_message[1] = (timerB_transmit_message[1] << 2) | 1;
		}

	}
}
int packetReady = 0;

void TIMERB_handler(void)
{
	//Keep track of the position in the current frame being sent (10, 01) using a frame index.
	//Keep track of the number being translated
	static int packet_index = 0;

	//TBCCTL0 = packet_index << 2;

	switch(tx_state)
	{
	case idle:
		break;
	case ready:
		tx_state = preamble;
		packet_index = PREAMBLE_BIT_COUNT;
		//translate_message();
		timerB_transmit_message[0] = 0x5555;
		break;
	case preamble:
		P4OUT = 1;
		//TBCCTL0 = (1<<4);
		packet_index--;
		if(packet_index <= 0)
		{
			tx_state = transmit_1;
			packet_index=0;
		}
		break;
	case transmit_1:
		//TBCCTL0 = 0x4&(timerB_transmit_message >> (packet_index-2)) ;
		P4OUT = 0x1&(timerB_transmit_message[0] >> (packet_index)) ;
		packet_index++;
		if(packet_index >= 31)
		{
			tx_state = transmit_2;
			packet_index = 0;
		}
		break;
	case transmit_2:
		//TBCCTL0 = 0x4&(timerB_transmit_message >> (packet_index-2)) ;
		P4OUT = 0x1&(timerB_transmit_message[1] >> (packet_index)) ;
		packet_index++;
		if(packet_index >= 31)
		{
			tx_state = ready;
			packet_index = 0;
		}
		break;
	default:
		tx_state = ready;
		break;
	}
	delay2();


}

void I2C_handler(void)
{
	int data = I2CDRW;
}

int main ()
{
	int i = 0;
	//int count = 0;
	WDTCTL = WDTPW | WDTHOLD;	// Stop watchdog timer
	//initializeSystem();
	util_boardInit();
	util_enableInterrupt();
	__bis_SR_register(GIE);

	i2c_init(&I2C_handler,9600);
	i2c_enable_interrupt();
	timer_init(9600);
	timer_start();
    timer_setPeriodicCallback(&TIMERB_handler);

	P4DIR |= BIT0; //set as output
	P4SEL &= ~BIT0; //Set as GPIO
	P3DIR |= BIT3; //SCL output
	i2c_receive_message = 0x5555;

    while(1)
    {}
    while(1)
    {

		i = 3;
		while(i-->0)
		{
			//i2c_receive_message |= i2c_receive_byte(0)<<(8*1);

		}
		if(tx_state == idle) tx_state = ready;
	}

}

