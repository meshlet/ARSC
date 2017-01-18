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
import os
from asm_parser import AsmParser, AsmParserObserver
from asm_stmt import DirectiveType
from symbol_table import SymbolTable
from code_generator import BaseGenerator, PrettyGenerator, BinaryGenerator, HexGenerator, MifGenerator
from binascii import hexlify

# Drives the first pass of the compilation during which all the labels,
# variable symbols, constant symbols and aliases are placed into the
# symbol table. Additionally, the syntax analysis is performed and in
# case of any errors the compilation is terminated
# FIXME: redefinition error should report the location (lineno) of the previous definition
# FIXME: the base address set with ANCHOR directive currently doesn't affect the ALIAS
# symbols. This must be fixed so that the actual physical address for the ALIAS is calculated
# based on the current base address (i.e. ANCHORED address). But how will this affect the
# ALIASES that point to other symbols? POSSIBLE SOLUTION: the offsetting is done only for
# aliases that are pointed to absolute addresses. If alias is pointed to another symbol or
# an expression including another symbol the offsetting is not done. This makes the behavior
# consistent: 1) the programmer can rely that alias to any physical address is offset by the
# currently set base address; 2) as long as symbols defined after the current BASE address has
# been set are used to define aliases, the offsetting is not needed (there's no much sense to
# define an alias to a symbol defined before the current BASE address has been set anyways)
class FirstPassDriver(AsmParserObserver):
    def __init__(self):
        self.base_addr = 0
        self.curr_addr = 0
        self.halt_reached = False
        self.end_reached = False
        self.sym_tbl = SymbolTable()

    def get_symbol_table(self):
        return self.sym_tbl

    def on_instruction(self, stmt):
        if self.halt_reached:
            raise SyntaxError('"%s" may not appear after the HLT instruction' % stmt.Mnemonic)
        elif stmt.Mnemonic == 'HLT':
            self.halt_reached = True

        self.curr_addr += 1
        return True

    def on_label(self, stmt):
        if self.halt_reached:
            raise SyntaxError('label definition may not appear after the HTL instruction')

        if self.sym_tbl.contains(stmt.Label):
            raise SyntaxError('redefinition of the label "%s"' % stmt.Label)

        self.sym_tbl.add_entry(stmt.Label, self.curr_addr)
        return True

    def on_directive(self, stmt):
        if stmt.DirType != DirectiveType.ANCHOR and not self.halt_reached:
            raise SyntaxError('HLT instruction expected')

        # If END is reached terminate the parsing process
        if stmt.DirType == DirectiveType.END:
            self.end_reached = True
            return False
        elif stmt.DirType == DirectiveType.ANCHOR:
            # FIXME: disabled until I figure out how exactly the behaviour should be like
            #self.base_addr = stmt.AbsAddress
            #self.curr_addr = stmt.AbsAddress
            raise SyntaxError('directive "%s" is not yet supported' % stmt.Directive)
        elif stmt.DirType == DirectiveType.ALIAS:
            if self.sym_tbl.contains(stmt.AliasSymbol):
                raise SyntaxError('redefinition of the symbol "%s"' % stmt.AliasSymbol)

            address = None
            if hasattr(stmt, 'OriginalSymbol'):
                if not self.sym_tbl.contains(stmt.OriginalSymbol):
                    raise SyntaxError(
                        'cannot define an alias for an unknown symbol "%s"' %
                        stmt.OriginalSymbol)

                address = self.sym_tbl.get_address(stmt.OriginalSymbol)

            elif hasattr(stmt, 'AbsAddress'):
                address = stmt.AbsAddress
            else:
                # FIXME: allow aliases with expression where both operands are symbols
                if not self.sym_tbl.contains(stmt.BaseSymbol):
                    raise SyntaxError(
                        'cannot define an alias for an expression with an unknown symbol "%s"' %
                        stmt.BaseSymbol)

                if stmt.Operator == '+':
                    address = self.sym_tbl.get_address(stmt.BaseSymbol) + stmt.Offset
                else:
                    address = self.sym_tbl.get_address(stmt.BaseSymbol) - stmt.Offset
                    if address < 0:
                        raise SyntaxError(
                            'target address for alias "%s" evaluates to a negative number "%s"' %
                            (stmt.AliasSymbol, str(address)))

            self.sym_tbl.add_entry(stmt.AliasSymbol, address)

        elif stmt.DirType == DirectiveType.BSS:
            # FIXME: allow BSS directive where allocation size is a known BSC constant
            if self.sym_tbl.contains(stmt.VariableSymbol):
                raise SyntaxError('redefinition of the symbol "%s"' % stmt.VariableSymbol)

            self.sym_tbl.add_entry(stmt.VariableSymbol, self.curr_addr)
            self.curr_addr += stmt.AllocSize

        else:
            # BSC
            # FIXME: allow BSC directive where literal is a known BCS constant
            if self.sym_tbl.contains(stmt.ConstantSymbol):
                raise SyntaxError('redefinition of the symbol "%s"' % stmt.ConstantSymbol)

            self.sym_tbl.add_entry(stmt.ConstantSymbol, self.curr_addr)
            self.curr_addr += len(stmt.Constants)

        return True

    def on_finished(self):
        if not self.halt_reached:
            raise SyntaxError('HLT instruction expected')
        elif not self.end_reached:
            raise SyntaxError('END directive expected')


# FIXME: each constant must be in range [-32768, 32767]
# FIXME: no address may exceed 2^16 - 1 = 65535
class SecondPassDriver(AsmParserObserver):
    def __init__(self, sym_tbl, generators):
        if not isinstance(sym_tbl, SymbolTable):
            raise RuntimeError('sym_tbl must be an instance of SymbolTable')
        if not isinstance(generators, tuple):
            raise RuntimeError('generators must be an instance of tuple')
        if len(generators) == 0:
            raise RuntimeError('generators tuple must have at least one generator')
        for generator in generators:
            if not isinstance(generator, BaseGenerator):
                raise RuntimeError('each generators\' item must be an instance of BaseGenerator')

        self.sym_tbl = sym_tbl
        self.generators = generators

    def on_instruction(self, stmt):
        if stmt.HasAbsoluteAddress:
            physical_addr = stmt.Address
        elif not self.sym_tbl.contains(stmt.Address):
            raise SyntaxError('undefined variable "%s"' % stmt.Address)
        else:
            physical_addr = self.sym_tbl.get_address(stmt.Address)
            if physical_addr > 255:
                raise SyntaxError(
                    'physical address (%s) of the symbol "%s" is out of bounds (0-255)' %
                    (str(physical_addr), stmt.Address))

        for generator in self.generators:
            generator.on_instruction(
                stmt.Opcode
                , stmt.IndirectOrIODeviceBit
                , stmt.Index
                , physical_addr
                , stmt.StmtString)

        return True

    def on_label(self, stmt):
        return True

    def on_directive(self, stmt):
        if stmt.DirType == DirectiveType.BSS:
            for generator in self.generators:
                generator.on_bss_directive(stmt)
        elif stmt.DirType == DirectiveType.BSC:
            for generator in self.generators:
                generator.on_bsc_directive(stmt)

        return True

    def on_finished(self):
        for generator in self.generators:
            generator.on_finished()


# Drives the overall two-pass compilation process
class CompilerEngine:
    def __init__(self, src_filename, dest_filename, out_format):
        self.src_filename = src_filename
        self.dest_filename = dest_filename
        self.out_format = out_format
        self.generator = None
        self.compilation_done = False

    def run(self):
        self.compilation_done = False
        parser = AsmParser(self.src_filename)
        if self.out_format == 'PRETTY':
            self.generator = PrettyGenerator()
        elif self.out_format == 'MIF':
            self.generator = MifGenerator()
        elif self.out_format == 'HEX':
            self.generator = HexGenerator()
        else:
            self.generator = BinaryGenerator()

        # First pass
        first_pass_driver = FirstPassDriver()
        parser.parse(first_pass_driver)

        # Second pass
        second_pass_driver = SecondPassDriver(first_pass_driver.get_symbol_table(), tuple([self.generator]))
        parser.iterate(second_pass_driver)

        self.compilation_done = True

    def write(self):
        if not self.compilation_done:
            raise RuntimeError('compilation has not been completed yet')
        try:
            if self.out_format in ['PRETTY', 'HEX', 'MIF']:
                mode = 'w'
            else:
                mode = 'wb'

            with open(self.dest_filename, mode) as dest_file:
                    dest_file.write(self.generator.get_generated_code())

        except IOError:
            raise IOError('failed to write to "%s" file' % os.path.abspath(self.dest_filename))

    def get_code_pretty(self):
        if not self.compilation_done:
            raise RuntimeError('compilation has not been completed yet')

        if self.out_format == 'BIN':
            return hexlify(self.generator.get_generated_code())
        else:
            return self.generator.get_generated_code()