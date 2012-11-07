`timescale 1ns / 1ps
`include "aDefinitions.v"



`define TAG_WBS_INSTRUCTION_ADDRESS_TYPE 2'b10
`define TAG_WBS_DATA_ADDRESS_TYPE    2'b01
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
//------------------------------------------------------------------------------
module Unit_IO
(
//WB Input signals
input wire 						                 CLK_I,
input wire						                 RST_I,
input wire                                  MCU_STB_I,
input wire                                  MCU_WE_I,
input wire[`WB_WIDTH-1:0]                   MCU_DAT_I,
input wire[`WB_WIDTH-1:0]                   MCU_ADR_I,
input wire [1:0]                            MCU_TGA_I,
output wire                                 MCU_ACK_O,
input wire                                  MCU_MST_I,   
input wire                                  MCU_CYC_I,

//Internal Slave signals
output wire[`DATA_ADDRESS_WIDTH-1:0] 	     oDataWriteAddress,
output wire [`DATA_ROW_WIDTH-1:0]		     oDataBus,
output wire [`INSTRUCTION_ADDR_WIDTH-1:0]   oInstructionWriteAddress,
output wire [`INSTRUCTION_WIDTH-1:0]	     oInstructionBus,
output wire										     oDataWriteEnable,
output wire										     oInstructionWriteEnable,

//Output memory
input wire [`DATA_ROW_WIDTH-1:0]            iOMEM_WriteAddress,
input wire [`DATA_ROW_WIDTH-1:0]            iOMEM_WriteData,
input wire                                  iOMEM_WriteEnable,
output wire [`WB_WIDTH-1:0]                 OMEM_DAT_O,
output wire [`WB_WIDTH-1:0]                 OMEM_ADR_O,
output wire 					                 OMEM_WE_O,

//TMem

output wire [`DATA_ROW_WIDTH-1:0] oTMEMReadData,
input wire 								 iTMEMDataRequest,
input wire 	[`DATA_ROW_WIDTH-1:0] iTMEMReadAddress,	
output wire 							 oTMEMDataAvailable, 

input wire                  TMEM_ACK_I,
input wire [`WB_WIDTH-1:0]  TMEM_DAT_I , 
output wire [`WB_WIDTH-1:0] TMEM_ADR_O ,
output wire                 TMEM_WE_O,
output wire                 TMEM_STB_O,
output wire                 TMEM_CYC_O,
input wire                  TMEM_GNT_I

);


WishBoneSlaveUnit WBS
(
//WB Input signals
.CLK_I( CLK_I),
.RST_I( RST_I ),
.STB_I( MCU_STB_I ),
.WE_I(  MCU_WE_I  ),
.DAT_I( MCU_DAT_I ),
.ADR_I( MCU_ADR_I ),
.TGA_I( MCU_TGA_I ),
.ACK_O( MCU_ACK_O ),
.MST_I( MCU_MST_I ),
.CYC_I( MCU_CYC_I ),

.oDataWriteAddress(         oDataWriteAddress               ),
.oDataBus(                  oDataBus                        ),
.oInstructionWriteAddress(  oInstructionWriteAddress        ),
.oInstructionBus(           oInstructionBus                 ),
.oDataWriteEnable(          oDataWriteEnable                ),
.oInstructionWriteEnable(   oInstructionWriteEnable         )

);


Module_OMemInterface OMI
(
	.Clock(        CLK_I              ),
	.Reset(        RST_I              ),
	.iWriteEnable( iOMEM_WriteEnable  ),
	.iData(        iOMEM_WriteData    ),
	.iAddress(     iOMEM_WriteAddress ),
	.ADR_O(        OMEM_ADR_O         ),
	.DAT_O(        OMEM_DAT_O         ),
	.WE_O(         OMEM_WE_O          )
	
);



Module_TMemInterface TMI
(
	.Clock( CLK_I ),
	.Reset( RST_I ),
	.iEnable(  iTMEMDataRequest   ),
	.iAddress( iTMEMReadAddress   ),	
	.oData(    oTMEMReadData      ),
	.oDone(    oTMEMDataAvailable ),

	.ACK_I( TMEM_ACK_I ),
	.GNT_I( TMEM_GNT_I ), 
	.DAT_I( TMEM_DAT_I ),
	.ADR_O( TMEM_ADR_O ),
	.WE_O(  TMEM_WE_O  ),
	.STB_O( TMEM_STB_O ),
	.CYC_O( TMEM_CYC_O )	
	

);

endmodule
