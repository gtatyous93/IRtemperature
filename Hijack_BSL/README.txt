This document describes how to load code to the hijack MSP430F1611 

Python 2.6 must be installed, and pyserial v2.5

P2.6: Get python 2.6 from python webpage
pyserial: (as admin) pip install pyserial==2.5

First use:
1. From this directory, run (as admin): python setup.py install
2. Ignore the error message on installation. 

Continued use:
1. Determine the port that the USB is using. On my Macbook, the port name was ‘/dev/tty.usbserial-AH025K4J’
2. Generate machine code in ti-text or ihex format using CCS or any other build tools for the MSP430F1611
3. In the same directory, run: python -m msp430.bsl.target -e -p <port name> --invert-test --invert-reset --swap-reset-test -i <fileformat> <file>
This command will erase the memory on the MCU, and then program the hex file into the board’s memory using UART (taking advantage of the built in BSL firmware for programming over UART)

Unix system:
python -m msp430.bsl.target -e -p /dev/tty.usbserial-AH025K4J --invert-test --invert-reset --swap-reset-test -i ihex <filename>.ihex

python -m msp430.bsl.target -e -p /dev/tty.usbserial-AH025K4J --invert-test --invert-reset --swap-reset-test <filename>.titext


Windows system: Determine the right COM port to use and replace COM1 as necessary

python msp430\bsl\target\__main.py__ -e -p COM1 --invert-test --invert-reset --swap-reset-test -i ihex <filename>.ihex

python msp430\bsl\target\__main.py__ -e -p COM1 --invert-test --invert-reset --swap-reset-test <filename>.titext







