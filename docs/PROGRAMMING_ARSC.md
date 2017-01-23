# ARSC Organization and Programming Guide

ARSC is a 16-bit, accumulator-based computer system. This document represents a *ARSC programming guide* that aims to give enough
details on ARSC internals and organization to start writting ARSC assembly programs. The following topics are covered: basic introduction
to the ARSC main memory, register file, instruction format, instruction set architecture, address modes, ARSC I/O and ARSC assembly
language. It is worthwhile stating that ARSC uses the *2's complement* number representation.

## Main Memory

ARSC word is 16-bits wide which means that ARSC can address no more than *2^16 = 64K* of memory. That means that the capacity of the
ARSC main memory is not larger than 64K x 16-bits. Furthermore, it is assumed that the memory is word-addressable (as opposed to
byte-addressable memory). In other words, ARSC doesn't allow access to individual bytes of the 2-bytes word. All read/write operations
are done on the level of words and an address refers to the exact memory word that is being accessed.

## Register File

ARSC contains the following set of registers:

* *Accumulator Register* (ACC) - used in all arithmetic and logic operations and, as its name implies, it accumulates the result of
these operations.
* *Program Counter* (PC) - contains the address of the instruction to be fetched and executed next. This register is usually incremented
by the control unit to point to the next instruction. However, branching might set PC to any address in the memory.
* *Instruction Register* (IR) - before it is decoded and executed, an instruction is fetched into the IR register.
* *Universal Address Register* (UAR) - holds the memory/IO address during memory/IO read/write operations.
* *Universal Buffer Register* (UBR) - holds the data to be written to the memory/output device during the memory/IO write operation.
* *Index registers* (1, 2 and 3) - these registers are used for address manipulation and enable the so-called indexed addressing. Refer
to [Indexed Addressing](#indexed-addressing) for more information.
* *Processor Status Register* (PSR) - 5-bit status register whose bits represent (from MSB to LSB) *carry* (CR), *negative* (NG), *zero*
(ZR), *overflow* (OF) and *interrupt enable* (IR).

PC, IR, UAR, UBR and PSR are CPU internal registers and their contents cannot be accessed directly by the ARSC programmer. However,
contents of the PC register can be set by using the branching instructions.

## Instruction Format

The ARSC instruction is 16-bits wide and its format is presented in the following table:

| Opcode         | indirect/IO device bit | Index flag  |  Address        |
|:--------------:|:----------------------:|:-----------:|----------------:|
| 15 14 13 12 11 | 10                     | 9 8         | 7 6 5 4 3 2 1 0 |

Bits 15 to 11 represent the instruction opcode that identifies a unique operation that can be performed by the ARSC CPU. As opcode is
5-bits wide, ARSC can have at most *2^5 = 32* instructions. Refer to the [Instruction Set](#instruction-set) for more information
about the ARSC ISA.

Bit 10 is the indirect bit for one-address instructions which enables the so called [Indirect Addressing](#indirect-addressing). For
I/O instructions bit 10 is the I/O device identifier, which means that ARSC supports maximum of 2 input and 2 output devices.

Bits 9 and 8 are the index flag that select one of the three index registers when index addressing is used. The following table
illustrates all the possible index register selections:

| Bit 9  | Bit 8  | Selected Index Register |
|:-------|:-------|:-----------------------:|
| 0      | 0      | None                    |
| 0      | 1      | 1                       |
| 1      | 0      | 2                       |
| 1      | 1      | 3                       |

Bits 7 to 0 represent the memory address for those instructions that access the memory. With only 8-bits in the instruction format
dedicated to the memory address, ARSC can directly address only first 256 memory locations (from 0 to 255). To overcome this limitation,
indexed and indirect addressing modes are supported. For more information refer to [Addressing Modes](#addressing-modes).

## Instruction Set

The table below summarizes all the instructions supported by the ARSC CPU:

| Mnemonic      | Opcode (hexadecimal) | Description                                                                    |
|:-------------:|:--------------------:|:-------------------------------------------------------------------------------|
| HLT           | 0                    | Stops the CPU from fetching the next instruction                               |
| LDA           | 1                    | Loads ACC with data from the memory address                                    |
| STA           | 2                    | Stores ACC to the memory address                                               |
| ADD           | 3                    | Adds contents of the memory location to ACC                                    |
| TCA           | 4                    | Computes 2's complement of the ACC                                             |
| BRU           | 5                    | Uncoditionally branches to the memory address                                  |
| BIP           | 6                    | Branches to the memory address if ACC > 0                                      |
| BIN           | 7                    | Branches to the memory address if ACC < 0                                      |
| RWD           | 8                    | Reads a data word from the input device to ACC                                 |
| WWD           | 9                    | Writes the contents of ACC to the output device                                |
| SHL           | A                    | Left-shift the contents of the ACC                                             |
| SHR           | B                    | Right-shifts the contents of the ACC                                           |
| LDX           | C                    | Loads the specified index register with data from memory address               |
| STX           | D                    | Stores the contents of the index register to the memory address                |
| TIX           | E                    | Increments the index register and branches to the address if ACC = 0           |
| TDX           | F                    | Decrements the index register and branches to the address if ACC != 0          |
| AND           | 10                   | Computes bit AND operation between ACC and the contents of the memory location |
| OR            | 11                   | Computes bit OR operation between ACC and the contents of the memory location  |
| NOT           | 12                   | Complements the ACC                                                            |
| XOR           | 13                   | Computes bit XOR operation between ACC and the contents of the memory location |

The ARSC instructions can be classified into three separate groups:

* *Zero-Address* (HLT, TCA, SHL, SHR, NOT)
* *One-Address* (LDA, STA, ADD, BRU, BIP, BIN, LDX, STX, TIX, TDX, AND, OR, XOR)
* *I/O Instructions* (RWD, WWD)

### Zero-Address Instructions

These instructions have no operand field and the opcode represents the entire instruction. The operand is assumed to be in the ACC if
the instruction expects one. The other fields (indirect/IO device, index flag and address) are not used.

#### HLT

```
HLT   // Stop the execution
```

HLT instruction stops the CPU from fetching and executing the next instruction. In other words, HLT instruction represents the logical
end of the program. The ARSC assembly language **mandates** that the instruction memory segment must terminate with the HLT instruction.
In this way, it will never happen that CPU proceeds to execute the data from the data memory segment.

#### TCA

```
TCA   // ACC <-- ACC' + 1
```

Computes the 2's complement of the contents of ACC and writes the result back to ACC. Internally, the 2's complement is computed by
first complementing the contents of ACC and then adding 1 to the complement.

#### SHL

```
SHL   // ACC <-- ACC << 1
```

SHL instruction left-shifts the contents of the ACC by one bit and writes the result back to ACC. The MSB bit is lost and zero is
shifted in to the LSB. SHL instruction may lead to setting the overflow bit of the PSR register in case the sign of the result has
changed.

#### SHR

```
SHR   // ACC[14:0] <-- ACC[15:1]
      // ACC[15]   <-- ACC[15]
```

SHR instruction right-shifts the contents of the ACC by one bit, keeping the MSB bit unchaged. The LSB bit is lost.

#### NOT

```
NOT   // ACC <-- ACC'
```

Complements the contents of the ACC and writes the result back to ACC.

### One-Address Instructions

These instructions require an address operand in the instruction word. In the following description, *M* represents the main memory
and *A* is a symbolic address of an arbitrary memory location. An *absolute address* is the actual physical address of the memory
location, expressed as a numeric literal. Symbolic address is translated to the absolute address during the assembly process. For
simplicity, the description of one-address instructions will assume that direct addressing mode is used, in which MEM is the
*effective address* of the operand. In real ARSC programs, the direct address is often modified by indexing and/or indirecting to
compute the effective address.

#### LDA

```
LDA A   // ACC <-- M[A]
```

Loads the ACC with the contents of the memory location *A*.

#### STA

```
STA A   // M[A] <-- ACC
```

Stores the contents of the ACC to the memory location *A*.

#### ADD

```
ADD A   // ACC <-- ACC + M[A]
```

Adds the contents of the memory location *A* to the contents of ACC.

#### BRU

```
BRU A   // PC <-- A
```

Unconditionally branches (sets PC to new address) to the memory location *A*. In other words, the next instruction to be fetched and
executed is at address *A*.

#### BIP

```
BIP A   // IF ACC > 0:
        //    PC <-- A
```

Branches to the memory location *A* if the contents of ACC is positive. Internally, the bits NG and ZR of the PSR register are checked,
and branching is performed if both of those bits are zero.

#### BIN

```
BIP A   // IF ACC < 0:
        //    PC <-- A
```

Branches to the memory location *A* if the contents of ACC is negative. Internally, the NG bit of PSR register is checked, and if it
is one the branching happens.

#### LDX

```
LDX A,INDEX   // INDEX <-- M[A]
```

Loads the index register selected with INDEX (may be 1, 2 or 3) with the contents of memory location *A*.

#### STX

```
STX A,INDEX   // M[A] <-- INDEX
```

Stores the index register selected with INDEX (1, 2 or 3) to the memory location *A*.

#### TIX

```
TIX A,INDEX   // INDEX <-- INDEX + 1
              // IF INDEX = 0:
              //    PC <-- A
```

TIX firstly increments the selected index register and then if the index register is equal to zero it branches to instruction at
the memory location *A*. Otherwise, the next in-order instruction is executed.

#### TDX

```
TDX A,INDEX   // INDEX <-- INDEX - 1
              // IF INDEX != 0:
              //    PC <-- A
```

Decrements the selected index register and if it is not equal to zero it branches to the memory location *A*. Otherwise, the next
in-order instruction is executed.

#### AND

```
AND A   // ACC <-- ACC & M[A]
```

Performs the bit AND operation between the contents of the memory location *A* and the contents of ACC, and writes the result back
to ACC.

#### OR

```
OR A   // ACC <-- ACC | M[A]
```

Performs the bit OR operation between the contents of the memory location *A* and the contents of ACC, and writes the result back
to ACC.

#### XOR

```
XOR A   // ACC <-- ACC ^ M[A]
```

Performs the bit XOR operation between the contents of the memory location *A* and the contents of ACC, and writes the result back
to ACC.

### I/O Instructions

I/O instructions require the address operand as well, which means that these are also one-address instructions. However, these
instruction are special because they require the I/O device identifier to be able to determine which I/O devices will be read/written.
Refer to [ARSC I/O](#arsc-io) for more details on the ARSC input/output.

#### RWD

```
RWD { IN_DEV } A  // ACC <-- IN_DEV[ M[A] ]
```

RWD (read word) instruction reads one word of data from the input device IN_DEV (must be 0 or 1) and stores it to the ACC. Note that
this instruction also requires the address operand. This is required to support so-called memory-mapped I/O devices, that require an
address when reading the data from or writing the data to the device. An example of a memory-mapped device in ARSC system is the VGA
screen. ARSC CPU treats the VGA screen as a memory device and it reads/writes this device just like it does the main memory. Thus, in
order to read/write the memory mapped devices the address has to be provided. Refer to [ARSC I/O](#arsc-io) for more details.

#### WWD

```
WWD { OUT_DEV } A  // OUT_DEV[ M[A] ] <-- ACC
```

Writes the contents of the ACC to the output device OUT_DEV at the specified I/O address. Note that I/O address is read from the memory
location *A* (just like ADD instruction is reading the operand from the memory location).

## Addressing Modes

ARSC supports the following addressing modes: *direct addressing*, *indexed addressing*, *indirect addressing* and *pre-indexed
indirect addressing*. Effective address is the actual memory location where the operand is located (after specific addressing has
been applied).

### Direct Addressing

An example:
```
ADD A
```

Assume that the symbolic address *A* gets translated to physical location 100 during the assembly process:
```
Effective address:  100
Effect:             ACC <-- ACC + M[100]
```

In the case of direct addressing, the address field represents the effective address of the operand. As address field is only 8-bits
wide, this means that ARSC can directly address only first 256 memory location (0 to 255).

### Indexed Addressing

An example:
```
ADD A,3
```

Assume that the symbolic address *A* gets translated to physical location 100 during the assembly process:
```
Effective address:  100 + index register 3
Effect:             ADD <-- ADD + M[100 + index register 3]
```

The numeric literal that appears after the comma in the operand field denotes the selected index register. As mentioned earlier, this
can be 1, 2 or 3 (if ommitted it is assumed that no index register is selected). The effective address is computed by adding the
contents of the selected index register to the direct address (*A* or 100 in this case). The address field of the instruction refers
to *A* which is the base address, and the contents of the index register is an offset from *A*. The contents of selected index register
can be modified via LDX, TIX and TDX instruction, so one can access various consecutive memory locations by simply changing the contents
of a index register.

As index registers are 16-bits wide, indexed addressing effectively expands the addressing space from 256 locations (with direct
addressing) to 64K. There are several usecases where indexed addressing comes in handy. One is implementing an efficient looping
mechanism. Consider the following example:

```
  LDX MINUS_TEN,1

LOOP:
  TIX LOOP_END,1
  // Do something useful
  BRU LOOP

LOOP_END:
```

The previous code segment implements the single loop using the TIX instruction. Recall that the TIX instruction branches if ACC is zero.
While loops can be implemented with other branching instructions, these approaches will be slower because they involve memory access
(read and write) that is not needed in this implementation. Index register are CPU internal registers and read/write operations on them
are very fast, thus making this looping mechanism very efficient.

The other usecase where indexed addressing can be useful is iteration over arrays. To iterate over an array, one can set the address
field to point to the first element, and then increment the index register to access the subsequent array elements. Indexed addressing
may be used for all one-address and I/O instructions expect LDX, STX, TIX and TDX. These instruction internally reference the index
registers and thus this addressing mode cannot be used. For instance:

```
LDA Z,1   // Adds the contents of index register 1 to Z to compute the effective address, and then loads data from that address to ACC
LDX Z,1   // Loads the contents of Z to the index register 1
```

Allowing indexed addressing for such instructions would be confusing as they use these registers for other purposes.

### Indirect Addressing

An example:
```
ADD *A
```

Assume that the symbolic address *A* gets translated to physical location 100 during the assembly process:
```
Effective address:  M[100]
Effect:             ADD <-- ADD + M[ M[100] ]
```

The asterisk in front of the operand field in the instruction denotes that indirect addressing is to be used. In this addressing mode,
the memory location *A* contains the effective address of the operand. In other words, *A* points to the effective address where the
operand is located at. Since the memory words is 16-bits wide, the indirect addressing mode can also be used to extend the addressing
space to 64K.

Indirect addressing is allowed for all one-address instructions but not for I/O instructions. The reason is that the bit 10 is used
as an I/O device identifier in case of I/O instructions (RWD and WWD). Thus, these instructions cannot used indirect addressing.

### Pre-Indexed Indirect Addressing

An example:
```
ADD *A,2
```

Assume that the symbolic address *A* gets translated to physical location 100 during the assembly process:
```
Effective address:  M[100 + index register 2]
Effect:             ADD <-- ADD + M[ M[100 + index register 2] ]
```

Pre-indexed indirect addressing is a combination of the indexed and indirect addressing. The direct address is first indexed and the
indirection operation is then performed on this indexed address to compute the effective address. This addressing mode may not be used
with LDX, STX, TIX, TDX, RWD and WWD instructions. It can be used with other one-address instructions.

## ARSC I/O

ARSC supports up to 2 input and 2 output devices. Input devices are VGA screen and a keyboard, while VGA screen is currently only
output device. I/O devices are read/written using the RWD/WWD instruction, that require the I/O device identifier to be able to
determine which device should be accessed. The following two tables assign identifiers to all input/output devices.

| Input device | Identifier  |
|:------------:|:-----------:|
| VGA screen   | 0           |
| Keyboard     | 1           |

| Output device | Identifier |
|:-------------:|:----------:|
| VGA screen    | 0          |
| -             | -          |

The data to be written to the output device must be stored to the ACC before the WWD instruction occurs. The data is read from the
input device to the ACC in the case of RWD instruction. Previous ACC contents are overwritten, thus ACC contents should be written
to the memory before RWD instruction is executed if it needs to be preserved.

It may seem strange that VGA screen is considered to be both input and output device, however note that besides writing to the screen
it is also possible to read the screen and obtain the current pixel data (expression *read/write the screen* is a bit misleading,
because what is actually being read/written is the video memory and not the screen).

### VGA screen

ARSC system features a *640x480* pixels VGA screen with 3-bit color depth (1-bit for red, green and blue). Thus, ARSC can display
*2^3 = 8* different colors for each pixel. All the colors are listed in the following table:

| Red     | Green    | Blue   | Resulting color |
|:-------:|:--------:|:------:|:---------------:|
| 0       | 0        | 0      | black           |
| 0       | 0        | 1      | blue            |
| 0       | 1        | 0      | green           |
| 0       | 1        | 1      | cyan            |
| 1       | 0        | 0      | red             |
| 1       | 0        | 1      | magenta         |
| 1       | 1        | 0      | yellow          |
| 1       | 1        | 1      | white           |

The pixel data is stored in the *video memory*. Video memory must be large enough to store the data for *640x480 = 307200* pixels.
Video memory must be organized in a way that ARSC CPU, with its 16-bit word width, can address every word. With this in mind, note
that 5 3-bit pixels can fit into the 16-bit word. For example, this is how first 5 pixels of the screen would fit into the 16-bit word:

| MSB | Pixel 4  | Pixel 3  | Pixel 2  | Pixel 1  | Pixel 0  |
|:---:|:--------:|:--------:|:--------:|:--------:|:--------:|
| 15  | 14 13 12 | 11 10 9  | 8 7 6    | 5 4 3    | 2 1 0    |

And the following table illustrates how first 20 pixels are organized in the video memory (Px(i,j) - *i* and *j* are pixel coordinates,
row and column respectively):

| MSB | Pixel 4   | Pixel 3   | Pixel 2   | Pixel 1  | Pixel 0  |
|:---:|:----------|:----------|:----------|:---------|:---------|
| -   | Px(0,4)   | Px(0,3)   | Px(0,2)   | Px(0,1)  | Px(0,0)  |
| -   | Px(0,9)   | Px(0,8)   | Px(0,7)   | Px(0,6)  | Px(0,5)  |
| -   | Px(0,14)  | Px(0,13)  | Px(0,12)  | Px(0,11) | Px(0,10) |
| -   | Px(0,19)  | Px(0,18)  | Px(0,17)  | Px(0,16) | Px(0,15) |

The MSB bit of the word is unused. If there was be only one pixel per 16-bit word, video memory would be *307200 x 16-bits*. As there
are 5 pixels per 16-bit word, the video memory is organized as:

*(307200/5) x 16-bits* = 61440 x 16-bits*.

which is less than 64K meaning that ARSC CPU can draw the entire screen. Total capacity of the ARSC video memory is *122880 B*.

#### Pixel Coordinates to Video Memory Address

I/O instructions accept the I/O address that is used for reading/writing memory mapped I/O devices. This means that one cannot simply
use the pixel coordinates *(x, y)* to read/write the pixel of data. These pixel coordinates must be translated to the video memory
address to be used for reading/writing the video memory.

Assume that coordinates of the pixel to be accessed are (x, y). If there was one pixel per video memory word, the memory address would
be: address = 640*y + x. As each video memory word contains 5 pixels, the memory address of the pixel (x, y) is:

address = (640*y / y) / 5.

The quotient is the video memory address and the remainder is the offset of the pixel within a single word. However, this 640*x
multiplication might lead to overflow: y can have any value from 0 to 479 so for example 640*400 = 256000 > 65535, where 65535 is
the largest unsigned integer representable by 16-bits. Fortunately, the address calculation expression can be simplified in the
following way:

address = (640*y / y) / 5 = 128*y + x/5 = (y << 7) + x/5.

Note the trick that multiplying with the power of 2 is the same as right shifting the value by the *power* number of bits in the
binary. The sum of *(y << 7)* and the quotient of *x/5* is the video memory address of the pixel and the remainder of *x/y* is the
pixel offset.

In order to write a single pixel in the video memory word, the entire memory word has to be read (RWD instruction) and then the
new pixel data has to be combined with the pixel mask and the previous pixel data to obtain the new video memory word with the
given pixel color updated. For an example of a drawing program that uses the described technique for calculating the video memory
address from pixel coordiantes as well as the masking technique for drawing a single pixel check the
[bouncing_square_test.asm](../assembler/test/bouncing_square_test.asm).

#### More Efficient Way to Draw

The previous section described how to compute the video memory address for the arbitrary pixel coordinates (x, y). While this is
sometimes necessary, it is painfuly slow because of the division operation *x/5*. ARSC currently doesn't support the division operation
in hardware, which means that it would have to be emulated in software and this would have significant negative impact on the
performance.

Fortunately, in many situations the video memory address for the pixel can be computed in a much simplier way. Assume that the inital
pixel coordinates are known, then one can also pre-calculate the video memory address for these coordinates. As long as the object
being drawn moves linearly it is quite easy to calculate the change in the video memory address for the pixels without re-calculating
the expression from the previous section. This idea is implemented in the
[bouncing_square_nodiv_test.asm](../assembler/test/bouncing_square_nodiv_test.asm) program that does implements the same drawing
program as [bouncing_square_test.asm](../assembler/test/bouncing_square_test.asm) but without evaluating the expression from the
previous section.

### Keyboard

Fill this secton.............

## ARSC Assembly

Most of the executable part of ARSC assembly language has been presented in the [Instruction Set](#instruction-set) section. This
section covers the ARSC assembly directives and general rules in writing ARSC assembly programs. The ARSC assembly contains two
classes of instructions: an *executable instruction* and an *assembler directive*. ARSC assembly is case-sensitive and all assembly
instructions (executable and directive) are written in ***uppercase***.

Symbols in ARSC assembly all use the same naming rules - the valid symbol name is any sequence of alphanumeric characters and an
underscore that begins with a uppercase or lowercase letter or an underscore. This rule applies to all of the following: symbolic
addresses, [labels](#label), [BSS symbols](#bss), [BSC symbols](#bsc) and [ALIAS symbols](#alias).

Wherever the numeric literal is expected, it may be provided in decimal or hexadecimal format. The hexadecimal numbers must be written
with the *0x* prefix. There is not exception to this rule: only decimal numbers are allowed when specifying the INDEX register in case
of indexed addressing.

### Executable Instructions

As shown in [#Instruction Set](instruction-set) section, the general format of the executable assembly instruction is:

```
MNEMONIC *ADDRESS,INDEX
```

*ADDRESS* may be a decimal or hexadecimal numeric literal or a symbol that will be resolved during the assembly process. Note,
however, that every such symbol appearing in the address field of executable instruction must be defined via [BSS](#bss), [BSC](#bsc)
or [ALIAS](#alias) directive. Failing to do so will result in an *undefined symbol* error during the assembly process.

Valid values for INDEX field are 1, 2 and 3. To select no index register simply omit the INDEX field (in that case comma before the
INDEX must be removed).

### Labels

A label is a symbolic name representing the memory location where the instruction is located. Labels are used in branching instructions,
to provide the destination address for the branch. A label statement has the following format:

```
LABEL_1:
```

### BSS

*Block storage starting* directive is used to allocate a block of consecutive memory locations. Its syntax is:

```
AN_ARRAY BSS 10
```

This directive reserves 10 memory locations and sets AN_ARRAY symbol to point to the first memory location in this sequence. The
BSS directive operand must always be a positive decimal or hexadecimal integer number. Contents of the memory locations are undefined.

### BSC

*Block storage constants* directive gives a way of storing constants in the memory locations besides reserving those locations. Its
syntax is:

```
C BSC 2, -5, 4567
```

The previous BSC directive reserves 3 memory locations: C containing 2, C + 1 containing -5 and C + 2 containing 4567.

### ALIAS

*ALIAS* directive gives ability to create aliases for memory locations and symbols or even arithmetic expressions involving symbols.
Several examples of ALIAST directive:

```
B ALIAS A         // B is another name for A (A must already be defined)
B ALIAS A + 10    // B is the name for location A + 10
B ALIAS 56        // B is another name for memory location 56
```

Note that unlike BSS and BSC directives, the ALIAS directive doesn't reserve the memory location. It only creates a reference to it
so that assembler will replace any occurence of the alias symbol with the physical memory address during the assembly process.

### END

Marks the end of the assembly program. The *END* directive must appear as the last assembly command and all content of the file after
this directive is ignored by the assembler. Its syntax:

```
END
```

### Comments

The comments start with *//* and continue until the end of the line. An example of a comment:

```
// Entire line is a comment
LDA A,1   // This is a very important instruction
```