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
#define BUFFERLEN	256
#define VREF 	3

//3000V: 1<<13
//0V: 0?
//RESOLUTION: (1<<13)/3000 units/mv
//

#define RESOLUTION		(1.24463519313)
#define	MV_TO_BITS(x)	(RESOLUTION*(float)x)
#define V_ONE			1195
#define V_ZERO			883
#define CLASSIFY(x)	(abs(x-V_ONE) > abs(x-V_ZERO) ? 0 : 1)

uint32_t Sequence_data[BUFFERLEN];
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
	uint32_t index1 = 0,index2=0;
	uint32_t manchester_result = 0;
	uint32_t temp_result = 0;
	/*
	 * Classify each sample as a zero or one (or: find scheme that is better suited to manchester decoding)
	 */
	for(index=0;index<=BUFFERLEN;index++)
	{
		//manchester_result = (manchester_result << 1) | CLASSIFY(Sequence_data[index]);
		Sequence_data[index] =CLASSIFY(Sequence_data[index]);
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
	//init_GPIO();
	while(1)
	{
	}
}
