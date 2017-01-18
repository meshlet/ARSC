# ARSC (A Relatively Simple Computer)

ARSC is a FPGA-based, 16-bit computer system. It's instruction set and CPU architecture are based on the hypothetical computer system
designed in Computer Organization, Design and Architecture, 4th Edition by Sajjan G. Shiva.

In the interest of clarity, the ARSC documentation is divided into several seperated documents each covering a specific portion of the
system:

* [ARSC Architecture](docs/ARSC_ARCH.md) - describes ARSC system architecture in greater detail. Anyone who wishes to experiement with
ARSC should read this document, especially those who plan to modify and/or extend the hardware platform.

* [How-To Synthesize ARSC](docs/COMPILE_ARSC.md) - explains how to synthesize the ARSC design for Altera FPGA's and gives suggestions
of what has to be modified to make ARSC compile for FPGAs of other manufacturers.

* [Programming ARSC](docs/PROGRAMMING_ARSC.md) - delves into ARSC ISA, ARSC assembly and aims to bring readers up-to speed with ARSC
assembly programming.

* [Performance Evaluation](ARSC_PERFORMANCE.md) - gives summary of the theoretical evaluation of the performance for the ARSC system.

## Features

* *ARSC CPU* - an accumulator-based, 16-bit CPU composed of the *ARSC CU*, *ARSC ALU* and *ARSC BUS*.
* *ARSC ISA* - 16-bit instruction set architecture implemented by the ARSC CPU.
* Supports two types of main memory: off-chip SDRAM and on-chip RAM.
* *VGA controller* - implements VGA synchronization circuit and rendering.
* *Video RAM* - implemented as a dual-port on-chip memory.
* *PS/2 Keyboard controller* - PS/2 receiver and keyboard interface circuit.
* *ARSC assembler* - compiles a program written in the ARSC assembly language into ARSC machine code ready to be run by the ARSC CPU.

## Supported FPGAs

This section lists all the FPGA boards that successfully ran the ARSC design. I would kindly ask to send me a notification in case you
test the ARSC system on a FPGA board not listed here. Currently tested FPGAs:

* Altera DE0-CV (Cyclone V)
