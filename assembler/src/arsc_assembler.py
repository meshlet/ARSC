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
# ARSC ASSEMBLER DRIVER
#
from compiler_engine import CompilerEngine
from argparse import ArgumentParser
import sys

def format_syntax_err(err):
    return '%s(%d): %s' % (err.filename, err.lineno, err.message)

def main():
    try:
        arg_parser = ArgumentParser(
            description='ARSC Assembler, Copyright (c) 2016-2017 Dzanan Bajgoric.'
                + ' All Rights Reserved. The ARSC assembler translates the assembly'
                + ' program written in ARSC ASM language into a ARSC machine code'
                + ' to be executed by the ARSC CPU.')

        arg_parser.add_argument(
            '-f'
            , '--fmt'
            , help='Output file format. Possible options are: MIF (ASCII initialization'
                + ' file), BIN (binary), HEX (ASCII HEX file - this is NOT an Intel-Format'
                + ' .hex file) or PRETTY (human-readable output). If omitted,'
                + ' MIF format is used.'
            , choices=['MIF', 'BIN', 'HEX', 'PRETTY']
            , default='MIF')

        arg_parser.add_argument(
            '-d'
            , '--dst'
            , help='The destination for the generated code: FILE (default), STD (standard'
                + ' output).'
            , choices=['FILE', 'STD']
            , default='FILE')

        arg_parser.add_argument(
            'input_file'
            , help='The source file containing the ARSC assembly program.')

        arg_parser.add_argument(
            'output_file'
            , nargs='?'
            , help='The output file where the generated code will be written to. It may'
                + ' be omitted if -fmt is set to STD.'
            , default=None)

        args = arg_parser.parse_args()
        if args.output_file is None and args.dst != 'STD':
            arg_parser.print_usage()
            raise RuntimeError('[output_file] must be specified if -dst is not set to STD')

        # Run the compiler
        compiler = CompilerEngine(args.input_file, args.output_file, args.fmt)
        compiler.run()

        # Figure out what to do with the generated code
        if args.dst == 'FILE':
            compiler.write()
        elif args.dst == 'STD':
            print compiler.get_code_pretty()

    except SyntaxError as err:
        print format_syntax_err(err)
#    except Exception as err:
#        print '%s: error: %s\n' % (__file__, err.message)

if __name__ == '__main__':
    main()
else:
    raise RuntimeError('arsc_assembler.py must be executed via the terminal')