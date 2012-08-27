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

module THEIA
(
	input wire         Clock,
	input wire         Reset,
	input wire         iEnable,
	input wire [31:0]  iMemReadData,				//Data read from Main memory
	input wire         iMemDataAvailable,
	output wire [31:0] oMemReadAddress,
	output wire        oMEM_ReadRequest

);


wire [`WB_WIDTH-1:0]              wMCU_2_VP_InstructionWriteAddress;
wire  [`WB_WIDTH-1:0]             wMCU_2_VP_InstructionWriteData;
wire   [`MAX_CORES-1:0]           wMCU_2_VP_InstructionWriteEnable;
wire [`MCU_TAG_SIZE-1:0]          wMCU_2_VP_Tag;
wire                              wMCU_2_VP_STB;
wire                              wMCU_2_VP_Cyc;
wire                              wMCU_2_VP_Mst;
wire  [`MAX_CORES-1:0]            wVP_2_MCU_ACK;
wire                              wVP_Slave_ACK;
wire [`MCU_REQUEST_SIZE-1:0]      wCP_2MCU_BlockCopyCommand;
wire[`CBC_BUS_WIDTH-1:0]          wCP_VP__ControlCommandBus;
wire                              wMCU_2_CP__FIFOEmpty;
wire                              wOMem_WE[`MAX_CORES-1:0];
wire [`WB_WIDTH-1:0]              wOMEM_Address[`MAX_CORES-1:0];
wire [`WB_WIDTH-1:0]              wOMEM_Dat[`MAX_CORES-1:0];


//////////////////////////////////////////////
//
// The control processor
//
//////////////////////////////////////////////
ControlProcessor CP 
(
		.Clock(               Clock                     ), 
		.Reset(               Reset                     ), 
		.oControlBus(         wCP_VP__ControlCommandBus ),
		.iMCUFifoEmpty(       wMCU_2_CP__FIFOEmpty      ),
		.oCopyBlockCommand(   wCP_2MCU_BlockCopyCommand )
);

//////////////////////////////////////////////
//
// The control processor
//
//////////////////////////////////////////////
assign wVP_Slave_ACK = wVP_2_MCU_ACK[0] | wVP_2_MCU_ACK[1] | wVP_2_MCU_ACK[2] | wVP_2_MCU_ACK[3];

MemoryController #(`MAX_CORES) MCU
(
		.Clock(                  Clock                             ), 
		.Reset(                  Reset                             ), 
		.iRequest(               wCP_2MCU_BlockCopyCommand         ),
		.oMEM_ReadAddress(       oMemReadAddress                   ),
		.oMEM_ReadRequest(       oMEM_ReadRequest                  ),
		.oFifoEmpty(             wMCU_2_CP__FIFOEmpty              ),
		.iMEM_ReadData(          iMemReadData                      ),
		.iMEM_DataAvailable(     iMemDataAvailable                 ),
		.DAT_O(                  wMCU_2_VP_InstructionWriteData    ),
		.ADR_O(                  wMCU_2_VP_InstructionWriteAddress ),
		.STB_O(                  wMCU_2_VP_STB                     ),
		.WE_O(                   wMCU_2_VP_InstructionWriteEnable  ),
		.TAG_O(                  wMCU_2_VP_Tag                     ),
		.CYC_O(                  wMCU_2_VP_Cyc                     ),
		.MST_O(                  wMCU_2_VP_Mst                     ),
		.ACK_I(                  wVP_Slave_ACK                     )
);

//////////////////////////////////////////////
//
// The vector processors
//
//////////////////////////////////////////////
genvar i;
  generate
	for (i = 0; i < `MAX_CORES; i = i +1)
	begin : VPX
	
	VectorProcessor VP 
	(
		.Clock(           Clock                                 ), 
		.Reset(           Reset                                 ), 
		.iEnable(         iEnable                               ),
		.iVPID(           i+1                                   ),
		.iCpCommand(      wCP_VP__ControlCommandBus             ),
		.MCU_STB_I(       wMCU_2_VP_STB                         ),
      .MCU_WE_I(        wMCU_2_VP_InstructionWriteEnable[i]   ),
      .MCU_DAT_I(       wMCU_2_VP_InstructionWriteData        ),
      .MCU_ADR_I(       wMCU_2_VP_InstructionWriteAddress     ),
      .MCU_TAG_I(       wMCU_2_VP_Tag                         ),
      .MCU_ACK_O(       wVP_2_MCU_ACK[i]                      ),
      .MCU_MST_I(       wMCU_2_VP_Mst                         ),
      .MCU_CYC_I(       wMCU_2_VP_Cyc                         ),
		.OMEM_WE(         wOMem_WE[i]                            ),
		.OMEM_ADDR(       wOMEM_Address[i]                       ),
		.OMEM_DATA(       wOMEM_Dat[i]                           )

	
	);
	
	RAM_SINGLE_READ_PORT # ( `WB_WIDTH, `WB_WIDTH, `OMEM_SIZE ) OMEM 
	(
	  .Clock(         Clock                ),
	  .iWriteEnable(  wOMem_WE[i]          ),
	  .iWriteAddress( wOMEM_Address[i]     ),
	  .iDataIn(       wOMEM_Dat[i]         ),
	  .iReadAddress0( wOMEM_Address[i]     )
	  //.oDataOut0(     wOMEM_Dat[i]         )
	  
	);

	end // for
endgenerate


endmodule
