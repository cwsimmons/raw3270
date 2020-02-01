# raw3270
**IBM 3270 Coaxial Interface**
## Overview

See it work here https://www.edaplayground.com/x/guf

* This module is capable of sending and receiving 3270 coax frames as described by the "Type A" specification. This is a work in progress, but it has been tested against a real terminal and appears to work.
* The module is designed to be used with the Xilinx AXI BRAM Controller for use in Zynq devices.
* The serial clock is expected to be 28.3046 MHz, i.e. twelve times the bitrate.
* The system clock is expected to be 100 MHz, but can be changed to another suitably high frequency. The timing parameters used to judge the length of a bit run in the receiver should be adjusted accordingly.

## Memory Map
Byte Address | Read Function | Write Function
-------------|---------------|---------------
0x0          | TX Register   | TX Register
0x4          | RX Register   | None
0x8          | TX Status     | Reset
0xC          | RX Status     | Reset

**Reset Register**

Bit Position | Function
-------------|----------
0 (LSB)      | Reset (Cleared by hardware)

**TX Register**

Bit Position | Description
-------------|-------------
9-0          | Frame word

**RX Register**

Bit Position | Description
-------------|-------------
0            | Parity Bit
10-1         | Payload
11           | Sync Bit ('1')

**TX Status**

Bit Position | Description
-------------|-------------
4-0          | Number of words in queue
8            | TX Active

**RX Status**

Bit Position | Description
-------------|-------------
4-0          | Number of words in queue
8            | RX Active
