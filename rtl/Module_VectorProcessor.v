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
//--------------------------------------------------------

module VectorProcessor
(
	input wire                          Clock,
	input wire                          Reset,
	input wire                          iEnable,
	input wire [`CBC_BUS_WIDTH-1:0]     iCpCommand,
	input wire [`VPID_WIDTH-1:0]        iVPID,
	input wire                          MCU_WE_I,
	input wire                          MCU_MST_I,
	input wire                          MCU_STB_I,
	input wire                          MCU_CYC_I,
	input wire [`MCU_TAG_SIZE-1:0]      MCU_TAG_I,
	input wire [`WB_WIDTH-1:0]          MCU_DAT_I,
	input wire [`WB_WIDTH-1:0]          MCU_ADR_I,
	output wire                         MCU_ACK_O,
	output wire                         OMEM_WE,
	output wire [`WB_WIDTH-1:0]        	OMEM_ADDR,
	output wire [`WB_WIDTH-1:0]     	   OMEM_DATA
	
	

);
wire [`INSTRUCTION_ADDR_WIDTH-1:0] wIO_2_MEM__InstructionWriteAddress;
wire [`INSTRUCTION_WIDTH-1:0]      wIO_2_MEM__Instruction;
wire                               wIO_2_MEM__InstructionWriteEnable;
wire                               wControl_2_Exe_Enabled;
wire [`DATA_ROW_WIDTH-1:0]         wEXE_2_IO__OMEM_WriteAddress;
wire [`DATA_ROW_WIDTH-1:0]         wEXE_2_IO__OMEM_WriteData;
wire                               wEXE_2_IO__OMEM_WriteEnable;


ControlUnit CONTROL
(
.Clock(       Clock                  ),
.Reset(       Reset                  ),
.iCpCommand(  iCpCommand             ),
.iVPID(       iVPID                  ),
.oVpEnabled(  wControl_2_Exe_Enabled )
);



Unit_IO IO
(
//WB Input signals
.CLK_I(                     Clock            ),
.RST_I(                     Reset            ),
.MCU_STB_I(                 MCU_STB_I        ),
.MCU_WE_I(                  MCU_WE_I         ),
.MCU_DAT_I(                 MCU_DAT_I        ),
.MCU_ADR_I(                 MCU_ADR_I        ),
.MCU_TGA_I(                 MCU_TAG_I        ),
.MCU_ACK_O(                 MCU_ACK_O        ),
.MCU_MST_I(                 MCU_MST_I        ),
.MCU_CYC_I(                 MCU_CYC_I        ),

//.oDataWriteAddress,
//.oDataBus,
.oInstructionWriteAddress(  wIO_2_MEM__InstructionWriteAddress ),
.oInstructionBus(           wIO_2_MEM__Instruction             ),
//.oDataWriteEnable(         wIO_2_MEM__DataWriteEnable  ),
.oInstructionWriteEnable(    wIO_2_MEM__InstructionWriteEnable  ),

.iOMEM_WriteAddress(          wEXE_2_IO__OMEM_WriteAddress     ),
.iOMEM_WriteData(             wEXE_2_IO__OMEM_WriteData        ),
.iOMEM_WriteEnable(           wEXE_2_IO__OMEM_WriteEnable      ),
.OMEM_DAT_O(                  OMEM_DATA                        ),
.OMEM_ADR_O(                  OMEM_ADDR                        ),
.OMEM_WE_O(                   OMEM_WE                          )



);

Unit_Execution EXE 
(
.Clock(                        Clock                                 ), 
.Reset(                        Reset                                 ), 
.iEnable(                      wControl_2_Exe_Enabled                ),
.iInstructionMem_WriteAddress( wIO_2_MEM__InstructionWriteAddress    ),
.iInstructionMem_WriteEnable(  wIO_2_MEM__InstructionWriteEnable     ),
.iInstructionMem_WriteData(    wIO_2_MEM__Instruction                ),
.oOMEMWriteAddress(            wEXE_2_IO__OMEM_WriteAddress          ),
.oOMEMWriteData(               wEXE_2_IO__OMEM_WriteData             ),
.oOMEMWriteEnable(             wEXE_2_IO__OMEM_WriteEnable           )

);
	
endmodule
