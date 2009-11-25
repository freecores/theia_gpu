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
	all over the code. By know you have may noticed that all
	constants are pre-compilation define directives. This is
	for simulation perfomance reasons mainly.
*******************************************************************************/


//---------------------------------------------------------------------------------
//Verilog provides a `default_nettype none compiler directive.  When
//this directive is set, implicit data types are disabled, which will make any
//undeclared signal name a syntax error.This is very usefull to avoid annoying
//automatic 1 bit long wire declaration where you don't want them to be!
`default_nettype none
//---------------------------------------------------------------------------------
//Defines the Scale. This very important because it sets the fixed point precsision.
//The Scale defines the number bits that are used as the decimal part of the number.
//The code has been written in such a way that allows you to change the value of the
//Scale, so that it is possible to experimet with different scenarios. SCALE can be
//no smaller that 1 and no bigger that WIDTH.
`define SCALE 			17

//The next 2 defines the length of the registers, buses and other structures, 
//do not change this valued unless you really know what you are doing (seriously!)
`define WIDTH 			32
`define WB_WIDTH     32  //width of wish-bone buses		
`define LONG_WIDTH  	64

`define WB_SIMPLE_READ_CYCLE 0
`define WB_SIMPLE_WRITE_CYCLE 1
//---------------------------------------------------------------------------------
//Next are the constants that define the size of the instructions.
//instructions are formed like this:
// Tupe I:
// Operand			 (of size INSTRUCTION_OP_LENGTH )
// DestinationAddr (of size DATA_ADDRESS_WIDTH )
// SourceAddrr1	 (of size DATA_ADDRESS_WIDTH )
// SourceAddrr2	 (of size DATA_ADDRESS_WIDTH )	
//Type II:
// Operand			 (of size INSTRUCTION_OP_LENGTH )
// DestinationAddr (of size DATA_ADDRESS_WIDTH )
// InmeadiateValue (of size WIDTH = DATA_ADDRESS_WIDTH * 2 )
//You can play around with the size of instuctions, but keep
//in mind that Bits 3 and 4 of the Operand have a special meaning
//that is used for the jump familiy of instructions (see Documentation).
//Also the MSB of Operand is used by the decoder to distinguish 
//between Type I and Type II instructions.
`define INSTRUCTION_WIDTH		64//55
`define INSTRUCTION_OP_LENGTH 16//7
`define INSTRUCTION_IMM_BIT	6		//don't change this!

//Defines the Lenght of Memory blocks
`define DATA_ROW_WIDTH	96
`define DATA_ADDRESS_WIDTH		16
`define ROM_ADDRESS_WIDTH		16

//---------------------------------------------------------------------------------
//Defines the ucode memory entry point for the various ucode routines
`define INITIAL_UCODE_ADDRESS		`ROM_ADDRESS_WIDTH'd0
`define CPPU_UCODE_ADDRESS			`ROM_ADDRESS_WIDTH'd14
`define RGU_UCODE_ADDRESS			`ROM_ADDRESS_WIDTH'd17
`define AABBIU_UCODE_ADDRESS		`ROM_ADDRESS_WIDTH'd33
`define BIU_UCODE_ADDRESS			`ROM_ADDRESS_WIDTH'd121
`define PSU_UCODE_ADRESS			`ROM_ADDRESS_WIDTH'd196
`define PSU_UCODE_ADRESS2        `ROM_ADDRESS_WIDTH'd212  
`define TCC_UCODE_ADDRESS        `ROM_ADDRESS_WIDTH'd154  
`define DEBUG_LOG_REGISTERS		`ROM_ADDRESS_WIDTH'd221
`define NPG_UCODE_ADDRESS 			`ROM_ADDRESS_WIDTH'd24

`define USER_AABBIU_UCODE_ADDRESS `ROM_ADDRESS_WIDTH'b1000000000000000
//---------------------------------------------------------------------------------
//This handy little macro allows me to print stuff either to STDOUT or a file.
//Notice that the compilation vairable DUMP_CODE must be set if you want to print
//to a file. In XILINX right click 'Simulate Beahvioral Model' -> Properties and
//under 'Speceify `define macro name and value' type 'DEBUG=1|DUMP_CODE=1'
`ifdef DUMP_CODE
	
	`define LOGME  $fwrite(ucode_file,
`else
	`define LOGME  $write(
`endif
//---------------------------------------------------------------------------------	
`define RT_TRUE 48'b1
`define RT_FALSE 48'b0
//---------------------------------------------------------------------------------	
`define VOID									`DATA_ADDRESS_WIDTH'd0	//0000
//** Control register bits **//
`define CR_EN_LIGHTS   0
`define CR_EN_TEXTURE  1
`define CR_USER_AABBIU 2

//** Configurtation Registers **//
`define CREG_LIGHT_INFO						`DATA_ADDRESS_WIDTH'd0	//0000
`define CREG_CAMERA_POSITION 				`DATA_ADDRESS_WIDTH'd1	//0001
`define CREG_PROJECTION_WINDOW_MIN		`DATA_ADDRESS_WIDTH'd2	//0002
`define CREG_PROJECTION_WINDOW_MAX		`DATA_ADDRESS_WIDTH'd3	//0003
`define CREG_RESOLUTION						`DATA_ADDRESS_WIDTH'd4	//0004
`define CREG_TEXTURE_SIZE					`DATA_ADDRESS_WIDTH'd5	//0005
`define CREG_PIXEL_2D_POSITION			`DATA_ADDRESS_WIDTH'd6 //0008
`define CREG_FIRST_LIGTH               `DATA_ADDRESS_WIDTH'd7	//0007
//OK, so from address 0x06 to 0x0F is where the lights are,watch out values are harcoded
//for now!! (look in ROM.v for hardcoded values!!!)





// ** User Registers **//
//General Purpose registers, the user may put what ever he/she
//wants in here...
`define R1		`DATA_ADDRESS_WIDTH'd20
`define R2		`DATA_ADDRESS_WIDTH'd21
`define R3		`DATA_ADDRESS_WIDTH'd22
`define R4		`DATA_ADDRESS_WIDTH'd23
`define R5		`DATA_ADDRESS_WIDTH'd24
`define R6		`DATA_ADDRESS_WIDTH'd25
`define R7		`DATA_ADDRESS_WIDTH'd26
`define R8		`DATA_ADDRESS_WIDTH'd27
`define R9		`DATA_ADDRESS_WIDTH'd28
`define R10		`DATA_ADDRESS_WIDTH'd29
`define R11		`DATA_ADDRESS_WIDTH'd30
`define R12		`DATA_ADDRESS_WIDTH'd31


//** Constant Registers **//
//Don't change the order of the registers. CREG_V* and CREG_UV* registers
//need to be in that specific order for the trinagle fetcher to work 
//correctly!
`define CREG_PROJECTION_WINDOW_SCALE	`DATA_ADDRESS_WIDTH'd32
`define CREG_UNORMALIZED_DIRECTION		`DATA_ADDRESS_WIDTH'd33
`define CREG_RAY_DIRECTION					`DATA_ADDRESS_WIDTH'd34	
`define CREG_E1								`DATA_ADDRESS_WIDTH'd35
`define CREG_E2								`DATA_ADDRESS_WIDTH'd36
`define CREG_T									`DATA_ADDRESS_WIDTH'd37
`define CREG_P									`DATA_ADDRESS_WIDTH'd38
`define CREG_Q									`DATA_ADDRESS_WIDTH'd39
`define CREG_H1								`DATA_ADDRESS_WIDTH'd40
`define CREG_H2								`DATA_ADDRESS_WIDTH'd41
`define CREG_H3								`DATA_ADDRESS_WIDTH'd42
`define CREG_DELTA							`DATA_ADDRESS_WIDTH'd43
`define CREG_t									`DATA_ADDRESS_WIDTH'd44
`define CREG_u									`DATA_ADDRESS_WIDTH'd45
`define CREG_v									`DATA_ADDRESS_WIDTH'd46
`define CREG_AABBMIN							`DATA_ADDRESS_WIDTH'd47
`define CREG_AABBMAX							`DATA_ADDRESS_WIDTH'd48
`define CREG_V0								`DATA_ADDRESS_WIDTH'd49	//002a
`define CREG_UV0								`DATA_ADDRESS_WIDTH'd50	//002b	
`define CREG_V1								`DATA_ADDRESS_WIDTH'd51	//002c
`define CREG_UV1								`DATA_ADDRESS_WIDTH'd52	//002d
`define CREG_V2								`DATA_ADDRESS_WIDTH'd53	//002e
`define CREG_UV2								`DATA_ADDRESS_WIDTH'd54	//002f
`define CREG_TRI_DIFFUSE					`DATA_ADDRESS_WIDTH'd55	//0030
`define COLOR_ACC								`DATA_ADDRESS_WIDTH'd56	//0031
`define CREG_LAST_t							`DATA_ADDRESS_WIDTH'd58	//0033
`define CREG_E1_LAST							`DATA_ADDRESS_WIDTH'd59	//0034
`define CREG_E2_LAST							`DATA_ADDRESS_WIDTH'd60	//0035
`define CREG_TRI_DIFFUSE_LAST				`DATA_ADDRESS_WIDTH'd61	//0036
`define CREG_LAST_u							`DATA_ADDRESS_WIDTH'd62	//0037
`define CREG_LAST_v							`DATA_ADDRESS_WIDTH'd63	//0038


//Output registers
`define OREG_PIXEL_COLOR					`DATA_ADDRESS_WIDTH'd57	//0032
`define OREG_TEX_COORD1						`DATA_ADDRESS_WIDTH'd65	//0032
`define OREG_TEX_COORD2						`DATA_ADDRESS_WIDTH'd66	//0032
`define CREG_TEX_COLOR1						`DATA_ADDRESS_WIDTH'd67	//0032
`define CREG_TEX_COLOR2						`DATA_ADDRESS_WIDTH'd68	//0032
`define CREG_TEX_COLOR3						`DATA_ADDRESS_WIDTH'd69	
`define CREG_TEX_COLOR4						`DATA_ADDRESS_WIDTH'd70	//This is intentionally COLOR6
`define CREG_TEX_COLOR5						`DATA_ADDRESS_WIDTH'd71	
`define CREG_TEX_COLOR6						`DATA_ADDRESS_WIDTH'd72	
`define CREG_TEX_COLOR7						`DATA_ADDRESS_WIDTH'd73	
`define OREG_TEXWEIGHT1 					`DATA_ADDRESS_WIDTH'd74	
`define OREG_TEXWEIGHT2 					`DATA_ADDRESS_WIDTH'd75	
`define OREG_TEXWEIGHT3 					`DATA_ADDRESS_WIDTH'd76	
`define OREG_TEXWEIGHT4 					`DATA_ADDRESS_WIDTH'd77	
`define CREG_UV0_LAST                  `DATA_ADDRESS_WIDTH'd78
`define CREG_UV1_LAST                  `DATA_ADDRESS_WIDTH'd79
`define CREG_UV2_LAST                  `DATA_ADDRESS_WIDTH'd80
`define OREG_PIXEL_PITCH       			`DATA_ADDRESS_WIDTH'd81
`define CREG_LAST_COL						`DATA_ADDRESS_WIDTH'd82 //the last valid column, simply CREG_RESOLUTIONX - 1
//-------------------------------------------------------------
//*** Instruction Set ***
//The order of the instrucitons is important here!. Don't change
//it unles you know what you are doing. For example all the 'SET'
//family of instructions have the MSB bit in 1. This means that
//if you add an instruction and the MSB=1, this instruction will treated
//as type II (see manual) meaning the second 32bit argument is expected to be
//an inmediate value instead of a register address!
//Another example is that in the JUMP family Bits 3 and 4 have a special
//meaning: b4b3 = 01 => X jump type, b4b3 = 10 => Y jump type, finally 
//b4b3 = 11 means Z jump type.
//All this is just to tell you: Don't play with these values!

// *** Type I Instructions (OP DST REG1 REG2) ***
`define RETURN `INSTRUCTION_OP_LENGTH'b0_000000 	//0
`define ADD 	`INSTRUCTION_OP_LENGTH'b0_000001 	//1
`define SUB		`INSTRUCTION_OP_LENGTH'b0_000010 	//2
`define DIV		`INSTRUCTION_OP_LENGTH'b0_000011 	//3
`define MUL 	`INSTRUCTION_OP_LENGTH'b0_000100 	//4
`define MAG		`INSTRUCTION_OP_LENGTH'b0_000101 	//5
`define NOP		`INSTRUCTION_OP_LENGTH'b0_000110 	//6
`define COPY	`INSTRUCTION_OP_LENGTH'b0_000111 	//7
`define JGX		`INSTRUCTION_OP_LENGTH'b0_001_000  	//8
`define JLX		`INSTRUCTION_OP_LENGTH'b0_001_001	//9
`define JEQX	`INSTRUCTION_OP_LENGTH'b0_001_010 	//10
`define JNEX	`INSTRUCTION_OP_LENGTH'b0_001_011 	//11
`define JGEX	`INSTRUCTION_OP_LENGTH'b0_001_100	//12
`define JLEX	`INSTRUCTION_OP_LENGTH'b0_001_101 	//13
`define INC		`INSTRUCTION_OP_LENGTH'b0_001_110	//14
`define ZERO	`INSTRUCTION_OP_LENGTH'b0_001_111	//15
`define JGY		`INSTRUCTION_OP_LENGTH'b0_010_000  	//16
`define JLY		`INSTRUCTION_OP_LENGTH'b0_010_001 	//17
`define JEQY	`INSTRUCTION_OP_LENGTH'b0_010_010  	//18
`define JNEY	`INSTRUCTION_OP_LENGTH'b0_010_011 	//19
`define JGEY	`INSTRUCTION_OP_LENGTH'b0_010_100 	//20
`define JLEY	`INSTRUCTION_OP_LENGTH'b0_010_101  	//21
`define CROSS	`INSTRUCTION_OP_LENGTH'b0_010_110	//22
`define DOT		`INSTRUCTION_OP_LENGTH'b0_010_111	//23
`define JGZ		`INSTRUCTION_OP_LENGTH'b0_011_000 	//24
`define JLZ		`INSTRUCTION_OP_LENGTH'b0_011_001	//25
`define JEQZ	`INSTRUCTION_OP_LENGTH'b0_011_010 	//26
`define JNEZ	`INSTRUCTION_OP_LENGTH'b0_011_011	//27
`define JGEZ	`INSTRUCTION_OP_LENGTH'b0_011_100	//28
`define JLEZ	`INSTRUCTION_OP_LENGTH'b0_011_101 	//29

//The next instruction is for simulation debug only
//not to be synthetized! Pretty much behaves the same
//as a NOP, only that prints the register value to
//a log file called 'Registers.log'
`ifdef DEBUG
`define DEBUG_PRINT `INSTRUCTION_OP_LENGTH'b0_011_110	//30
`endif

`define MULP `INSTRUCTION_OP_LENGTH'b0_011_111			//31	R1.z = S1.x * S1.y
`define MOD `INSTRUCTION_OP_LENGTH'b0_100_000			//32	R = MODULO( S1,S2 )
`define FRAC `INSTRUCTION_OP_LENGTH'b0_100_001			//33	R =FractionalPart( S1 )
`define INTP `INSTRUCTION_OP_LENGTH'b0_100_010			//34	R =IntergerPart( S1 )
`define NEG  `INSTRUCTION_OP_LENGTH'b0_100_011			//35	R = -S1
`define DEC  `INSTRUCTION_OP_LENGTH'b0_100_100			//36	R = S1--
`define XCHANGEX `INSTRUCTION_OP_LENGTH'b0_100_101		//		R.x = S2.x, R.y = S1.y, R.z = S1.z
`define XCHANGEY `INSTRUCTION_OP_LENGTH'b0_100_110		//		R.x = S1.x, R.y = S2.y, R.z = S1.z
`define XCHANGEZ `INSTRUCTION_OP_LENGTH'b0_100_111		//		R.x = S1.x, R.y = S1.y, R.z = S2.z
`define IMUL     `INSTRUCTION_OP_LENGTH'b0_101_000		//		R = INTEGER( S1 * S2 )
`define UNSCALE  `INSTRUCTION_OP_LENGTH'b0_101_001		//		R = S1 >> SCALE
`define RESCALE  `INSTRUCTION_OP_LENGTH'b0_101_010		//		R = S1 << SCALE
`define INCX     `INSTRUCTION_OP_LENGTH'b0_101_011	   //    R.X = S1.X + 1
`define INCY     `INSTRUCTION_OP_LENGTH'b0_101_100	   //    R.Y = S1.Y + 1
`define INCZ     `INSTRUCTION_OP_LENGTH'b0_101_101	   //    R.Z = S1.Z + 1


//*** Type II Instructions (OP DST REG1 IMM) ***
`define SETX				`INSTRUCTION_OP_LENGTH'b1_000000 //64 
`define SETY				`INSTRUCTION_OP_LENGTH'b1_000001 //65
`define SETZ				`INSTRUCTION_OP_LENGTH'b1_000010 //66
`define SWIZZLE3D			`INSTRUCTION_OP_LENGTH'b1_000011 //67 
`define JMP					`INSTRUCTION_OP_LENGTH'b1_011_000 	//56
//-------------------------------------------------------------


`define SWIZZLE_XXX		32'd0
`define SWIZZLE_YYY		32'd1
`define SWIZZLE_ZZZ		32'd2
`define SWIZZLE_XYY		32'd3
`define SWIZZLE_XXY		32'd4
`define SWIZZLE_XZZ		32'd5
`define SWIZZLE_XXZ		32'd6
`define SWIZZLE_YXX		32'd7
`define SWIZZLE_YYX		32'd8
`define SWIZZLE_YZZ		32'd9
`define SWIZZLE_YYZ		32'd10
`define SWIZZLE_ZXX		32'd11
`define SWIZZLE_ZZX		32'd12
`define SWIZZLE_ZYY		32'd13
`define SWIZZLE_ZZY		32'd14
`define SWIZZLE_XZX		32'd15
`define SWIZZLE_XYX		32'd16
`define SWIZZLE_YXY		32'd17
`define SWIZZLE_YZY		32'd18
`define SWIZZLE_ZXZ		32'd19
`define SWIZZLE_ZYZ		32'd20
`define SWIZZLE_YXZ		32'd21




//`define REG_BUS_OWNED_BY_BCU	 0	//0000
`define REG_BUS_OWNED_BY_NULL  0 //0010
`define REG_BUS_OWNED_BY_GFU 	 1 //0001
`define REG_BUS_OWNED_BY_UCODE 2 //0011


`define OP_WIDTH				`INSTRUCTION_OP_LENGTH
`define INST_WIDTH			5


`define MULTIPLICATION 	0
`define DIVISION			1


`define ENABLE_ALU_AB	3'b001
`define ENABLE_ALU_CD	3'b010
`define ENABLE_ALU_EF	3'b100
`define ALU_CONTROL_IS_NULL 	0
`define ALU_CONTROL_IS_RGU 	1
`define ALU_CONTROL_IS_AABBIU 2
`define ALU_CONTROL_IS_CPPU	3

`define UCODE_CONTROL_IS_CU		0
`define UCODE_CONTROL_IS_IFU		1



`define FLOATING_POINT_WIDTH 32
`define FIXED_POINT_WIDTH	 32//128
`define IEEE754_BIAS		 127
`define NORMAL_EXIT			 0
`define DIVISION_BY_ZERO	 1
`define NULL					 0
`define RAY_TYPE_I		1
`define RAY_TYPE_II		2
`define RAY_TYPE_III		3

//Scheduler commands
`define SCHEDULER_NULL_COMMAND		0
`define REG_SELECTOR_WIDTH				5
//Main state machine control values
`define READ_CONFIGURATION_DATA				2
`define WRITE_NO_HIT										20
//Control values for BusUnitInterface
`define INITIAL_PROTOCOL_STATE  					0
`define GET_NEXT_CONFIGURATION_PACKET			4
`define READ_COMMAND_DATA							5
`define WAIT_FOR_CONTROL_UNIT_COMMAND			6
`define READ_COMMAND									7
`define GET_NEXT_DATA_PACKET						8
`define IDLE											9 
`define READ_CONFIGURATION_DATA_FROM_BUS		10
`define READ_TASK_DATA_FROM_BUS					12
`define WRITE_TASK_RESULTS_TO_BUS				13
`define ACK_LAST_GO_IDLE						14
`define REQUEST_BUS_FOR_WRITE_OPERATION	23
`define WAIT_FOR_BUS_WRITE_PERMISSION		24
`define WRITE_DATA_TO_BUS						25
`define ACK_BUS_READ_OPERATION				26
`define WAIT_FOR_NEXT_DATA_PACKET  			27
`define BCU_READ_LANES							28
`define CONFIGURATION_3LANE_DATA_PACKET 	12
`define BCU_WAIT_FOR_RAM_WRITE				29
`define BCU_READ_DATA_LANE_C					30
`define BCU_READ_DATA_LANE_D					31
`define BCU_WRITE_LAST_LANE_TO_RAM			32
`define BCU_WRITE_NO_HIT_TO_BUS				33
`define BCU_ACK_BUS_WRITE_DATA				34
`define BCU_REQUEST_COLOR_ACC_FROM_RAM		35
`define BCU_READ_COLOR_ACC_FROM_RAM			36
`define WAIT_FOR_CONTROL_UNIT_ACK			37
`define BCU_REQUEST_COLOR_FROM_RAM			38
`define BCU_RAM_READ_DELAY						39
`define BCU_READ_COLOR_FROM_RAM				40

`define FETCH_GEOMETRY							1

//Controlo values for RGU
`define RG_AFTER_RESET_STATE		  			1
`define RG_WAIT_FOR_CONTROL_UNIT_COMMAND 	2
`define EXECUTE_TASK_STEP1						3
`define EXECUTE_TASK_STEP2						4
`define EXECUTE_TASK_STEP3						5
`define EXECUTE_TASK_STEP4						6
`define EXECUTE_TASK_STEP5						7


//Cnotrol values for GFU
`define REQUSET_PARENT_CUBE					5
`define FETCH_CUBE_STAGE_I						6
`define FETCH_CUBE_STAGE_I_ACK				7
`define FETCH_CUBE_STAGE_II					8
`define FETCH_CUBE_STAGE_II_ACK				9
`define TRIGGER_CUBE_INTERSECTION_UNIT		10

//Control values for AABBIU
`define RAY_INSIDE_BOX_TEST					5
`define WAIT_FOR_T_DIVISION_RESULTS			6
`define CALCULE_AABB_INTERSECTION			7
`define WAIT_FOR_T_MULTIPLICATION_RESULTS	8
`define CALCULATE_AABB_HIT						9
`define AABB_WRITE_RESULTS						10

//RegisterFileVariables
`define AGENT_WRITING_VALUE_TO_REGISTER_BUS 		1
`define AGENT_READING_VALUE_FROM_REGISTER_BUS	 	0

//Division State Machine Constants
`define INITIAL_DIVISION_STATE					6'd1
`define DIVISION_REVERSE_LAST_ITERATION		6'd2
`define PRE_CALCULATE_REMAINDER					6'd3
`define CALCULATE_REMAINDER						6'd4
`define WRITE_DIVISION_RESULT						6'd5

//Square Root State Machine Constants
`define SQUARE_ROOT_LOOP					1
`define WRITE_SQUARE_ROOT_RESULT			2

//Multiplication State Machine Constants
`define MULTIPLCATION_LOOP					1
`define WRITE_MULTIPLCATION_RESULT		2

//------------------------------------

//endmodule
