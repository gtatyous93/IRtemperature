/*
 * main.c
 */
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdint.h>
#include <sysctl.h>
#include <gpio.h>
#include <interrupt.h>
#include <hw_types.h>
#include <hw_memmap.h>
#include <hw_ints.h>
#include <pin_map.h>
#include <adc.h>

#define SEQUENCE0 0
#define BUFFERLEN	348
#define VREF 	3
#define RESOLUTION		(1.24463519313)
#define	MV_TO_BITS(x)	(RESOLUTION*(float)x)


#define V_ONE			1140
#define V_ZERO			945
#define CLASSIFY(x)	(abs(x-V_ONE) > abs(x-V_ZERO) ? 0 : 1)

#define PREAMBLE_LEN	(5)
#define SAMPLES_PER_BIT	(4) /*programmatic definition?*/

uint32_t Sequence_data[BUFFERLEN];
uint64_t manchester_output = 0;
void processSequence(void);



void Sequence_IRQHandler(void)
{
	//ADCBusy(ADC0_BASE);
	static int sample_index = 0;

	uint32_t interruptsMask = ADCIntStatus(ADC0_BASE,SEQUENCE0,true);
	ADCSequenceDataGet(ADC0_BASE,SEQUENCE0,(Sequence_data+sample_index));
	sample_index +=8;
	if(sample_index >= BUFFERLEN-1)
	{
		sample_index = 0;
		processSequence();
	}

	ADCIntClear(ADC0_BASE,interruptsMask);
	ADCProcessorTrigger(ADC0_BASE,SEQUENCE0);

}

void processSequence(void)
{
	uint8_t decode_state = 0;
	uint32_t index=0;
	uint32_t manchester_result = 0;
	int32_t temp_result = 0;
	uint32_t bit_count = 0,zero_count = 0;
	uint8_t bit = 0,bit_previous=0;

	//For debugging
	uint16_t PREAMBLE_END,START_BIT_END,MANCH_BIT_END,MESSAGE_END;
	/*
	 * Classify each sample as a zero or one (or: find scheme that is better suited to manchester decoding)
	 */

	for(index=0;index<=BUFFERLEN;index++)
	{
		bit = (Sequence_data[index] < 100) ? bit_previous : CLASSIFY(Sequence_data[index]) ;
		bit_previous = bit;

		switch(decode_state)
		{
			case 0: //Wait for preamble
				/*
				if(bit==1) {bit_count++; zero_count = 0;}
				else if(bit==0) {zero_count++;bit_count++;}
				if(zero_count >= SAMPLES_PER_BIT)
				{
					bit_count = 0;
					zero_count = 0;
				}
				*/
				if(bit==1) bit_count++;
				else if(bit==0) bit_count = 0;
				//allow for a certain number of bit errors, at least one full preamble bit will be lost
				if(bit_count >= SAMPLES_PER_BIT*(PREAMBLE_LEN-1))
				{
					bit_count = 0;
					decode_state = 1;
					PREAMBLE_END = index;
				}
				break;
			case 1: //Preamble received, wait for start bit
				if(bit == 0) bit_count++;
				if(bit==1) bit_count = 0;
				if(bit_count >= SAMPLES_PER_BIT)
				{
					decode_state = 2;
					START_BIT_END = index;
					temp_result = 0;
					bit_count = 0;

				}
				break;
			case 2: //Start bit received, parsing is aligned now
				/* We need to maintain alignment, since drift is possible
				 * 	To accomplish this, the bit count will be used to indicate (with some uncertainty)
				 * 	that a bit has been detected. Its contents will be inspected and (taking into account errors)
				 * 	it will be assigned a value of 1 or 0, from a string of bits such as ...11101.... or ...01000....
				 * 	These bit strings will be separated from other bits based on "estimated" transitions
				 */
				temp_result = (temp_result << 1) | bit;
				//temp_result += bit;

				if(++bit_count >= (2*SAMPLES_PER_BIT))
				{
					//LSB - MSB
					temp_result = (temp_result>>SAMPLES_PER_BIT) - (temp_result&((1<<SAMPLES_PER_BIT)-1));
					manchester_result = (manchester_result << 1 ) | ((temp_result < 0) ? 0 : 1);
					temp_result = 0;
					MANCH_BIT_END = (index-START_BIT_END)>>2;
					bit_count = 0;
					zero_count++;
				}

				/*
				if(++bit_count >= SAMPLES_PER_BIT)
				{
					manchester_result = (manchester_result << 1) | ((temp_result>2) ? 1 : 0);
					bit_count = 0;
					temp_result = 0;
					zero_count++;
				}
				*/
				if(zero_count >= 16)
				{
					bit_count = 0;
					decode_state = 0;
					MESSAGE_END = index;

					//convert to bit positions: find number of SAMPLE_LEN offsets from start bit, divide by 2 again to get decoded bit length
					MESSAGE_END = (index-START_BIT_END) >> 3;
				}
 				break;
		}


		//temp_result += CLASSIFY(Sequence_data[index]);


	}
	//return manchester_result;
}

void init_ADC(void)
{
	//clock configuration:
	/*
	 * CLKSRC: PLL(480MHz), PIOSC(16MHz)
	 * CLOCK_RATE: FUlL, HALF, QUARTER, EIGHTH
	 */

	uint32_t clkDivider = 39;
	uint32_t clkConfig = (ADC_CLOCK_SRC_PIOSC+ADC_CLOCK_RATE_FOURTH);
	uint32_t stepConfig = ADC_CTL_IE+ADC_CTL_END+ADC_CTL_CH0;
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOE); // DCC Signal Output
	while(!SysCtlPeripheralReady(SYSCTL_PERIPH_GPIOE)){}
	GPIOPinTypeADC(GPIO_PORTE_BASE, (1<<3));
	SysCtlPeripheralClockGating(true);
	//ADCPhaseDelaySet(ADC0_BASE);

	SysCtlClockSet(SYSCTL_SYSDIV_64|SYSCTL_USE_PLL|SYSCTL_OSC_MAIN|SYSCTL_XTAL_16MHZ);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_ADC0); // DCC Signal Output
	//SysCtlADCSpeedSet(SYSCTL_ADCSPEED_250KSPS);
	ADCSequenceDisable(ADC0_BASE,0);
	while(!SysCtlPeripheralReady(SYSCTL_PERIPH_ADC0)){}

	ADCClockConfigSet(ADC0_BASE,clkConfig,clkDivider);
	ADCReferenceSet(ADC0_BASE,ADC_REF_INT);

	//sequence configuration
	ADCSequenceConfigure(ADC0_BASE,SEQUENCE0,ADC_TRIGGER_PROCESSOR,0);
	ADCSequenceStepConfigure(ADC0_BASE,SEQUENCE0,7,stepConfig);
	ADCSequenceEnable(ADC0_BASE,SEQUENCE0);

	//interrupts on sequence 0
	ADCIntRegister(ADC0_BASE,SEQUENCE0,&Sequence_IRQHandler);
	ADCIntEnable(ADC0_BASE,SEQUENCE0);
	//ADCIntEnableEx(); //?

	IntPrioritySet(INT_ADC0SS0,0);
	IntEnable(INT_ADC0SS0);

	ADCProcessorTrigger(ADC0_BASE,SEQUENCE0);

}


void init_GPIO(void)
{
	GPIOPinTypeGPIOOutput(GPIO_PORTA_BASE,0x1F);
}
int main(void) {
	
	//TODO: use ADC as a communication interface
	/*
	 * Set up the ADC to sample at a clock rate(multiple of the input signal)
	 * Capture buffers of samples based on the presence of the preamble sequence.. state machine
	 *
	 */
	init_ADC();
	while(1)
	{
	}
}
