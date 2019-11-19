# raw3270
**IBM 3270 Coaxial Interface**
## Overview

* This module is capable of sending and receiving 3270 coax frames as described by the "Type A" specification. This is a work in progress and has not been tested against a real terminal.
* The module is designed to be used with the Xilinx AXI BRAM Controller for use in Zynq devices.
* The serial clock is expected to be 28.3046 MHz, i.e. twelve times the bitrate.
* The system clock is expected to be 100 MHz, but can be changed to another suitably high frequency. The timing parameters used to judge the length of a bit run in the receiver should be adjusted accordingly.

## Memory Map
Byte Address | Function
-------------|----------
0x0          | TX Register
0x1          | RX Register
0x2/0x3      | Control Register

**Control Register**

Bit Position | Function
-------------|----------
0 (LSB)      | Reset (Cleared by hardware)
1            | Start (Cleared by hardware)
2            | TX Active
3            | RX Data Available
9-4          | Number of Words Available
