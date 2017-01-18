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

# Provides the traditional symbol table functionality
class SymbolTable:
    def __init__(self):
        self.symbols = dict()

    def add_entry(self, symbol, addr):
        if symbol in self.symbols:
            raise KeyError('Symbol "%s" already exists' % symbol)

        try:
            self.symbols[symbol] = int(addr)
        except ValueError:
            raise ValueError('Address "%s" must be an integer' % addr)

    def contains(self, symbol):
        return (symbol in self.symbols)

    def get_address(self, symbol):
        if symbol not in self.symbols:
            raise KeyError('Symbol "%s" not in the symbol table' % symbol)

        return self.symbols[symbol]

    def __str__(self):
        pretty_str = '{\n'
        for key in sorted(self.symbols, key=self.symbols.get):
            pretty_str += '\t%s: %s\n' % (key, self.symbols[key])

        pretty_str += '}'
        return pretty_str