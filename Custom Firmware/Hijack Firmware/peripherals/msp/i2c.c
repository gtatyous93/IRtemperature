#include "i2c.h"

i2c_IRQHandler *I2C_callback;

#define TMP_SDA_SLAVE	0b1000010
#define TMP007_I2CADDR 0x40

void i2c_init(i2c_IRQHandler* cb,int f){

	//Configure I2C: I2CEN must be disabled for all configuration
	U0CTL = 0;
	U0CTL |= SWRST;
	//Disable I2C (automatically when only these two bits are set), set I2C mode
	U0CTL |= I2C + SYNC;
	U0CTL &= ~I2CEN;

	U0CTL |= MST;
	// Set clock source to SMCLK
	I2CTCTL = 0X00;
	I2CTCTL = I2CSSEL_3;// + I2CRM;
	I2CPSC = 1; //divide by 3
	I2CSCLL = 10; //low-period: 2+I2CSCLL (minimum of 5 output)
	I2CSCLH = 10;//100; //high-period: 2+I2CSCLH (minimum of 5 output))
	I2COA = 1;
	I2CSA = TMP_SDA_SLAVE;
	I2CIFG = 0;

	//Set callback function for interrupt handler
	I2C_callback = cb;
	// Enable I2C
	U0CTL |= I2CEN;


}

void i2c_enable_interrupt()
{
	I2CIE |= RXRDYIE + TXRDYIE;
}

void i2c_disable_interrupt()
{
}


void I2C_rx (void)
{
	//Data has been received from the temperature sensor:
	I2C_callback();
	I2CIFG |= RXRDYIFG;
}
void i2c_send_byte(uint8_t txdat){
	// Three byte transfer
	I2CNDAT = 0x01;
	
	// Master mode
	U0CTL |= MST;
	
	// Start transfer - start bit, stop bit, tx mode
	I2CTCTL |= I2CSTT + I2CSTP + I2CTRX;
	
	// Wait for transmitter to be ready, 
	// then load transfer byte and wait
	// for stop condition
	while((I2CIFG & TXRDYIFG) == 0);
	I2CDRB = txdat;
	while((I2CTCTL & I2CSTP) == 0x02);
}

uint8_t i2c_receive_byte(uint8_t readReg){
	uint8_t i = 0;
	uint8_t recByte = 0;
	
	//i2c_send_byte(readReg);
	
	I2CNDAT = 0x03;
	
	// There is some condition in which it 'falls out' of master
	// mode so just to be safe I do it each time. If this is 
	// redundant it wont hurt anything
	U0CTL |= MST;
	
	// Start bit, stop bit, rx mode
	I2CTCTL = I2CSTT + I2CSTP;
	
	// What for receiver to be ready
	while((I2CIFG & RXRDYIFG) == 0);
	
	// Receive byte
	recByte = I2CDRB;
	
	// Wait for receiver to be ready
	while((I2CIFG & RXRDYIFG) == 0);
	
	// Cant tell what this does but I couldnt get it to work without it
	// I found it in some example code
	i = i + I2CDRB;
	
	// Wait for the transmission to be complete
	while(I2CTCTL & I2CSTP);
	
	return recByte;
}
