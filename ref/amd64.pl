:- module(amdref, [instruction/7, excep/3]).

% We list a bunch of instructions. They take the following form:
%
%     (AMD64_<mnemonic>
%     , <name>
%     , [<gas suffixes>]
%     , <action performed>
%     , <side effects> % textual description
%     , [<source operands>]
%     , [<dest operands>]
%     , [<affected flags (excluding exceptions)>])
% 
% These are adapted (almost but not quite) verbatim from AMD's
% Architecture Programmer's Manual, Volume 3, Chapter 3.

instruction('AAA', [''],
	    "ASCII Adjust After Addition",
	    "Adjusts the value in the AL register to an unpacked BCD value. \c
	     Use the AAA instruction after using the ADD instruction to add \c
	     two unpacked BCD numbers.",
	    [], [], []).

instruction('AAD', [''],
	    "ASCII Adjust Before Division",
	    "Converts two unpacked BCD digits in the AL (least significant) \c
             and AH (most significant) registers to a single binary value in \c
             the AL register.",
	    [], [], []).

instruction('AAM', [''],
            "ASCII Adjust After Multiply",
	    "Converts the value in the AL register from binary to two unpacked \c
	     BCD digits in the AH (most significant and AL (least significant) \c
	     registers.",
	    [], [], []).

instruction('AAS', [''],
	    "ASCII Adjust After Subtraction",
	    "Adjusts the value in the AL register to an unpacked BCD value. \c
	     Use the AAS instruction after using the SUB instruction to \c
	     subtract two unpacked BCD numbers.",
	    [], [], []).

instruction('ADC', [''],
	    "Add with Carry",
	    "Adds the carry flag (CF), the value in a destination register or \c
	     memory location, and an immediate value or the value in a \c
	     source register or memory location, and stores the result in the \c
	     destination operand location.",
	    [(mem, reg, imm)], [(mem, reg)],
	    ['OF', 'SF', 'ZF', 'AF', 'PF', 'CF']).

instruction('ADD', [b, w, l, q],
	    "Signed or Unsigned ADD",
	    "Adds the value in a register or memory location (destination \c
	     operand) and an immediate value or the value in a register or \c
	     memory location (source operand), and stores the result in the \c
	     destination operand.",
	    [(mem, reg, imm)], [(mem, reg)],
	    ['OF', 'SF', 'ZF', 'AF', 'PF', 'CF']).

instruction('AND', [b, w, l, q],
	    "Logical AND",
	    "Performs a bit-wise logical and operation on the value in a \c
	     register or memory location (destination operand) and an \c
	     immediate value or the value in a register or memory location \c
	     (source operand), and stores the result in the destination \c
	     operand location. Both operands cannot be memory locations.",
	    [(mem, reg, imm)], [(mem, reg)],
	    ['OF', 'SF', 'ZF', 'AF', 'PF', 'CF']).

instruction('BSF', [w, l],
	    "Bit Scan Forward",
	    "Searches the value in a register or a memory location (source \c
             operand) for the least significant set bit. If a set bit is \c
	     found, the instruction clears the zero flag (ZF) and stores the \c
	     index of the least-significant set bit in a destination register \c
	     (destination operand). If the second operand contains 0, the \c
	     instruction sets ZF to 1 and does not change the contents of the \c
	     destination register. The bit index is an unsigned offset from \c
	     bit 0 of the searched value.",
	    [(mem, reg)], [(reg)],
	    ['OF', 'SF', 'ZF', 'AF', 'PF', 'CF']).

excep('AAA', 'invalid opcode', "used in 64-bit mode").
excep('AAM', 'invalid opcode', "used in 64-bit mode").
excep('AAD', 'invalid opcode', "used in 64-bit mode").
excep('AAS', 'invalid opcode', "used in 64-bit mode").

excep('ADC', 'Stack, #SS', "a memory address exceeds the stack segment \c
	     limit or is non-canonical").
excep('ADC', 'General protection, #GP', "a memory address exceeds the \c
	     data segment limit, is non-canonical, non-writeable, or NULL").
excep('ADC', 'Page fault, #PF', "a page fault results from the execution \c
	     of the instruction").
excep('ADC', 'Alignment check, #AC', "an unaligned memory access was \c
	      performed while alignment checking was enabled").

excep('ADD', 'Stack, #SS', "a memory address exceeds the stack segment \c
	     limit or is non-canonical").
excep('ADD', 'General protection, #GP', "a memory address exceeds the \c
	     data segment limit, is non-canonical, non-writeable, or NULL").
excep('ADD', 'Page fault, #PF', "a page fault results from the execution \c
	     of the instruction").
excep('ADD', 'Alignment check, #AC', "an unaligned memory access was \c
	      performed while alignment checking was enabled").

excep('AND', 'Stack, #SS', "a memory address exceeds the stack segment \c
	     limit or is non-canonical").
excep('AND', 'General protection, #GP', "a memory address exceeds the \c
	     data segment limit, is non-canonical, non-writeable, or NULL").
excep('AND', 'Page fault, #PF', "a page fault results from the execution \c
	     of the instruction").
excep('AND', 'Alignment check, #AC', "an unaligned memory access was \c
	      performed while alignment checking was enabled").

excep('BSF', 'Stack, #SS', "a memory address exceeds the stack segment limit \c
	     	            or is non-canonical").
excep('BSF', 'General protection, #GP', "a memory address exceeds a data \c
	                                 segment limit, is non-canonical, or \c
					 a null data segment is used to \c
					 reference memory.").
excep('BSF', 'Page fault, #PF', "a page fault results from the execution of \c
	                         the instruction.").
excep('BSF', 'Alignment Check, #AC', "an unaligned memory reference is \c
	                              performed while alignment checking was \c
				       enabled.").
