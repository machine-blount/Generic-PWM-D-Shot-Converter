<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Converts PWM signal into a 16bit unidirectional D-Shot frame. There are 4 mian functioanl blocks.
1. Affine mapping pulsewidth to an 11 bit throttle range.
2. Buffering the 1-bit tlm(telemetry) signal
3. Calculating a 4-bit CRC from the 12-bit tlm and throttle data internally
4. Transmitting frame serially, MSB first

## How to test

inputs:
1MHz minimum clk signal 
50Hz PWM signal
telemetry bit 
- 0 no tlm request
- 1 tlm request


## External hardware

N/A
