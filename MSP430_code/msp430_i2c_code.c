#include <msp430g2553.h>


int TXByteCtr;
unsigned char PRxData;                     
int Rx = 0;
char WHO_AM_I = 0x00;
char itgAddress = 0x69;

int current_temperature_byte = 0;
unsigned int current_temperature = 0;


void init_I2C(void);
void Transmit(void);
void Receive(void);



/*

Tx Buffer written to at UCB0TXBUF, taken from 
Rx Buffer read from UCB0RXBUF, put into PRxData

TODO: add address information

*/
void condition_signal(char data)
{
//Read in temperature bytes from the I2C interface byte by byte, feed them into this data structure
	current_temperature_byte++;
	if(current_temperature_byte < 3)
	{
		current_temperature = (current_temperature<<8) + data;
	}
}

int main(void)
{
  WDTCTL = WDTPW + WDTHOLD;                 // Stop WDT
  P1SEL |= BIT6 + BIT7;                     // Assign I2C pins to USCI_B0
  P1SEL2|= BIT6 + BIT7;                     // Assign I2C pins to USCI_B0
  init_I2C();


  while(1){
      //Transmit process
      Rx = 0;
      if(current_temperature_byte >= 3)
      {
      	TXByteCtr = 3;
	    Transmit(); //enter LPM until message is transmitted
	  }
      //Receive process
      Rx = 1;
      Receive();
      temperature_reading = condition_signal(PRxData)
  }
}

//-------------------------------------------------------------------------------
// The USCI_B0 data ISR is used to move received data from the I2C slave
// to the MSP430 memory. It is structured such that it can be used to receive
//-------------------------------------------------------------------------------
#pragma vector = USCIAB0TX_VECTOR
__interrupt void USCIAB0TX_ISR(void)
{
  if(Rx == 1){                              // Master Recieve?
      PRxData = UCB0RXBUF;                       // Get RX data
      __bic_SR_register_on_exit(CPUOFF);        // Exit LPM0
  }

  else{                                     // Master Transmit
      if (TXByteCtr)                            // Check TX byte counter
        {
          UCB0TXBUF = current_temperature&(0xFF<<8*TXByteCtr); // Load TX buffer: shift out MSB to LSB (?)
          TXByteCtr--;                            // Decrement TX byte counter
        }
        else
        {
          UCB0CTL1 |= UCTXSTP;                    // I2C stop condition
          IFG2 &= ~UCB0TXIFG;                     // Clear USCI_B0 TX int flag
          __bic_SR_register_on_exit(CPUOFF);      // Exit LPM0
        }
 }

}
void init_I2C(void) {
      UCB0CTL1 |= UCSWRST;                      // Enable SW reset
      UCB0CTL0 = UCMST + UCMODE_3 + UCSYNC;     // I2C Master, synchronous mode
      UCB0CTL1 = UCSSEL_2 + UCSWRST;            // Use SMCLK, keep SW reset
      UCB0BR0 = 12;                             // fSCL = SMCLK/12 = ~100kHz
      UCB0BR1 = 0;
      UCB0I2CSA = itgAddress;                         // Slave Address is 069h
      UCB0CTL1 &= ~UCSWRST;                     // Clear SW reset, resume operation
      IE2 |= UCB0RXIE + UCB0TXIE;               //Enable RX and TX interrupt
}

void Transmit(void){
    while (UCB0CTL1 & UCTXSTP);             // Ensure stop condition got sent
    UCB0CTL1 |= UCTR + UCTXSTT;             // I2C TX, start condition
    __bis_SR_register(CPUOFF + GIE);        // Enter LPM0 w/ interrupts
}
void Receive(void){
        while (UCB0CTL1 & UCTXSTP);             // Ensure stop condition got sent
        UCB0CTL1 &= ~UCTR ;                     // Clear UCTR
        UCB0CTL1 |= UCTXSTT;                    // I2C start condition
        while (UCB0CTL1 & UCTXSTT);             // Start condition sent?
        UCB0CTL1 |= UCTXSTP;                    // I2C stop condition
        __bis_SR_register(CPUOFF + GIE);        // Enter LPM0 w/ interrupts
}
