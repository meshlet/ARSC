# ==============================================================================
# ARSC (A Relatively Simple Computer) License
# ==============================================================================
# 
# ARSC is distributed under the following BSD-style license:
# 
# Copyright (c) 2016-2017 Dzanan Bajgoric
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, this
#    list of conditions and the following disclaimer in the documentation and/or other
#    materials provided with the distribution.
# 
# 3. The name of the author may not be used to endorse or promote products derived from
#    this product without specific prior written permission from the author.
# 
# 4. Products derived from this product may not be called "ARSC" nor may "ARSC" appear
#    in their names without specific prior written permission from the author.
# 
# THIS PRODUCT IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS PRODUCT, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# PART OF THE ARSC ASSEMBLER
#
from binascii import hexlify

# The base class for code generators
class BaseGenerator:
    def on_instruction(self, opcode, indirect_or_iodev_bit, index, address, stmt_str = None):
        raise NotImplementedError
    def on_bss_directive(self, bss_stmt):
        raise NotImplementedError
    def on_bsc_directive(self, bsc_stmt):
        raise NotImplementedError
    def get_generated_code(self):
        raise NotImplementedError
    def on_finished(self):
        pass


# The pretty code generator that generates the human-readable, annotated code
class PrettyGenerator(BaseGenerator):
    def __init__(self):
        self.gen_code = ''
        self.curr_addr = 0

    def get_generated_code(self):
        return self.gen_code

    def on_instruction(self, opcode, indirect_or_iodev_bit, index, address, stmt_str = None):
        self.gen_code += (
            '0x'
            + format(self.curr_addr, '04x')
            + ':\t'
            + format(opcode, '05b')
            + format(indirect_or_iodev_bit, '01b')
            + format(index, '02b')
            + format(address, '08b'))

        if stmt_str is not None:
            self.gen_code += '\t// ' + stmt_str.lstrip()

        self.gen_code += '\n'
        self.curr_addr += 1

    def on_bss_directive(self, bss_stmt):
        for i in range(0, bss_stmt.AllocSize):
            self.gen_code += (
                '0x'
                + format(self.curr_addr, '04x')
                + ':\t'
                + '0'.zfill(16)
                + '\t// '
                + bss_stmt.VariableSymbol
                + ' + '
                + str(i)
                + ' (BSS)'
                + '\n')

            self.curr_addr += 1

    def on_bsc_directive(self, bsc_stmt):
        i = 0
        for constant in bsc_stmt.Constants:
            self.gen_code += (
                '0x'
                + format(self.curr_addr, '04x')
                + ':\t')

            if constant >= 0:
                self.gen_code += format(constant, '016b')
            else:
                self.gen_code += bin(constant & 0b1111111111111111)[2:]

            self.gen_code += (
                '\t// '
                + bsc_stmt.ConstantSymbol
                + ' + '
                + str(i)
                + ' (BSC -> %d)' % constant
                + '\n')

            self.curr_addr += 1
            i += 1


# Binary generator that generates the executable (binary) ARSC code. 'get_hex_string'
# method may be used to obtain the hexadecimal ASCII representation of the binary
# data, where each byte is represented by two HEX digits. This HEX string can be
# stored in the .hex memory initialization file
class BinaryGenerator(BaseGenerator):
    def __init__(self):
        self.bin_data = bytearray()

    def get_generated_code(self):
        return self.bin_data

    def on_instruction(self, opcode, indirect_or_iodev_bit, index, address, stmt_str = None):
        self.bin_data.append(address)
        self.bin_data.append((opcode << 3) | (indirect_or_iodev_bit << 2) | index)

    def on_bss_directive(self, bss_stmt):
        for i in range(0, bss_stmt.AllocSize):
            self.bin_data.append(0)
            self.bin_data.append(0)

    def on_bsc_directive(self, bsc_stmt):
        for constant in bsc_stmt.Constants:
            self.bin_data.append(constant & 0xFF)
            self.bin_data.append((constant >> 8) & 0xFF)


# MIF generator produces an ASCII memory intialization string that can be used to
# create a .mif memory initialization file supported by most FPGA synthesis tools
# for CAM, RAM and ROM memory initialization
class MifGenerator(BinaryGenerator):
    def __init__(self):
        self.mif_data = ''
        BinaryGenerator.__init__(self)

    def on_finished(self):
        self.mif_data = 'WIDTH=16;\n'
        self.mif_data += 'DEPTH=%d;\n\n' % (len(self.bin_data) / 2)
        self.mif_data += 'ADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\n'
        self.mif_data += 'CONTENT BEGIN\n'

        address = 0
        for i in range(0, len(self.bin_data), 2):
            self.mif_data += '\t%s\t:\t%s%s;\n' %\
                             (format(address, '02x'), format(self.bin_data[i+1], '02x'), format(self.bin_data[i], '02x'))
            address += 1

        self.mif_data += 'END;\n'

    def get_generated_code(self):
        return self.mif_data


# Hexadecimal generator that produce the HEX string representation of the binary
# data (used to create a .hex memory initialization file)
class HexGenerator(BinaryGenerator):
    def __init__(self):
        self.hex_data = ''
        BaseGenerator.__init__(self)

    def on_finished(self):
        self.hex_data = hexlify(self.bin_data)

    def get_generated_code(self):
        return self.hex_data