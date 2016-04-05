/*
 * i2c_test.h
 *
 *  Created on: Apr 2, 2016
 *      Author: amsaclab
 */

#include <msp430f1611.h>
#include <inttypes.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>

#ifndef I2C_TEST_H_
#define I2C_TEST_H_


uint8_t ReadI2CDeviceREG(uint8_t SlaveAddress, uint8_t SlaveRegAddress, int ReadCnt, volatile uint8_t *pReadBuf);
void WriteI2CDeviceREG(uint8_t SlaveAddress, uint8_t SlaveRegAddress, int WriteCnt, volatile uint8_t *pWriteBuf);
void InitI2CRx(void);
void InitI2CTx(void);
void InitI2CModule(void);


#endif /* I2C_TEST_H_ */
