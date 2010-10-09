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
input wire	                            iFlipMemory,

//Data bus for EXE Unit
input wire                              iDataWriteEnable_EXE,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataReadAddress1_EXE,
output wire[`DATA_ROW_WIDTH-1:0]        oData1_EXE,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataReadAddress2_EXE,
output wire[`DATA_ROW_WIDTH-1:0]        oData2_EXE,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataWriteAddress_EXE,
input wire[`DATA_ROW_WIDTH-1:0]         iData_EXE,

//Data bus for IO Unit
input wire                              iDataWriteEnable_IO,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataReadAddress1_IO,
output wire[`DATA_ROW_WIDTH-1:0]        oData1_IO,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataReadAddress2_IO,
output wire[`DATA_ROW_WIDTH-1:0]        oData2_IO,
input wire[`DATA_ADDRESS_WIDTH-1:0]     iDataWriteAddress_IO,
input wire[`DATA_ROW_WIDTH-1:0]         iData_IO,

//Instruction bus
input wire                              iInstructionWriteEnable,
input  wire [`ROM_ADDRESS_WIDTH-1:0]    iInstructionReadAddress1,
input  wire [`ROM_ADDRESS_WIDTH-1:0]    iInstructionReadAddress2,
input wire [`ROM_ADDRESS_WIDTH-1:0]     iInstructionWriteAddress,
input wire [`INSTRUCTION_WIDTH-1:0]     iInstruction,
output wire [`INSTRUCTION_WIDTH-1:0]    oInstruction1,
output wire [`INSTRUCTION_WIDTH-1:0]    oInstruction2,

`ifdef DEBUG
input wire [`MAX_CORES-1:0]            iDebug_CoreID,
`endif


//Control Register
input wire[15:0]	                      iControlRegister,
output wire[15:0]                       oControlRegister


);

wire [`ROM_ADDRESS_WIDTH-1:0] wROMInstructionAddress,wRAMInstructionAddress;
wire [`INSTRUCTION_WIDTH-1:0] wIMEM2_IMUX__DataOut1,wIMEM2_IMUX__DataOut2,
wIROM2_IMUX__DataOut1,wIROM2_IMUX__DataOut2;


wire wInstructionSelector,wInstructionSelector2;
FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) FFD1
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable( 1'b1 ),
	.D( iInstructionReadAddress1[`ROM_ADDRESS_WIDTH-1]  ),
	.Q( wInstructionSelector )
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) FFD2
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable( 1'b1 ),
	.D( iInstructionReadAddress2[`ROM_ADDRESS_WIDTH-1]  ),
	.Q( wInstructionSelector2 )
);

assign oInstruction1 = (wInstructionSelector == 1) ? 
	wIMEM2_IMUX__DataOut1 : wIROM2_IMUX__DataOut1;


assign oInstruction2 = (wInstructionSelector2 == 1) ? 
	wIMEM2_IMUX__DataOut2 : wIROM2_IMUX__DataOut2;	  
//-------------------------------------------------------------------
/*
Data memory.
*/
`define SMEM_START_ADDR `DATA_ADDRESS_WIDTH'd32
`define RMEM_START_ADDR `DATA_ADDRESS_WIDTH'd64
`define OMEM_START_ADDR `DATA_ADDRESS_WIDTH'd128

wire wDataWriteEnable_RMEM,wDataWriteEnable_SMEM,wDataWriteEnable_IMEM,wDataWriteEnable_OMEM;
wire [`DATA_ADDRESS_WIDTH-1:0] wDataWriteAddress_RMEM,wDataWriteAddress_SMEM;
wire [`DATA_ADDRESS_WIDTH-1:0] wDataReadAddress_RMEM1,wDataReadAddress_RMEM2;
wire [`DATA_ADDRESS_WIDTH-1:0] wDataReadAddress_SMEM1,wDataReadAddress_SMEM2;
wire [`DATA_ROW_WIDTH-1:0] wData_SMEM1,wData_SMEM2,wData_RMEM1,wData_RMEM2,wData_IMEM1,wData_IMEM2;
wire [`DATA_ROW_WIDTH-1:0] wIOData_SMEM1,wIOData_SMEM2,wData_OMEM1,wData_OMEM2;
/*
always @ (posedge Clock)
begin
	if (wDataWriteEnable_OMEM)
	$display("%dns OMEM Writting %h to Addr %d (%h)",
	$time,iData_EXE,iDataWriteAddress_EXE,iDataWriteAddress_EXE);
	
	//if (iDataReadAddress1_IO >= 130)
	//$display("%dns OMEM Readin %h from %d (%h)",
	//$time,wData_OMEM1,iDataReadAddress1_IO,iDataReadAddress1_IO);
	
end
*/
assign wDataWriteEnable_OMEM =
(iDataWriteAddress_EXE >= `OMEM_START_ADDR ) 
? 	iDataWriteEnable_EXE : 1'b0;

assign wDataWriteEnable_IMEM =
(iDataWriteAddress_IO <  `SMEM_START_ADDR )
? 	iDataWriteEnable_IO :  1'b0;

assign wDataWriteEnable_SMEM  = 
(iDataWriteAddress_EXE >= `SMEM_START_ADDR && iDataWriteAddress_EXE < `RMEM_START_ADDR) 
? 	iDataWriteEnable_EXE : 1'b0;


assign wDataWriteEnable_RMEM  = 
(iDataWriteAddress_EXE  >= `RMEM_START_ADDR && iDataWriteAddress_EXE < `OMEM_START_ADDR) 
? 	iDataWriteEnable_EXE : 1'b0;


assign wDataWriteAddress_RMEM = iDataWriteAddress_EXE;
assign wDataReadAddress_RMEM1 = iDataReadAddress1_EXE;
assign wDataReadAddress_RMEM2 = iDataReadAddress2_EXE;
assign wDataWriteAddress_SMEM = iDataWriteAddress_EXE;
assign wDataReadAddress_SMEM1 = iDataReadAddress1_EXE;
assign wDataReadAddress_SMEM2 = iDataReadAddress2_EXE;

//assign oData1_EXE = ( iDataReadAddress1_EXE < `RMEM_START_ADDR ) ? wData_SMEM1 : wData_RMEM1;
assign oData1_EXE = ( iDataReadAddress1_EXE < `RMEM_START_ADDR ) ? 
( ( iDataReadAddress1_EXE < `SMEM_START_ADDR ) ? wData_IMEM1 : wData_SMEM1  )
: wData_RMEM1;

//assign oData2_EXE = ( iDataReadAddress2_EXE < `RMEM_START_ADDR ) ? wData_SMEM2 : wData_RMEM2;
assign oData2_EXE = ( iDataReadAddress2_EXE < `RMEM_START_ADDR ) ? 
( ( iDataReadAddress2_EXE < `SMEM_START_ADDR ) ? wData_IMEM2 : wData_SMEM2  )
: wData_RMEM2;


assign oData1_IO = ( iDataReadAddress1_IO < `OMEM_START_ADDR ) ? wIOData_SMEM1 : wData_OMEM1;
assign oData2_IO = ( iDataReadAddress2_IO < `OMEM_START_ADDR ) ? wIOData_SMEM2 : wData_OMEM2;


//Output registers written by EXE, Read by IO
RAM_DUAL_READ_PORT  # (`DATA_ROW_WIDTH,`DATA_ADDRESS_WIDTH,512) OMEM
(
	.Clock( Clock ),
	.iWriteEnable( wDataWriteEnable_OMEM ),
	.iReadAddress0( iDataReadAddress1_IO ),
	.iReadAddress1( iDataReadAddress2_IO ),
	.iWriteAddress( iDataWriteAddress_EXE ),
	.iDataIn( iData_EXE ),
	.oDataOut0( wData_OMEM1 ),
	.oDataOut1( wData_OMEM2 )
);

//Input Registers, Written by IO, Read by EXE
RAM_DUAL_READ_PORT  # (`DATA_ROW_WIDTH,`DATA_ADDRESS_WIDTH,42) IMEM
(
	.Clock( Clock ),
	.iWriteEnable( wDataWriteEnable_IMEM ),
	.iReadAddress0( iDataReadAddress1_EXE ),
	.iReadAddress1( iDataReadAddress2_EXE ),
	.iWriteAddress( iDataWriteAddress_IO ),
	.iDataIn( iData_IO ),
	.oDataOut0( wData_IMEM1 ),
	.oDataOut1( wData_IMEM2 )
);

//Swap registers, while IO reads/write values, EXE reads/write values
//the pointers get filped in the next iteration
SWAP_MEM  # (`DATA_ROW_WIDTH,`DATA_ADDRESS_WIDTH,512) SMEM
(
	.Clock( Clock ),
	.iSelect( wFlipSelect ),
	
	.iWriteEnableA( wDataWriteEnable_SMEM ),
	.iReadAddressA0( wDataReadAddress_SMEM1 ),
	.iReadAddressA1( wDataReadAddress_SMEM2 ),
	.iWriteAddressA( wDataWriteAddress_SMEM ),
	.iDataInA( iData_EXE ),
	.oDataOutA0( wData_SMEM1 ),
	.oDataOutA1( wData_SMEM2 ),
	
	.iWriteEnableB( iDataWriteEnable_IO ),
	.iReadAddressB0( iDataReadAddress1_IO ),
	.iReadAddressB1( iDataReadAddress2_IO ),
	.iWriteAddressB( iDataWriteAddress_IO ),
	.iDataInB( iData_IO ),
	.oDataOutB0( wIOData_SMEM1 ),
	.oDataOutB1( wIOData_SMEM2 )
	
); 

//General purpose registers, EXE can R/W, IO can not see these sections
//of the memory
RAM_DUAL_READ_PORT  # (`DATA_ROW_WIDTH,`DATA_ADDRESS_WIDTH,256) RMEM
(
	.Clock( Clock ),
	.iWriteEnable( wDataWriteEnable_RMEM ),
	.iReadAddress0( wDataReadAddress_RMEM1 ),
	.iReadAddress1( wDataReadAddress_RMEM2 ),
	.iWriteAddress( wDataWriteAddress_RMEM ),
	.iDataIn( iData_EXE ),
	.oDataOut0( wData_RMEM1 ),
	.oDataOut1( wData_RMEM2 )
);

wire wFlipSelect;
UPCOUNTER_POSEDGE # (1) UPC1
(
.Clock(Clock),
.Reset( Reset ),
.Initial(1'b0),
.Enable(iFlipMemory),
.Q(wFlipSelect)
);



//-------------------------------------------------------------------
/*
Instruction memory.
*/ 
RAM_DUAL_READ_PORT  # (`INSTRUCTION_WIDTH,`ROM_ADDRESS_WIDTH,512) INST_MEM
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
	`ifdef DEBUG
	.iDebug_CoreID(iDebug_CoreID),
	`endif
	.I( wRomDelay1 )
);

ROM IROM2
(
	.Address( {1'b0,iInstructionReadAddress2[`ROM_ADDRESS_WIDTH-2:0]} ),
	`ifdef DEBUG
	.iDebug_CoreID(iDebug_CoreID),
	`endif
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