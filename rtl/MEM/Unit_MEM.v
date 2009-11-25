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
DMEM: The data memory, it is a R/W RAM, stores the data locations.
IMEM: The instruction memory, R/W RAM, stores user shaders.
IROM: RO instruction memory, stores default shaders and other internal code.
This unit also has a Control register.
*/
//-------------------------------------------------------------------
module MemoryUnit
(
input wire                              Clock,
input wire                              Reset,
input wire                              iDataWriteEnable,
input wire                              iInstructionWriteEnable,
input  wire [`ROM_ADDRESS_WIDTH-1:0]    iInstructionReadAddress,
input wire [`ROM_ADDRESS_WIDTH-1:0]     iInstructionWriteAddress,
output wire [`INSTRUCTION_WIDTH-1:0]    oInstruction,
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
wire [`INSTRUCTION_WIDTH-1:0] wIMEM2_IMUX__DataOut,wIROM2_IMUX__DataOut;


assign oInstruction = (iInstructionReadAddress[`ROM_ADDRESS_WIDTH-1] == 1) ? 
	wIMEM2_IMUX__DataOut : wIROM2_IMUX__DataOut;

//-------------------------------------------------------------------
/*
Data memory.
*/
RAM_DATA DMEM
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
RAM_INST IMEM
(
	.Clock( Clock ),
	.iWriteEnable( iInstructionWriteEnable ),
	.iReadAddress( iInstructionReadAddress ),
	.iWriteAddress( iInstructionWriteAddress ),
	.iDataIn( iInstruction ),
	.oDataOut( wIMEM2_IMUX__DataOut )
	
);
//-------------------------------------------------------------------
/*
 Default code stored in ROM.
*/
ROM IROM
(
	.Address( iInstructionReadAddress ),
	.I(  wIROM2_IMUX__DataOut )
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