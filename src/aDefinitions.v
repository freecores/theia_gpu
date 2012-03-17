/**********************************************************************************
Theaia, Ray Cast Programable graphic Processing Unit.
Copyright (C) 2009  Diego Valverde (diego.valverde.g@gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

***********************************************************************************/


/*******************************************************************************
Module Description:

	This module defines constants that are going to be used
	all over the code. By now you have may noticed that all
	constants are pre-compilation define directives. This is
	for simulation perfomance reasons mainly.
*******************************************************************************/
//`define VERILATOR 1
`define MAX_CORES 4 		//The number of cores, make sure you update MAX_CORE_BITS!
`define MAX_CORE_BITS 2 		// 2 ^ MAX_CORE_BITS = MAX_CORES
`define MAX_TMEM_BANKS 4 		//The number of memory banks for TMEM
`define MAX_TMEM_BITS 2 		//2 ^ MAX_TMEM_BANKS = MAX_TMEM_BITS
`define SELECT_ALL_CORES `MAX_CORES'b1111 		//XXX: Change for more cores

//Defnitions for the input file size (avoid nasty warnings about the size of the file being different from the
//size of the array which stores the file in verilog
`define PARAMS_ARRAY_SIZE 43 		//The maximum number of byte in this input file
`define VERTEX_ARRAY_SIZE 7000 		//The maximum number of byte in this input file
`define TEXTURE_BUFFER_SIZE 196608 		//The maximum number of byte in this input file
//---------------------------------------------------------------------------------
//Verilog provides a `default_nettype none compiler directive.  When
//this directive is set, implicit data types are disabled, which will make any
//undeclared signal name a syntax error.This is very usefull to avoid annoying
//automatic 1 bit long wire declaration where you don't want them to be!
`default_nettype none

//The clock cycle
`define CLOCK_CYCLE  5
`define CLOCK_PERIOD 10
//---------------------------------------------------------------------------------
//Defines the Scale. This very important because it sets the fixed point precision.
//The Scale defines the number bits that are used as the decimal part of the number.
//The code has been written in such a way that allows you to change the value of the
//Scale, so that it is possible to experiment with different scenarios. SCALE can be
//no smaller that 1 and no bigger that WIDTH.
`define SCALE        17

//The next section defines the length of the registers, buses and other structures, 
//do not change this valued unless you really know what you are doing (seriously!)
`define WIDTH        32
`define WB_WIDTH     32  //width of wish-bone buses		
`define LONG_WIDTH   64

`define WB_SIMPLE_READ_CYCLE  0
`define WB_SIMPLE_WRITE_CYCLE 1
//---------------------------------------------------------------------------------

`define OPERATION_NOP    4'b0000
`define OPERATION_ADD    4'b0001
`define OPERATION_DIV    4'b0010
`define OPERATION_MUL    4'b0011
`define OPERATION_SQRT   4'b0100


`define RS_ADD0                  1	//001
`define RS_ADD1                  2  //010
`define RS_DIV                   3  //011
`define RS_MUL                   4  //100
`define RS_SQRT                  5  //101

//----------------------------------------------------------------
//Issue bus packet structure

`define ISSUE_PACKET_SIZE 237       //The size of the packet
`define ISSUE_SRCTAG_SIZE 9

`define ISSUE_RSID_RNG    236:233   //4 bits
`define ISSUE_DST_RNG     232:225   //8 bits
`define ISSUE_WE_RNG      224:222   //3 bits
`define ISSUE_SCALE_OP    221
`define ISSUE_SCALER      220
`define ISSUE_SCALE0      219
`define ISSUE_SCALE1      218
`define SCALE_SIZE        4
`define ISSUE_SCALE_RNG   221:218    //4 bits
`define ISSUE_SRC1RS_RNG  217:214    //4 bits
`define ISSUE_SIGN1_RNG   213:211    //3 bits
`define ISSUE_SWZZ1_RNG   210:205    //6 bits
`define ISSUE_SRC1_DATA_RNG    204:109    //96 bits

`define ISSUE_SRC0RS_RNG  108:105   //4 bits
`define ISSUE_SIGN0_RNG   104:102   //3 bits
`define ISSUE_SWZZ0_RNG   101:96    //6 bits
`define ISSUE_SRC0_DATA_RNG    95:0		//96 bits

`define ISSUE_SRC1_TAG_RNG    213:205
`define ISSUE_SRC0_TAG_RNG    104:96
`define TAG_SIGNX 8
`define TAG_SIGNY 7
`define TAG_SIGNZ 6
`define TAG_SWLX_RNG 5:4
`define TAG_SWLY_RNG 3:2
`define TAG_SWLZ_RNG 1:0
//----------------------------------------------------------------
`define MOD_ISSUE_PACKET_SIZE     219
`define MOD_ISSUE_RSID_RNG        218:215
`define MOD_ISSUE_DST_RNG         214:207
`define MOD_ISSUE_WE_RNG          206:204
`define MOD_ISSUE_SCALE_RNG       203:200
`define MOD_ISSUE_SRC1RS_RNG      199:196
`define MOD_ISSUE_SRC1_DATA_RNG   195:100
`define MOD_ISSUE_SRC0RS_RNG      99:96
`define MOD_ISSUE_SRC0_DATA_RNG   95:0

`define MOD_ISSUE_TAG1_RNG        8:0
`define MOD_ISSUE_TAG0_RNG        8:0
//----------------------------------------------------------------
// Commit bus packet structure

`define COMMIT_PACKET_SIZE 111      // The size of the packet
`define COMMIT_RSID_RNG    110:107  //4 bits
`define COMMIT_WE_RNG		106:104  //3 bits
`define COMMIT_WE_X        106
`define COMMIT_WE_Y        105
`define COMMIT_WE_Z        104
`define COMMIT_DST_RNG     103:96	//8 bits
`define COMMIT_DATA_RNG    95:0     //95 bits
`define COMMIT_X_RNG       95:64		//32 bits
`define COMMIT_Y_RNG       63:32		//32 bits
`define COMMIT_Z_RNG       31:0		//32 bits

`define COMMIT_SIGN_X      95
`define COMMIT_SIGN_Y      63
`define COMMIT_SIGN_Z      31 
//----------------------------------------------------------------
`define MOD_COMMIT_PACKET_SIZE 114
`define MOD_SCALE_RNG          113:110
`define MOD_SIGN_RNG           109:106
`define MOD_COMMIT_TAG_RNG     109:100
`define MOD_COMMIT_SWZ_RNG     105:100
`define MOD_COMMIT_RSID_RNG    99:96
`define MOD_COMMIT_DATA_RNG    95:0     //95 bits
//----------------------------------------------------------------
`define OP_SIZE     16             //Size of the operation part of the instruction
`define OP_RNG      63:48          //Range of the operation part of the instruction
`define OP_BIT_IMM  15
//`define OP_WE_RNG   14:12
`define OP_BREAK    11
`define OP_CODE_RNG 10:0
//----------------------------------------------------------------
// Source0 structure
`define SRC0_SIZE           17
`define SRC0_RNG            16:0
`define SRC0_ADDR_SIZE      8
`define SRC0_SIGN_RNG       16:14
`define SRC0_SWZX_RNG       13:8  
`define SRC0_ADDR_RNG       7:0
//----------------------------------------------------------------
// Source1 structure 
`define SRC1_SIZE           17
`define SRC1_RNG            33:17
`define SRC1_ADDR_SIZE      8
`define SRC1_SIGN_RNG       16:14
`define SRC1_SWZX_RNG       13:8  
`define SRC1_ADDR_RNG       7:0
//----------------------------------------------------------------

`define NUMBER_OF_RSVR_STATIONS 5

//---------------------------------------------------------------
//Instruction structure
`define INST_IMM_RNG          31:0
`define INST_SRC0_ADDR_RNG    7:0
`define INST_SRC0_SWZL_RNG    13:8
`define INST_SRC0_SWLZ_RNG    9:8
`define INST_SRC0_SWLY_RNG    11:10
`define INST_SRC0_SWLX_RNG    13:12
`define INST_SRC0_SIGN_RNG    16:14
`define INST_SRC0_SIGNZ       14
`define INST_SRC0_SIGNY       15
`define INST_SRC0_SIGNX       16
`define INST_SCR1_ADDR_RNG    24:17
`define INST_SCR1_SWZL_RNG    30:25
`define INST_SRC1_SWLZ_RNG    26:25
`define INST_SRC1_SWLY_RNG    28:27
`define INST_SRC1_SWLX_RNG    30:29
`define INST_SRC1_SIGN_RNG    33:31
`define INST_SRC1_SIGNZ       31
`define INST_SRC1_SIGNY       32
`define INST_SRC1_SIGNX       33
`define INST_DST_RNG          41:34
`define INST_WE_Z             42
`define INST_WE_Y             43 
`define INST_WE_X             44
/*
`define INST_RESERVED_RNG     46:42
*/

`define INST_SRC0_DISPLACED   45
`define INST_SRC1_DISPLACED   46
`define INST_DEST_ZERO        47
`define INST_ADDRMODE_RNG     47:45
`define INST_CODE_RNG         50:48
//`define INST_SCOP_RNG         53:51
`define INST_RESERVED_RNG     51:53
`define INST_BRANCH_OP_RNG    56:54
`define INST_BRANCH_BIT       57
`define INST_EOF_RNG          58           //End of flow
`define INST_SCOP_RNG         62:59
`define INST_IMM              63	

`define INST_WE_RNG           44:42
`define SCALE_SRC1_EN  0		 
`define SCALE_SRC0_EN  1
`define SCALE_SRCR_EN  2
`define SCALE_OP       3		 		 
//---------------------------------------------------------------
//Compiler has to put the WE.x, WE.y and WE.z in zero (no write)
//for the branch instructions
`define BRANCH_ALWAYS               3'b000      //JMP
`define BRANCH_IF_ZERO              3'b001      //==
`define BRANCH_IF_NOT_ZERO          3'b010      //!=
`define BRANCH_IF_SIGN              3'b011      //<
`define BRANCH_IF_NOT_SIGN          3'b100      //>
`define BRANCH_IF_ZERO_OR_SIGN      3'b101		//<=
`define BRANCH_IF_ZERO_OR_NOT_SIGN  3'b110      //>=
//---------------------------------------------------------------

`define X_RNG 95:64
`define Y_RNG 63:32
`define Z_RNG 31:0


`define ALU_BIT_ADD     0 //Bit 2 of operation is div bit
`define ALU_BIT_ASSIGN  1 //Bit 2 of operation is div bit
`define ALU_BIT_DIV     2 //Bit 2 of operation is div bit
`define ALU_BIT_MUL     3


`define OPERAND_BIT_X 15
`define OPERAND_BIT_Y 14
`define OPERAND_BIT_Z 13

`define NOP  `INSTRUCTION_OP_LENGTH'b0_000000000000000
`define ADD  `INSTRUCTION_OP_LENGTH'b0_000000000000001
`define AND  `INSTRUCTION_OP_LENGTH'b0_000000000000010
`define DIV  `INSTRUCTION_OP_LENGTH'b0_000000000000100
`define MUL  `INSTRUCTION_OP_LENGTH'b0_000000000001000



//You can play around with the size of instuctions, but keep
//in mind that Bits 3 and 4 of the Operand have a special meaning
//that is used for the jump familiy of instructions (see Documentation).
//Also the MSB of Operand is used by the decoder to distinguish 
//between Type I and Type II instructions.


`define INSTRUCTION_WIDTH       64

//Defines the Lenght of Memory blocks
//`define RESOURCE_VECTOR_SIZE  11
`define INSTRUCTION_ADDR_WIDTH 16
`define DATA_ROW_WIDTH        96
`define DATA_ADDRESS_WIDTH    8//7
`define ROM_ADDRESS_WIDTH     16
`define ROM_ADDRESS_SEL_MASK  `ROM_ADDRESS_WIDTH'h8000



`define SPR_CONTROL `DATA_ADDRESS_WIDTH'd30


`define C1     `DATA_ADDRESS_WIDTH'd64 
`define C2     `DATA_ADDRESS_WIDTH'd65 
`define C3     `DATA_ADDRESS_WIDTH'd66 
`define C4     `DATA_ADDRESS_WIDTH'd67 
`define C5     `DATA_ADDRESS_WIDTH'd68 
`define C6     `DATA_ADDRESS_WIDTH'd69 
`define C7     `DATA_ADDRESS_WIDTH'd70 
`define R1		`DATA_ADDRESS_WIDTH'd71 
`define R2		`DATA_ADDRESS_WIDTH'd72 
`define R3		`DATA_ADDRESS_WIDTH'd73 
`define R4		`DATA_ADDRESS_WIDTH'd74
`define R5		`DATA_ADDRESS_WIDTH'd75
`define R6		`DATA_ADDRESS_WIDTH'd76
`define R7		`DATA_ADDRESS_WIDTH'd77
`define R8		`DATA_ADDRESS_WIDTH'd78
`define R9		`DATA_ADDRESS_WIDTH'd79
`define R10		`DATA_ADDRESS_WIDTH'd80
`define R11		`DATA_ADDRESS_WIDTH'd81
`define R12		`DATA_ADDRESS_WIDTH'd82

