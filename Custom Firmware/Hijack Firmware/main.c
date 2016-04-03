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
#include "i2c_test.h"
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

enum {idle, transmit_1,transmit_2,preamble,ready} tx_state = ready;

#define TMP_SDA_SLAVE	0b1000000
//#define TMP_SCL_SLAVE	0b1000011

#define TMP007_VOBJ       0x00
#define TMP007_TDIE       0x01
#define TMP007_CONFIG     0x02
#define TMP007_TOBJ       0x03
#define TMP007_STATUS     0x04
#define TMP007_STATMASK   0x05

#define TMP007_CFG_RESET    0x8000
#define TMP007_CFG_MODEON   0x1000
#define TMP007_CFG_1SAMPLE  0x0000
#define TMP007_CFG_2SAMPLE  0x0200
#define TMP007_CFG_4SAMPLE  0x0400
#define TMP007_CFG_8SAMPLE  0x0600
#define TMP007_CFG_16SAMPLE 0x0800
#define TMP007_CFG_ALERTEN  0x0100
#define TMP007_CFG_ALERTF   0x0080
#define TMP007_CFG_TRANSC   0x0040

#define TMP007_STAT_ALERTEN 0x8000
#define TMP007_STAT_CRTEN   0x4000

#define TMP007_DEVID 0x1F

#define IN_TYPE			uint16_t
#define OUT_TYPE		uint32_t
#define INPUT_TEMP_SIZE  (sizeof(IN_TYPE)*8)
#define OUTPUT_TEMP_SIZE (sizeof(OUT_TYPE)*8)

OUT_TYPE timerB_transmit_message[2] = {0,0};
IN_TYPE i2c_receive_message = 0;
uint8_t I2C_register_pointer_current = 0;

void delay2(void)
{
	volatile uint32_t i = 0xF4240 >> 6;
	while(i-->0){}
}

void translate_message(void)
{
	int i;
	for(i=0;i<=INPUT_TEMP_SIZE;i++)
	{
		if(1)//i < (INPUT_TEMP_SIZE>>1))
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
	uint8_t bit = 0;
	//TBCCTL0 = packet_index << 2;

	switch(tx_state)
	{
	case idle:
		break;
	case ready:
		tx_state = preamble;
		packet_index = PREAMBLE_BIT_COUNT;
		//translate_message();
		timerB_transmit_message[0] = i2c_receive_message;
		timerB_transmit_message[1] = i2c_receive_message;
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
		bit = 0x1&(timerB_transmit_message[0] >> (packet_index)) ;
		//P4OUT = bit;
		P4OUT = bit;
		packet_index++;
		if(packet_index >= OUTPUT_TEMP_SIZE)
		{
			tx_state = ready;
			packet_index = 0;
		}
		break;
	case transmit_2:
		//TBCCTL0 = 0x4&(timerB_transmit_message >> (packet_index-2)) ;
		bit = 0x1&(timerB_transmit_message[1] >> (packet_index)) ;
		P4OUT = bit;
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
}

void I2C_handler(void)
{
	int data = I2CDRW;
	//dont use this

}

void I2C_initRX(void)
{
	U0CTL |= MST;
	I2CTCTL &= ~I2CTRX;
}

void I2C_initTX(void)
{
	U0CTL |= MST;
	I2CTCTL |= I2CTRX;
	I2CIFG &= ~TXRDYIFG;

}

void test_write(void)
{
	while (I2CDCTL&I2CBUSY);	// wait until I2C module has finished all operations

	I2CSA = 1;

	I2CNDAT = 5;

	I2C_initTX();
	I2CIFG &= ~ARDYIFG; 			// clear Access ready interrupt flag
	I2CTCTL |= I2CSTT+I2CSTP;		// start condition generation
	while(!(I2CIFG & TXRDYIFG) ); //wait
	I2CDRB = 0x55;
}
	void TMP_write(uint8_t reg_addr, uint16_t data)
{
	/* Write operation
	 * START bit
	 * First byte: slave address byte, R/W Low
	 * TMP responds with ack
	 * Second byte: register address for r/w access
	 * TMP responds with ack
	 * Third and Fourth bytes: data written to the register
	 * TMP responds with ack
	 * STOP bit
	 */


	while(!(I2CIFG & ARDYIFG) );

	I2C_register_pointer_current = reg_addr;
	I2CNDAT = 3;
	I2CTCTL = I2CSTT + I2CSTP;

	I2CDRB = reg_addr; //send register address
	while(!(I2CIFG & TXRDYIFG) ); //wait

	I2CDRB = data&0xF; //send register address
	while(!(I2CIFG & TXRDYIFG) ); //wait

	I2CDRB = (data>>8)&0xF; //send register address
	while(!(I2CIFG & TXRDYIFG)); //wait

	//I2CTCTL = I2CSTP;
	while(I2CTCTL & I2CSTP);
}

void TMP_setRegAddr(uint8_t reg_addr)
{

	while (I2CDCTL&I2CBUSY);


	while(!(I2CIFG & ARDYIFG));
	I2CNDAT = 1;
	I2CTCTL = I2CSTT + I2CTRX + I2CSSEL_2;// + I2CSTP;

	while(!(I2CIFG & TXRDYIFG));
	I2CDRB = reg_addr; //send register address

	while(I2CTCTL & I2CSTP);
	I2C_register_pointer_current = reg_addr;

}

uint16_t TMP_read(void)
{
	//I2CRM = 1; : for variable length, sw-controlled byte lengths
	/* READ operation
	 * START bit
	 * First byte: slave address byte, R/W High
	 * TMP responds with byte 1 (MSB) from register pointer
	 * Second byte: ACK to TMP:
	 * TMP responds with byte 2 (LSB) from register pointer
	 * Third byte: ACK to TMP
	 * STOP bit
	 */
	uint16_t data = 0;
	U0CTL |= MST;
	// Start bit, stop bit, rx mode
	while(!(I2CIFG & ARDYIFG) );
	I2CNDAT = 2;
	I2CTCTL = I2CSTT +I2CSTP ;

	while(!(I2CIFG & RXRDYIFG) );
	data = I2CDRB<<8;

	while(!(I2CIFG & RXRDYIFG) );
	data |= I2CDRB;

	//I2CTCTL = I2CSTP;
	while(I2CTCTL & I2CSTP);
	return data;
}

void TMP_config(int confData)
{

}

uint16_t TMP_getTemp(void)
{
	//slave address
	/*
	if(I2C_register_pointer_current != TMP007_VOBJ) TMP_setRegAddr(TMP007_VOBJ);
	return TMP_read();

	 */
	//i2c_init(&I2C_handler,9600);
	TMP_setRegAddr(TMP007_VOBJ);
	return 0x5555;

}
int main ()
{

	unsigned char pWriteBuf[3] = {0x11, 0x33, 0x77};
	unsigned char pReadBuf[2] = {0,0};
	int temp_message = 0;
	//int count = 0;
	WDTCTL = WDTPW | WDTHOLD;	// Stop watchdog timer
	//initializeSystem();
	util_boardInit();
	__bis_SR_register(GIE);
	//i2c_init(&I2C_handler,9600);
	//i2c_enable_interrupt();
	__disable_interrupt();

	timer_init(44000);

    timer_setPeriodicCallback(&TIMERB_handler);
    InitI2CModule();

	__enable_interrupt();

	__delay_cycles(100000);
	timer_start();

	while(1)
    {

    	//temp_message = TMP_getTemp();

    	//WriteI2CDeviceREG(0x59, TMP007_TDIE, 3, pWriteBuf);
    	ReadI2CDeviceREG(TMP_SDA_SLAVE, TMP007_TDIE, 2, pWriteBuf);
    	//if ((I2CDCTL&I2CBUSY)) //If the I2C is no longer busy, then we can resynchronize our input message
    		//temp_message = __swap_bytes( ((uint16_t) pReadBuf) );

    	if(tx_state == idle) //If the SM for the transmitter (Timer B) is in its idle state, we may synch our temp message and resume transferring
		{
    		i2c_receive_message = temp_message;
			tx_state = ready;
		}
	}

}

