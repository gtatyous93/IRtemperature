HIJACK BSL

MAC:
python2 -m msp430.bsl.target -e -p <port> --invert-test --invert-reset --swap-reset-test <FIRMWARE.txt>

WINDOWS:
python2 msp430\bsl\target\__main__.py -e -p COM5 --invert-test --invert-reset --swap-reset-test HIJACK_firmware.txt

