# ARSC (A Relatively Simple Computer)

ARSC is a FPGA-based, 16-bit computer system. It's instruction set and CPU architecture are based on the hypothetical computer system
designed in *Computer Organization, Design and Architecture, 4th Edition by Sajjan G. Shiva*.

In the interest of clarity, the ARSC documentation is divided into several seperated documents each covering a specific portion of the
system:

* [Programming ARSC](docs/PROGRAMMING_ARSC.md) - this is the recommended starting point for anyone who wishes to learn about ARSC. It
provides enough details on the ARSC internals without overwhelming the reader with too many architectural and hardware details. It also
presents the ARSC instruction set and ARSC assembly giving enough context to start writing ARSC programs.

* [ARSC ASSEMBLER](docs/ARSC_ASSEMBLER.md) - tutorial on the ARSC assembler and how to use it to translate ARSC assembly programs to the
ARSC executable code.

* [Synthesizing ARSC](docs/SYNTHESIZE_ARSC.md) - explains how to synthesize the ARSC design for Altera FPGA's and gives suggestions
of what has to be modified to make ARSC compile for FPGAs produced by other manufacturers.

* [ARSC Hardware Platform](docs/ARSC_HW_PLATFORM.md) - describes the ARSC system architecture and hardware design in detail. This document
us intended to those who wishes to understand the ARSC from the hardware design point of view, and those who wish to experiment and modify
the ARSC hardware platform.

* [Performance Evaluation](PERFORMANCE_EVALUATION.md) - gives summary of the performance evaluation for the ARSC system.

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
sucessfully ran the ARSC system on a FPGA board not listed here. Currently tested FPGAs:

* Altera DE0-CV (Cyclone V)
