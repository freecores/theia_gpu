`timescale 1ns / 1ps
`include "aDefinitions.v"
/**********************************************************************************
Theia, Ray Cast Programable graphic Processing Unit.
Copyright (C) 2010  Diego Valverde (diego.valverde.g@gmail.com)

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
/*
The memory unit has all the memory related modules for THEIA.
There a 3 memories in the core: 
DMEM: The data memory, it is a R/W dual channel RAM, stores the data locations.
IMEM: The instruction memory, R/W dual channel RAM, stores user shaders.
IROM: RO instruction memory, stores default shaders and other internal code.
I use two ROMs with the same data, so that simulates dual channel. 
This unit also has a Control register.
*/
`define USER_CODE_ENABLED 2
//-------------------------------------------------------------------
module MemoryUnit
(
input wire                              Clock,
input wire                              Reset,
input wire                              iDataWriteEnable,
input wire                              iInstructionWriteEnable,
input  wire [`ROM_ADDRESS_WIDTH-1:0]    iInstructionReadAddress1,
input  wire [`ROM_ADDRESS_WIDTH-1:0]    iInstructionReadAddress2,
input wire [`ROM_ADDRESS_WIDTH-1:0]     iInstructionWriteAddress,
output wire [`INSTRUCTION_WIDTH-1:0]    oInstruction1,
output wire [`INSTRUCTION_WIDTH-1:0]    oInstruction2,
input wire [`INSTRUCTION_WIDTH-1:0]     iInstruction,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataReadAddress1,
input wire[`DATA_ROW_WIDTH-1:0]         oData1,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataReadAddress2,
input wire[`DATA_ROW_WIDTH-1:0]         oData2,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataWriteAddress,
input wire[`DATA_ROW_WIDTH-1:0]         iData,
input wire[15:0]	                      iControlRegister,
output wire[15:0]                       oControlRegister

);

wire [`ROM_ADDRESS_WIDTH-1:0] wROMInstructionAddress,wRAMInstructionAddress;
wire [`INSTRUCTION_WIDTH-1:0] wIMEM2_IMUX__DataOut1,wIMEM2_IMUX__DataOut2,
wIROM2_IMUX__DataOut1,wIROM2_IMUX__DataOut2;


wire wInstructionSelector;
FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) FFD1
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable( 1'b1 ),
	.D( iInstructionReadAddress1[`ROM_ADDRESS_WIDTH-1]  ),
	.Q( wInstructionSelector )
);

assign oInstruction1 = (wInstructionSelector == 1) ? 
	wIMEM2_IMUX__DataOut1 : wIROM2_IMUX__DataOut1;


assign oInstruction2 = (wInstructionSelector == 1) ? 
	wIMEM2_IMUX__DataOut2 : wIROM2_IMUX__DataOut2;	  
//-------------------------------------------------------------------
/*
Data memory.
*/
RAM_128_ROW_DUAL_READ_PORT  # (`DATA_ROW_WIDTH,`DATA_ADDRESS_WIDTH) DMEM
(
	.Clock( Clock ),
	.iWriteEnable( iDataWriteEnable ),
	.iReadAddress0( iDataReadAddress1 ),
	.iReadAddress1( iDataReadAddress2 ),
	.iWriteAddress( iDataWriteAddress ),
	.iDataIn( iData ),
	.oDataOut0( oData1 ),
	.oDataOut1( oData2 )
);
//-------------------------------------------------------------------
/*
Instruction memory.
*/ 
RAM_128_ROW_DUAL_READ_PORT  # (`INSTRUCTION_WIDTH,`ROM_ADDRESS_WIDTH) IMEM
(
	.Clock( Clock ),
	.iWriteEnable( iInstructionWriteEnable ),
	.iReadAddress0( {1'b0,iInstructionReadAddress1[`ROM_ADDRESS_WIDTH-2:0]} ),
	.iReadAddress1( {1'b0,iInstructionReadAddress2[`ROM_ADDRESS_WIDTH-2:0]} ),
	.iWriteAddress( iInstructionWriteAddress ),
	.iDataIn( iInstruction ),
	.oDataOut0( wIMEM2_IMUX__DataOut1 ),
	.oDataOut1( wIMEM2_IMUX__DataOut2 )
	
);
//-------------------------------------------------------------------
/*
 Default code stored in ROM.
*/
wire [`INSTRUCTION_WIDTH-1:0] wRomDelay1,wRomDelay2;
//In real world ROM will take at least 1 clock cycle,
//since ROMs are not syhtethizable, I won't hurt to put
//this delay

FFD_POSEDGE_SYNCRONOUS_RESET # ( `INSTRUCTION_WIDTH ) FFDA
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wRomDelay1),
	.Q(wIROM2_IMUX__DataOut1 )
);


FFD_POSEDGE_SYNCRONOUS_RESET # ( `INSTRUCTION_WIDTH ) FFDB
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wRomDelay2),
	.Q(wIROM2_IMUX__DataOut2 )
);

//The reason I put two ROMs is because I need to read 2 different Instruction 
//addresses at the same time (branch-taken and branch-not-taken) and not sure
//hpw to write dual read channel ROM this way...

ROM IROM
(
	.Address( {1'b0,iInstructionReadAddress1[`ROM_ADDRESS_WIDTH-2:0]} ),
	.I( wRomDelay1 )
);

ROM IROM2
(
	.Address( {1'b0,iInstructionReadAddress2[`ROM_ADDRESS_WIDTH-2:0]} ),
	.I( wRomDelay2 )
);
//--------------------------------------------------------
ControlRegister CR
(
	.Clock( Clock ),
	.Reset( Reset ),
	.iControlRegister( iControlRegister ),
	.oControlRegister( oControlRegister )
);


endmodule
//-------------------------------------------------------------------