# ARSC Assembler

ARSC assembler is a Python-based assembler designed to compile ARSC assembly programs into ARSC executable code. The ARSC assembler source
code is located [here](../assembler/src). [arsc_assembler.py](../assembler/src/arsc_assembler.py) is the top-level Python source use to
invoke the assembler. Below is a typical invocation command:

```
python arsc_assembler.py path_to_asm_file\test.asm path_to_output_dir\test.mif
```

By default, ARSC assembler generates the executable file in the **MIF** (memory initialization file) format, which is supported by most
FPGA synthesis software. The following is a list of all supported output formats:

* *MIF* (memory initialization file) - ASCI output format.
* *BIN* - binary executable file. This format may come in handy when loading the program and data into the external SDRAM.
* *HEX* - simple hexadecimal ASCI output format where each byte is represented via two hexadecimal digits.
* *PRETTY* - human-readable ASCI output format where each 16-bit instruction and data is written in binary with comments and line numbers. Can
be used to while getting familiar with ARSC system and its intruction set.

ARSC assembler also supports two destinations for the generated code:

* *FILE* - the generated code will be written to the file. Output file must be provided in the invocation command.
* *STD* - the generated code is written to standard output. Output file may be ommitted in this case.

Whenever in doubt, simply run the ARSC assembler with the -h switch:

```
python arsc_assembler.py -h
```