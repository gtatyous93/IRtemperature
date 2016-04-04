/*
 * Senior design team 17, GO GREEN
 */


#include <MSP430F1611.h>
#include <inttypes.h>
#include <stdio.h>
#include "config.h"
#include "utility.h"
#include "interrupt.h"
#include "f1611_timer.h"
#include "i2c_test.h"




#define TMP_AD00_SLAVE	0b1000000

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

#define PREAMBLE_BIT_COUNT (5)

enum {idle, transmit_1,transmit_2,preamble,ready} tx_state = ready;


#define IN_TYPE			uint16_t
#define OUT_TYPE		uint32_t
#define INPUT_TEMP_SIZE  (sizeof(IN_TYPE)*8)
#define OUTPUT_TEMP_SIZE (sizeof(OUT_TYPE)*8)

volatile OUT_TYPE manchester_output=0;
uint8_t mut_lock= 0;



void translate_message(IN_TYPE *input_data, volatile OUT_TYPE *encoded_data)
{
	//take data of size INPUT_TEMP_SIZE bits, translate manchester encoding  (0->0b01, 1->0b10) to output of twice this size
	int index;
//	for(index=0;index<INPUT_TEMP_SIZE;index++)
	for(index=(INPUT_TEMP_SIZE-1);index>=0;index--)
		*encoded_data = (*encoded_data<<2) | (1+(1&(*input_data>>index)));
}
void TIMERB_handler(void)
{
	//Keep track of the position in the current frame being sent (10, 01) using a frame index.
	//Keep track of the number being translated
	static int packet_index = 0;
	static OUT_TYPE bitbang_output = 0;
	uint8_t bit = 0;
	switch(tx_state)
	{
	case ready:
		P4OUT = 1;
		packet_index = (PREAMBLE_BIT_COUNT-1);
		tx_state = preamble;
		if(mut_lock == 1)
		{
			bitbang_output = manchester_output;
			mut_lock = 0;
		}
	case preamble:
		P4OUT = 1;
		if(packet_index-- <= 0)
		{
			tx_state = transmit_1;
			packet_index=0;
		}
		break;
	case transmit_1:
		//TBCCTL0 = 0x4&(manchester_output >> (packet_index-2)) ;
		bit = 0x1&(bitbang_output >> (packet_index)) ;
		P4OUT = bit;
		if(packet_index++ >= OUTPUT_TEMP_SIZE)
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


/*
 * timer B should retransmit until new data is avail
 * main polling / i2c rx loop will indicate when data is available (flag = 1)
 * 	read data
 * 	translate/encode data
 * 	if flag is clear:
 * 		update shared data
 * 		set flag
 * 	if flag is set:
 * 		continue (read more data)
 * timer B will acknowledge that it has received the new data (set flag to 0)
 * 	continue transmiting
 * 	in preamble state: if flag is set:
 * 		latch the new data
 * 		clear flag
 *
 */


int main ()
{
	//unsigned char pWriteBuf[3] = {0x11, 0x33, 0x77};
	volatile unsigned char pReadBuf[2] = {0,0};
	uint16_t temp_message = 0;
	WDTCTL = WDTPW | WDTHOLD;
	util_boardInit();

	__bis_SR_register(GIE);
	__disable_interrupt();

    timer_setPeriodicCallback(&TIMERB_handler);
	timer_init(10000); //10khz well within audio band
    InitI2CModule();

	__enable_interrupt();

	__delay_cycles(100000);
	timer_start();
	while(1)
	{
		ReadI2CDeviceREG(TMP_AD00_SLAVE, TMP007_VOBJ, 2, pReadBuf);
		if(mut_lock == 0)
		{
			temp_message = __swap_bytes( ((uint16_t) *pReadBuf) );
			translate_message(&temp_message,&manchester_output);
			mut_lock = 1;
		}
	}

#ifdef no
	while(2)
    {
		//
		if(mut_lock == 0)
		{

			mut_lock = 1;
		}

#endif

}






