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

`define THEIA_TOP uut
`define CP_TOP `THEIA_TOP.CP
`define VP_TOP `THEIA_TOP.VPX[  CVPID ].VP

`define CONTROL_PROCESSOR_OP_WIDTH            8
`define CONTROL_PROCESSOR_OP_NOP             `CONTROL_PROCESSOR_OP_WIDTH'd0
`define CONTROL_PROCESSOR_OP_DELIVER_COMMAND `CONTROL_PROCESSOR_OP_WIDTH'd1
`define CONTROL_PROCESSOR_OP_ADD             `CONTROL_PROCESSOR_OP_WIDTH'd2
`define CONTROL_PROCESSOR_OP_SUB             `CONTROL_PROCESSOR_OP_WIDTH'd3
`define CONTROL_PROCESSOR_OP_AND             `CONTROL_PROCESSOR_OP_WIDTH'd4
`define CONTROL_PROCESSOR_OP_OR              `CONTROL_PROCESSOR_OP_WIDTH'd5
`define CONTROL_PROCESSOR_OP_BRANCH          `CONTROL_PROCESSOR_OP_WIDTH'd6
`define CONTROL_PROCESSOR_OP_BEQ             `CONTROL_PROCESSOR_OP_WIDTH'd7
`define CONTROL_PROCESSOR_OP_BNE             `CONTROL_PROCESSOR_OP_WIDTH'd8
`define CONTROL_PROCESSOR_OP_BG              `CONTROL_PROCESSOR_OP_WIDTH'd9
`define CONTROL_PROCESSOR_OP_BL              `CONTROL_PROCESSOR_OP_WIDTH'd10
`define CONTROL_PROCESSOR_OP_BGE             `CONTROL_PROCESSOR_OP_WIDTH'd11
`define CONTROL_PROCESSOR_OP_BLE             `CONTROL_PROCESSOR_OP_WIDTH'd12
`define CONTROL_PROCESSOR_ASSIGN             `CONTROL_PROCESSOR_OP_WIDTH'd13
`define CONTROL_PROCESSOR_OP_COPYBLOCK       `CONTROL_PROCESSOR_OP_WIDTH'd14
`define CONTROL_PROCESSOR_OP_EXIT            `CONTROL_PROCESSOR_OP_WIDTH'd15
`define CONTROL_PROCESSOR_OP_NOT             `CONTROL_PROCESSOR_OP_WIDTH'd16
`define CONTROL_PROCESSOR_OP_SHL             `CONTROL_PROCESSOR_OP_WIDTH'd17
`define CONTROL_PROCESSOR_OP_SHR             `CONTROL_PROCESSOR_OP_WIDTH'd18

`define CONTROL_PROCESSOR_REG_STATUS         `CONTROL_PROCESSOR_OP_WIDTH'd2
`define CONTROL_PROCESSOR_REG_BLOCK_DST      `CONTROL_PROCESSOR_OP_WIDTH'd3


`define VPID_WIDTH                    7
`define VP_COMMAND_START_MAIN_THREAD  0
`define VP_COMMAND_STOP_MAIN_THREAD   1

//`define VERILATOR 1
//`define CONTROL_BUS_WIDTH                     32
`define CBC_BUS_WIDTH                     32
`define CP_MSG_ARGS_RNG                   15:0
`define CP_MSG_OPERATION_RNG              23:16
`define CP_MSG_DST_RNG                    31:24
`define CP_MSG_BCAST                      31

`define OMEM_SIZE                         250000

`define APR06 1
`define MCU_REQUEST_SIZE                      81  //32 + 32 + 8 + 8
`define MCU_FIFO_DEPTH                        8
`define MCU_COPYMEMBLOCKCMD_DSTOFF_RNG        19:0//23:0
`define MCU_COPYMEMBLOCKCMD_BLKLEN_RNG        30:20//31:24
`define MCU_COPYMEMBLOCK_TAG_BIT              31
`define MCU_COPYMEMBLOCKCMD_SRCOFF_RNG        63:32
`define MCU_COPYMEMBLOCKCMD_VPMASK_RNG        79:64
`define MCU_VPMASK_LEN                        (79-64)
//`define MCU_REQUEST_TYPE_BIT                  80           //See if it is CPBLOCKCOPY or VPCOMMAND
`define MCU_COPYMEMBLOCKCMD_DSTTYPE_VPCODEMEM 1'b1
`define MCU_COPYMEMBLOCKCMD_DSTTYPE_VPDATAMEM 1'b0

`define MCU_TAG_SIZE                          2
`define TAG_NULL                              2'b00
`define TAG_INSTRUCTION_ADDRESS_TYPE          2'b10
`define TAG_DATA_ADDRESS_TYPE                 2'b01

`define MAX_THREADS             2
`define MAX_CORES               4 		//The number of cores, make sure you update MAX_CORE_BITS!
`define MAX_CORE_BITS           2 		// 2 ^ MAX_CORE_BITS = MAX_CORES
`define MAX_TMEM_BANKS          4 		//The number of memory banks for TMEM
`define MAX_TMEM_BITS           2 		//2 ^ MAX_TMEM_BANKS = MAX_TMEM_BITS
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
`define OPERATION_LOGIC  4'b0101
`define OPERATION_IO     4'b0110


`define RS_ADD0                  4'd1	//001
`define RS_ADD1                  4'd2  //010
`define RS_DIV                   4'd3  //011
`define RS_MUL                   4'd4  //100
`define RS_SQRT                  4'd5  //101
`define RS_LOGIC                 4'd6  //110
`define RS_IO                    4'd7  //111
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

`define MOD_ISSUE_SRC_SIZE 87//`DATA_ROW_WIDTH-`ISSUE_SRCTAG_SIZE
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

`define NUMBER_OF_RSVR_STATIONS 7

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
`define IO_OPERATION_OMWRITE 3'b0
`define IO_OPERATION_TMREAD  3'b1

`define SRC_RET_ADDR_RNG 95:64
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


`define SPR_CONTROL0 `DATA_ADDRESS_WIDTH'd2
`define SPR_CONTROL1 `DATA_ADDRESS_WIDTH'd3
`define SPR_TCONTROL0_MT_ENABLED              0
`define SPR_TCONTROL0_T0_INST_OFFSET_RNG      16:1

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

