/*
 * i2c_test.h
 *
 *  Created on: Apr 2, 2016
 *      Author: amsaclab
 */

#include <msp430f1611.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>

#ifndef I2C_TEST_H_
#define I2C_TEST_H_


char ReadI2CDeviceREG(char SlaveAddress, char SlaveRegAddress, int ReadCnt, unsigned char *pReadBuf);
void WriteI2CDeviceREG(char SlaveAddress, char SlaveRegAddress, int WriteCnt, unsigned char *pWriteBuf);
void InitI2CRx(void);
void InitI2CTx(void);
void InitI2CModule(void);


#endif /* I2C_TEST_H_ */
