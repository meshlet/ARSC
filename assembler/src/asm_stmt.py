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

import re

# ARSC ISA along with the 5-bit opcode (stored as 1-byte, however most
# significant 3 bits will not end up in the instruction)
ISA = dict(
    HLT     = 0x00
    , LDA   = 0x01
    , STA   = 0x02
    , ADD   = 0x03
    , TCA   = 0x04
    , BRU   = 0x05
    , BIP   = 0x06
    , BIN   = 0x07
    , RWD   = 0x08
    , WWD   = 0x09
    , SHL   = 0x0A
    , SHR   = 0x0B
    , LDX   = 0x0C
    , STX   = 0x0D
    , TIX   = 0x0E
    , TDX   = 0x0F
    , AND   = 0x10
    , OR    = 0x11
    , NOT   = 0x12
    , XOR   = 0x13
)

DirectiveType = type('DirectiveType'
                 , ()
                 , dict(ANCHOR=0, ALIAS=1, BSS=2, BSC=3, END=4))

# Supported ARSC assembly directives
DIRS = dict(
    ANCHOR      = DirectiveType.ANCHOR
    , ALIAS     = DirectiveType.ALIAS
    , BSS       = DirectiveType.BSS
    , BSC       = DirectiveType.BSC
    , END       = DirectiveType.END
)


# Identifier names may be any sequence of letters, digits and underscore
# that doesn't start with a digit
def is_valid_name(identifier):
    match = re.search('\A[a-zA-Z_][a-zA-Z_0-9]*\Z', identifier)
    return match is not None


# Represents an ARSC instruction (i.e. LDA *Z, 2) and all its components:
# mnemonic (i.e. LDA), is_indirect flag (star '*' indicates indirect
# addressing), address (a decimal or hexadecimal string or a variable name)
# and index (an empty string, 0, 1, 2 or 3)
class AsmInstruction:
    def __init__(self
                 , mnemonic
                 , indirect_or_iodev_bit
                 , address
                 , index
                 , stmt_str = None):

        if type(mnemonic) is not str:
            raise TypeError('mnemonic must be a string')
        elif address is not None and type(address) is not str:
            raise TypeError('address must be a string')
        elif index is not None and type(index) is not str:
            raise TypeError('index must be a string')

        # Validate mnemonic
        self.Opcode = ISA.get(mnemonic, None)
        if self.Opcode is None:
            raise SyntaxError('unrecognized mnemonic "%s"' % mnemonic)

        self.Mnemonic = mnemonic
        self.StmtString = stmt_str

        # Handle zero-address instructions
        if mnemonic in ['TCA', 'SHL', 'SHR', 'HLT']:
            if (indirect_or_iodev_bit, address, index) != (None, None, None):
                raise SyntaxError('instruction "%s" expects no arguments' % mnemonic)

            self.HasAbsoluteAddress = True
            self.IndirectOrIODeviceBit = 0
            self.Address = 0
            self.Index = 0
            return

        # Validate address
        if address is None:
            raise SyntaxError('instruction "%s" expects an address' % mnemonic)
        elif is_valid_name(address):
            self.Address = address
            self.HasAbsoluteAddress = False
        else:
            try:
                self.Address = int(address, 0)
                if self.Address < 0:
                    raise SyntaxError

                self.HasAbsoluteAddress = True
            except:
                raise SyntaxError('invalid address "%s"' % address)

        # Validate index
        if index is None:
            if mnemonic in ['LDX', 'STX', 'TIX', 'TDX'] and index not in ['1', '2', '3']:
                raise SyntaxError('index is mandatory for instruction "%s"' % mnemonic)
            else:
                self.Index = 0;
        else:
            try:
                self.Index = int(index, 10)
                if self.Index not in range(1, 4):
                    raise SyntaxError
            except:
                raise SyntaxError('invalid index register "%s"' % str(index))

        if indirect_or_iodev_bit is None:
            if mnemonic in ['RWD', 'WWD']:
                raise SyntaxError('I/O device ID must be provided in "%s" instruction' % mnemonic)
            else:
                self.IndirectOrIODeviceBit = 0
        else:
            try:
                self.IndirectOrIODeviceBit = int(indirect_or_iodev_bit, 10)
                if self.IndirectOrIODeviceBit not in range(0, 2):
                    raise SyntaxError
            except:
                if mnemonic in ['RWD', 'WWD']:
                    raise SyntaxError('invalid I/O device ID "%s" in instruction "%s"' % (str(indirect_or_iodev_bit), mnemonic))
                else:
                    raise SyntaxError('invalid indirect bit "s" in instruction "%s"' % (str(indirect_or_iodev_bit), mnemonic))


# Represents the ARSC assembler directive (i.e. ANCHOR or BSS). As the number
# and meaning of the arguments depend on the directive, they are stored as
# an array of args
class AsmDirective:
    def __init__(self, directive, args):
        if type(directive) is not str:
            raise TypeError('mnemonic must be a string')
        elif args is not None and type(args) is not list:
            raise TypeError('args must be a list')

        self.Directive = directive
        self.DirType = DIRS[directive]

        # Validate arguments
        if self.DirType == DirectiveType.ANCHOR:
            try:
                self.AbsAddress = int(args[0], 0)
                if self.AbsAddress < 0:
                    raise SyntaxError
            except:
                raise SyntaxError('invalid argument "%s" for directive "%s"' % (args[0], directive))

        elif self.DirType == DirectiveType.END:
            return
        else:
            if not is_valid_name(args[0]):
                raise SyntaxError(
                        '"%s" is not valid left-hand side for directive "%s". Valid identifier expected' %
                        (args[0], directive))

            if self.DirType == DirectiveType.ALIAS:
                self.AliasSymbol = args[0]
                if is_valid_name(args[1]):
                    self.OriginalSymbol = args[1]
                else:
                    try:
                        self.AbsAddress = int(args[1], 0)
                    except:
                        # Finally check if arg 1 is an expression in form A+INT or A-INT
                        match = re.search('\A([a-zA-Z_][a-zA-Z_0-9]*)(\+|-)([0-9]+|0x[0-9a-fA-F])\Z', args[1])
                        if match is None or len(match.groups()) != 3:
                            raise SyntaxError(
                                '"%s" is not a valid right-hand side for the directive "%s"' %
                                (args[1], directive))

                        self.BaseSymbol = match.group(1)
                        self.Operator = match.group(2)
                        self.Offset = int(match.group(3), 0)

                    if hasattr(self, 'AbsAddress') and self.AbsAddress < 0:
                        raise SyntaxError('directive "%s" expects a positive absolute address' % directive)

            elif self.DirType == DirectiveType.BSS:
                self.VariableSymbol = args[0]
                try:
                    # Number of words to allocate in this BSS
                    self.AllocSize = int(args[1], 0)
                    if self.AllocSize <= 0:
                        raise SyntaxError('"%s" directive expects a positive allocation size' % directive)
                except TypeError:
                    raise SyntaxError('character string "%s" is not a valid allocation size' % args[1])
                except ValueError:
                    raise SyntaxError('character string "%s" is not a valid allocation size' % args[1])

            else: # BSC
                self.ConstantSymbol = args[0]
                self.Constants = []
                for i in range(1, len(args)):
                    try:
                        self.Constants.append(int(args[i]))
                    except:
                        if (is_valid_name(args[i])):
                            raise SyntaxError(
                                '"%s" is not an integer literal as required by the "%s" directive' %
                                (args[i], directive))
                        else:
                            raise SyntaxError('argument list contains unexpected character string "%s"' % args[i])


# Label instruction (i.e. ALABEL:)
class AsmLabel:
    def __init__(self, label):
        if type(label) is not str:
            raise TypeError('label must be a string')
        elif not is_valid_name(label):
            raise SyntaxError('"%s" is not a valid label name' % label)

        self.Label = label
