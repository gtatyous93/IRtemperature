//******************************************************************************
//			msp430f1611
//		------------------
//				p3.1 SDA
//      		p3.3 SCL                                            
//					GND
//
//******************************************************************************



#include "i2c_test.h"

volatile int				I2CBufferPointer = 0;
volatile int				I2CReadCount 	 = 0;
volatile int				I2CWriteCount 	 = 0;
volatile unsigned char	*pI2CBuffer 	 = 0;
volatile unsigned char	I2CSlaveRegAddress = 0;

#define BIT_CLEAR(x,y)	x &= ~(y);
#define BIT_SET(x,y)	x |= (y);

void delay_ms(void)
{
	volatile unsigned long i = 0xF4240 >> 11;
	while(i-->0){}
}
 
//******************************************************************************
//	func : InitI2CModule
//	description : Setup I2C Module
//******************************************************************************


void InitI2CModule(void)
{
	delay_ms();
	//P3.4 P3.5 UART0 TXD, RXD pin not select
	BIT_CLEAR(P3SEL, BIT4 + BIT5);
	//SET_PORT_IO_UTX0_PIN();
	//SET_PORT_IO_URX0_PIN();

	//P3.1,P3.3  I2C pin select
	BIT_SET(P3SEL, BIT1 + BIT3);
	//SET_PORT_MOD_I2C_SDA_PIN();
	//SET_PORT_MOD_I2C_SCL_PIN();

	//P3.1 P3.3 Set up Inputt
	BIT_CLEAR(P3DIR, BIT1 + BIT3);
	//SET_PORT_IN_I2C_SDA_PIN();
	//SET_PORT_IN_I2C_SCL_PIN();

	U0CTL = 0;						//Must need. for switch i2c <=> serial, spi

	BIT_SET(U0CTL, SWRST);			//I2C operation is enabled 	


	BIT_SET(U0CTL, I2C + SYNC);			// Switch USART0 to I2C mode

	BIT_CLEAR(U0CTL, I2CEN);				// clear I2CEN bit => necessary to re-configure I2C module(must this line)

	BIT_CLEAR(U0CTL, XA);	 	  			//7bit addressing
	BIT_CLEAR(U0CTL, LISTEN);				// Nomal Mode,(<=> loopback)
	BIT_CLEAR(U0CTL, RXDMAEN);				// I2C RXD DMA Disable
	BIT_CLEAR(U0CTL, TXDMAEN);				// I2C TXD DMA Disable

	I2CTCTL = 0X00;					//I2C control reg reset
	I2CTCTL = I2CSSEL_3;			// smclk , clock source,

	I2CIE   = 0;//TXRDYIE + NACKIE+ RXRDYIE + ARDYIE + STTIE + OAIE; // Enable I2C interrupts

	I2CIFG  = 0x00;					// clear I2C interrupt flags

	I2COA = 3;			// own address(local)

//	I2CNDAT = I2CTXDByteCnt;		// the number of bytes transmitted by I2C 

	// set i2c speed
	I2CPSC = 0X00;
  	I2CSCLL = I2CSCLH = 0X0A;		// 100K from 8M

	
	BIT_SET(U0CTL, I2CEN);					// Enable I2C

	BIT_CLEAR(IFG1, UTXIFG0);				//UART mode , don't care. USART0 transmit interrupt flag -> clear
	BIT_CLEAR(IFG1, URXIFG0);				//UART mode . don't care. USART0 receive interrupt flag -> clear
	
}
//******************************************************************************
//	func : InitI2CTx
//	description : Init I2C for TX
//******************************************************************************
void InitI2CTx(void)
{
	BIT_SET(U0CTL, MST);           	// define Master Mode
	BIT_SET(I2CTCTL, I2CTRX);      	// I2CTRX=1 => Transmit Mode (R/W bit = 0)
	BIT_CLEAR(I2CIFG, TXRDYIFG);		// clear Transmit ready interrupt flag 

	I2CIE = TXRDYIE;        	// enable Transmit ready interrupt
}

//******************************************************************************
//	func : InitI2CRx
//	description : Init I2C for RX
//******************************************************************************
void InitI2CRx(void)
{
	BIT_SET(U0CTL, MST);				// define Master Mode
	BIT_CLEAR(I2CTCTL, I2CTRX);     	// I2CTRX=0 => Receive Mode (R/W bit = 1)
	BIT_CLEAR(I2CIFG, RXRDYIFG);		// clear Receive ready interrupt flag


	I2CIE = RXRDYIE;        	// enable Receive ready interrupt
}

//******************************************************************************
//	func : WriteI2CDeviceREG
//	description : Write Register of Slave Device through I2C(DataCount)
//******************************************************************************
void WriteI2CDeviceREG(char SlaveAddress, char SlaveRegAddress, int WriteCnt, unsigned char *pWriteBuf)
{

	while (I2CDCTL&I2CBUSY);	// wait until I2C module has finished all operations

	I2CSA = SlaveAddress;		//set Slave address

	I2CSlaveRegAddress = SlaveRegAddress; 	// register address of Slave Device

	if(pI2CBuffer != 0)
		free((void *)pI2CBuffer);//error
	
	pI2CBuffer = (unsigned char*)malloc(WriteCnt);

	memcpy((void *)pI2CBuffer, (void *)pWriteBuf, WriteCnt);
		
	I2CNDAT = I2CWriteCount = WriteCnt + 1;
	I2CBufferPointer = 0;		
	
	InitI2CTx();
	I2CIFG &= ~ARDYIFG; 			// clear Access ready interrupt flag
	I2CTCTL |= I2CSTT+I2CSTP;		// start condition generation
	
	// => I2C communication is started

}

//******************************************************************************
//	func : ReadI2CDeviceREG
//	description : Read Register of Slave Device through I2C
//******************************************************************************
char ReadI2CDeviceREG(char SlaveAddress, char SlaveRegAddress, int ReadCnt, unsigned char *pReadBuf)
{
	if(ReadCnt == 0) return 0;
	if(pReadBuf == 0) return 0;
	
	/*
	P1OUT = 1<<2;
	while (I2CDCTL&I2CBUSY);			// wait until I2C module has finished all operations
	P1OUT = 0;
	I2CSA = SlaveAddress;				//set Slave address

	I2CSlaveRegAddress = SlaveRegAddress;		// register address of Slave Device

	I2CNDAT = I2CWriteCount = 1;				
	I2CBufferPointer = 0;
	

	InitI2CTx();
	I2CIFG &= ~ARDYIFG;  			// clear Access ready interrupt flag
	I2CTCTL |= I2CSTT+I2CSTP;   			// start condition generation
	

	*/
	//P1OUT = 1<<2;
	WriteI2CDeviceREG(SlaveAddress,SlaveRegAddress,1,pReadBuf);
	//while ((~I2CIFG)& ARDYIFG);  // wait until transmission is finished
	//P1OUT = 2<<2;
	while (I2CDCTL&I2CBUSY);
	pI2CBuffer = pReadBuf;
	I2CNDAT = I2CReadCount = ReadCnt;
	I2CBufferPointer = 0;
	
	InitI2CRx();
	I2CIFG &= ~ARDYIFG;         // clear Access ready interrupt flag
	I2CTCTL |= I2CSTT+I2CSTP;   // start receiving and finally generate

	// re-start and stop condition

	//while ((~I2CIFG)& ARDYIFG);	// wait untill transmission is finished
	return 1;
}



//******************************************************************************
//	func : ISR_I2C
//	description : interrupt I2C
//******************************************************************************
__attribute__((interrupt(USART0TX_VECTOR))) void ISR_I2C_tx(void)
{
	//I2C interrupt 
	switch (I2CIV)
	{ 
		case I2CIV_AL:		// I2C interrupt vector: Arbitration lost (ALIFG) 
			break;

		case I2CIV_NACK:	// I2C interrupt vector: No acknowledge (NACKIFG) 
			break;

		case I2CIV_OA:		// I2C interrupt vector: Own address (OAIFG) 
			break;

		case I2CIV_ARDY:	// I2C interrupt vector: Access ready (ARDYIFG) 
			break;

		case I2CIV_RXRDY:	// I2C interrupt vector: Receive ready (RXRDYIFG) 
			*(unsigned char *)(pI2CBuffer + I2CBufferPointer) = I2CDRB;	 // store received data in buffer
		
			if(++I2CBufferPointer >= I2CReadCount)
			{
				I2CIE &= ~RXRDYIE;	// disable interrupts
				I2CReadCount = I2CBufferPointer = 0;
				pI2CBuffer = 0;
			}
			BIT_CLEAR(I2CIFG, RXRDYIFG);
			break;

		case I2CIV_TXRDY:	// I2C interrupt vector: Transmit ready (TXRDYIFG) 

			if(I2CBufferPointer == 0)
				I2CDRB = I2CSlaveRegAddress;
			else
				I2CDRB = *(unsigned char *)(pI2CBuffer + (I2CBufferPointer - 1));
			
			if(++I2CBufferPointer >= I2CWriteCount)
			{
				if(I2CWriteCount == 1)//Tx slave REG Address in Read Sequence
					;
				else
					free((void *)pI2CBuffer);
				
				I2CIE &= ~TXRDYIE;	// disable interrupts
				I2CWriteCount = I2CBufferPointer = 0;
			}
			break;

		case I2CIV_GC:		// I2C interrupt vector: General call (GCIFG) 
			break;

		case I2CIV_STT: 	// I2C interrupt vector: Start condition (STTIFG) 
			break;

	}


}


__attribute__((interrupt(USART0RX_VECTOR))) void ISR_I2C_rx(void)
{
	//I2C interrupt
	switch (I2CIV)
	{
		case I2CIV_AL:		// I2C interrupt vector: Arbitration lost (ALIFG)
			break;

		case I2CIV_NACK:	// I2C interrupt vector: No acknowledge (NACKIFG)
			break;

		case I2CIV_OA:		// I2C interrupt vector: Own address (OAIFG)
			break;

		case I2CIV_ARDY:	// I2C interrupt vector: Access ready (ARDYIFG)
			break;

		case I2CIV_RXRDY:	// I2C interrupt vector: Receive ready (RXRDYIFG)

			*(unsigned char *)(pI2CBuffer + I2CBufferPointer) = I2CDRB;	 // store received data in buffer

			if(++I2CBufferPointer >= I2CReadCount)
			{
				I2CIE &= ~RXRDYIE;	// disable interrupts
				I2CReadCount = I2CBufferPointer = 0;
				pI2CBuffer = 0;
			}
			BIT_CLEAR(I2CIFG, RXRDYIFG);
			break;

		case I2CIV_TXRDY:	// I2C interrupt vector: Transmit ready (TXRDYIFG)

			if(I2CBufferPointer == 0)
				I2CDRB = I2CSlaveRegAddress;
			else
				I2CDRB = *(unsigned char *)(pI2CBuffer + I2CBufferPointer - 1);

			if(++I2CBufferPointer >= I2CWriteCount)
			{
				if(I2CWriteCount == 1)//Tx slave REG Address in Read Sequence
					;
				else
					free((void *)pI2CBuffer);

				I2CIE &= ~TXRDYIE;	// disable interrupts
				I2CWriteCount = I2CBufferPointer = 0;
			}
			break;

		case I2CIV_GC:		// I2C interrupt vector: General call (GCIFG)
			break;

		case I2CIV_STT: 	// I2C interrupt vector: Start condition (STTIFG)
			break;

	}


}
//EOF
