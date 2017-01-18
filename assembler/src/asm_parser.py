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
from asm_stmt import DirectiveType, ISA, DIRS, AsmInstruction, AsmDirective, AsmLabel

# An observer for the parsing events
class AsmParserObserver:
    def on_instruction(self, stmt):
        raise NotImplementedError
    def on_label(self, stmt):
        raise NotImplementedError
    def on_directive(self, stmt):
        raise NotImplementedError
    def on_finished(self):
        raise NotImplementedError


class StmtTokenizer:
    def __init__(self, stmt):
        self.org_stmt = stmt
        self.line = stmt.lstrip()
        # Ignore the comment
        if self.line[0:2] == '//':
            self.line = ''

    def get_stmt(self):
        return self.org_stmt

    def has_more_tokens(self):
        return len(self.line) != 0

    def get_next_token(self):
        if not self.has_more_tokens():
            raise RuntimeError('no more tokens')

        if self.line[0] in ['*', ',', ':', '+', '-', '{', '}']:
            token = self.line[0]
            self.line = self.line[1:].lstrip()
        else:
            count = 0
            while (count < len(self.line)
                   and not self.line[count].isspace()
                   and self.line[count] not in ['*', ',', ':', '+', '-', '{', '}']
                   and self.line[count:count + 2] != '//'):
                count = count + 1

            token = self.line[0:count]
            self.line = self.line[count:].lstrip()

        # Ignore the comment
        if self.line[0:2] == '//':
            self.line = ''

        return token


# Parses the ARSC assembly source file and for each instruction and
# assembler directive it invokes the proper method of the registered
# observer. The parsing results are caches so that the parser may be
# re-used to iterate over the parsed statements
class AsmParser:

    CommandType = type('CommandType'
                       , ()
                       , dict(INSTRUCTION = 0, LABEL = 1, DIRECTIVE = 2))

    # The filename can be either an absolute or relative path to the
    # source file
    def __init__(self, filename):
        try:
            with open(filename, 'r') as src_file:
                str = src_file.read()
                self.abs_path = os.path.abspath(filename)
                self.src_lines = str.split('\n')
                self.statements = []
                self.parsed = False
        except IOError:
            raise IOError('Failed to open/read the source file "%s"' % filename)


    def invoke_observer_method(self, observer, stmt):
        if isinstance(stmt, AsmInstruction):
            return observer.on_instruction(stmt)
        elif isinstance(stmt, AsmDirective):
            return observer.on_directive(stmt)
        else:
            return observer.on_label(stmt)


    # Kick-start the parsing process. This method may be used only if parsing has not been
    # completed yet. To iterate over the already parsed statements use the 'iterate' method
    def parse(self, observer):
        if isinstance(observer, AsmParserObserver) != True:
            raise TypeError('observer must be an instance of ParserObserver')
        elif self.parsed:
            raise RuntimeError('the parsing process has already been completed')

        lineno = 0
        for line in self.src_lines:
            lineno += 1
            tokenizer = StmtTokenizer(line)
            if not tokenizer.has_more_tokens():
                continue

            try:
                token = tokenizer.get_next_token()
                stmt = None
                if ISA.has_key(token):
                    stmt = self.parse_instruction(token, tokenizer, line)
                else:
                    stmt = self.parse_directive_or_label(token, tokenizer)

                self.statements.append(dict(stmt=stmt, lineno=lineno))
                if not self.invoke_observer_method(observer, stmt):
                    break

            except SyntaxError as err:
                err.lineno = lineno
                err.filename = self.abs_path
                raise err

            self.parsed = True

        try:
            # Inform the observer that parsing has been completed
            observer.on_finished()
        except SyntaxError as err:
            err.lineno = lineno
            err.filename = self.abs_path
            raise err

    def iterate(self, observer):
        if isinstance(observer, AsmParserObserver) != True:
            raise TypeError('observer must be an instance of ParserObserver')
        elif not self.parsed:
            raise RuntimeError('the source has not been parsed yet')

        for stmt_pair in self.statements:
            try:
                if not self.invoke_observer_method(observer, stmt_pair['stmt']):
                    break

            except SyntaxError as err:
                err.filename = self.abs_path
                err.lineno = stmt_pair['lineno']
                raise err

        # Iteration completed
        observer.on_finished()

    def parse_instruction(self, mnemonic, tokenizer, original_stmt):
        indirect_or_iodev_bit = None
        address = None
        index = None

        if tokenizer.has_more_tokens():
            token = tokenizer.get_next_token()
            if token == '*':
                indirect_or_iodev_bit = 1
                if not tokenizer.has_more_tokens():
                    raise SyntaxError('address expected after "%s"' % token)

                address = tokenizer.get_next_token()
            elif token == '{':
                token = tokenizer.get_next_token()
                if not tokenizer.has_more_tokens():
                    raise SyntaxError('matching "}" not found')

                indirect_or_iodev_bit = token
                token = tokenizer.get_next_token()
                if token != '}':
                    raise SyntaxError('matching "}" not found')

                if not tokenizer.has_more_tokens():
                    raise SyntaxError('address expected after "%s"' % token)

                address = tokenizer.get_next_token()
            else:
                address = token

            if tokenizer.has_more_tokens():
                token = tokenizer.get_next_token()
                if token != ',':
                    raise SyntaxError('instruction contains invalid address operand')
                elif not tokenizer.has_more_tokens():
                    raise SyntaxError('index register is expected after "%s"' % token)

                index = tokenizer.get_next_token()
                if tokenizer.has_more_tokens():
                    while tokenizer.has_more_tokens():
                        index += tokenizer.get_next_token()

                    raise SyntaxError('"%s" is not a valid index register' % index)

        return AsmInstruction(mnemonic, indirect_or_iodev_bit, address, index, original_stmt)


    def parse_directive_or_label(self, first_token, tokenizer):
        if first_token == 'END':
            if tokenizer.has_more_tokens():
                raise SyntaxError('"%s" directive expects no arguments' % first_token)

            return AsmDirective(first_token, None)
        elif not tokenizer.has_more_tokens():
            raise SyntaxError('unrecognized statement "%s"' % tokenizer.get_stmt())

        if first_token == 'ANCHOR':
            args = [tokenizer.get_next_token()]
            if tokenizer.has_more_tokens():
                token = ''
                while tokenizer.has_more_tokens():
                    token += tokenizer.get_next_token()

                raise SyntaxError(
                    'unexpected character sequence "%s" following "%s"' %
                    (token, args[-1]))

            return AsmDirective(first_token, args)
        else:
            token = tokenizer.get_next_token()
            if token == ':':
                if tokenizer.has_more_tokens():
                    tmp = ''
                    while tokenizer.has_more_tokens():
                        tmp += tokenizer.get_next_token()

                    raise SyntaxError(
                        'unexpected character sequence "%s" following "%s"' %
                        (tmp, token))

                return AsmLabel(first_token)
            elif token == 'ALIAS':
                token = ''
                while tokenizer.has_more_tokens():
                    token += tokenizer.get_next_token()

                return AsmDirective('ALIAS', [first_token, token])
            elif token == 'BSS':
                if not tokenizer.has_more_tokens():
                    raise SyntaxError('incomplete command "%s"' % token)

                token = tokenizer.get_next_token()
                while tokenizer.has_more_tokens():
                    token += tokenizer.get_next_token()

                return AsmDirective('BSS', [first_token, token])
            elif token == 'BSC':
                if not tokenizer.has_more_tokens():
                    raise SyntaxError('"%s" command expects one or more integer literals' % token)

                args = []
                while True:
                    token = tokenizer.get_next_token()
                    if token == '-':
                        if not tokenizer.has_more_tokens():
                            raise SyntaxError('invalid syntax near "%s"' % token)

                        args.append(token + tokenizer.get_next_token())
                    else:
                        args.append(token)

                    if not tokenizer.has_more_tokens():
                        break

                    token = tokenizer.get_next_token()
                    if token != ',':
                        while tokenizer.has_more_tokens():
                            token += tokenizer.get_next_token()

                        raise SyntaxError('unexpected character string "%s"' % token)
                    elif not tokenizer.has_more_tokens():
                        raise SyntaxError('comma (,) must be followed by another integer literal')

                return AsmDirective('BSC', [first_token] + args)
            else:
                raise SyntaxError('unrecognized statement "%s"' % tokenizer.get_stmt())
