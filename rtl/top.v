

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


/*******************************************************************************
Module Description:

This is the top module that connects the GPU with the HOST and the HUB/SWITCH.

*******************************************************************************/



`timescale 1ns / 1ps
`include "aDefinitions.v"
`ifdef VERILATOR
`include "Theia.v"
`endif
module top
(
input wire                        Clock,
input wire                        Reset,
input wire                        iHostEnable,
output wire[`WB_WIDTH-1:0]        oHostReadAddress,
input wire[`WB_WIDTH-1:0]         iMemorySize,
output wire[1:0]                  oMemSelect,
input wire [`WB_WIDTH-1:0]        iInstruction,
input wire [`WB_WIDTH-1:0]        iParameter,
input wire [`WB_WIDTH-1:0]        iVertex,
input wire [`WB_WIDTH-1:0]        iControlRegister,
input wire[`WIDTH-1:0]            iPrimitiveCount,
input wire [`WB_WIDTH-1:0]        iTMEMAdr,
input wire [`WB_WIDTH-1:0]        iTMEMData,
input wire                        iTMEM_WE,
input wire [`MAX_TMEM_BANKS-1:0]  iTMEM_Sel,
input wire  [`MAX_CORE_BITS-1:0]  iOMEMBankSelect,
input  wire [`WB_WIDTH-1:0]       iOMEMReadAddress,
output wire [`WB_WIDTH-1:0]       oOMEMData,   //Output data bus (Wishbone)
`ifndef NO_DISPLAY_STATS
	input wire [`WIDTH-1:0] iDebugWidth,
`endif
output wire                       oDone


);

assign oMemSelect =  wMemSelect;

 wire [`WB_WIDTH-1:0]       wHost_2__DAT_O;
 reg                        wHost_2__ACK;
 wire                       wGPU_2__ACK;
 wire [`WB_WIDTH-1:0]       ADR_I,wHost_2__ADR_O;
 wire                       WE_I,STB_I;
 wire [1:0]                 wHost_2__TGA_O;
 wire [1:0]                 TGA_I;
 wire [`MAX_CORES-1:0]      wCoreSelect;
 wire                       wHost_2__MST_O;
 wire                       wGPU_2_HOST_Done;
 wire [`MAX_CORES-1:0]      wHost_2__RENDREN_O;
 wire                       wGPU_2__HOST_HDL;
 wire                       wHost_2__WE_O;
 wire                       wHost_2__STDONE;
 wire                       wGPUCommitedResults;
 wire                       wHostDataAvailable;
 wire                       wHost_2__CYC_O,wHost_2__GACK_O,TGC_O,wHost_2__STB_O;

assign oDone = wGPU_2_HOST_Done;

THEIA GPU 
  (
  .CLK_I(     Clock              ), 
  .RST_I(     Reset              ), 
  .RENDREN_I( wHost_2__RENDREN_O ),
  .DAT_I(     wHost_2__DAT_O     ),
  .ACK_I(     wHost_2__ACK       ),
  .CYC_I(     wHost_2__CYC_O     ),
  .MST_I(     wHost_2__MST_O     ),
  .TGA_I(     wHost_2__TGA_O     ),
  .ACK_O(     wGPU_2__ACK        ),
  .ADR_I(     wHost_2__ADR_O     ),
  .WE_I(      wHost_2__WE_O      ),
  .SEL_I(     wCoreSelect        ),
  .STB_I(     wHost_2__STB_O     ),
  
  //O-Memory
  .OMBSEL_I(  iOMEMBankSelect  ),
  .OMADR_I(   iOMEMReadAddress ),
  .OMEM_O(    oOMEMData        ),
  //T-Memory
  .TMDAT_I(   iTMEMData        ),
  .TMADR_I(   iTMEMAdr         ),
  .TMWE_I(    iTMEM_WE         ),
  .TMSEL_I(   iTMEM_Sel        ),
  .HDL_O(     wGPU_2__HOST_HDL    ),
  .HDLACK_I(  wHost_2__GACK_O     ),
  .STDONE_I(  wHost_2__STDONE     ),
  .RCOMMIT_O( wGPUCommitedResults ),
  .HDA_I(     wHostDataAvailable  ),
  .CREG_I(    iControlRegister[15:0]    ),
  .DONE_O(    wGPU_2_HOST_Done    )

 );


wire[1:0] wMemSelect;
wire[`WB_WIDTH-1:0] wHostReadData;

MUXFULLPARALELL_2SEL_GENERIC # ( `WB_WIDTH ) MUX1
 (
.Sel( wMemSelect    ),
.I1(  iInstruction  ),
.I2(  iParameter    ),
.I3(  iVertex       ),
.I4(  0             ),
.O1(  wHostReadData )
 );

Module_Host HOST
(
 .Clock(                  Clock                ),
 .Reset(                  Reset                ),
 .iEnable(                iHostEnable          ),
 .oHostDataAvailable(     wHostDataAvailable   ),
 .iHostDataReadConfirmed( wGPU_2__HOST_HDL     ),
 .iMemorySize(            iMemorySize          ),
 .iPrimitiveCount(        iPrimitiveCount      ),  
 .iGPUCommitedResults(    wGPUCommitedResults  ),
 .STDONE_O(               wHost_2__STDONE      ),
 .iGPUDone(               wGPU_2_HOST_Done     ),
 
`ifndef NO_DISPLAY_STATS
 .iDebugWidth(iDebugWidth),
`endif

 //To Memory
.oReadAddress( oHostReadAddress ),
.iReadData(    wHostReadData ),
 
 //To Hub/Switch
.oCoreSelectMask( wCoreSelect        ),
.oMemSelect(      wMemSelect         ),
.DAT_O(           wHost_2__DAT_O     ),
.ADR_O(           wHost_2__ADR_O     ),
.TGA_O(           wHost_2__TGA_O     ),
.RENDREN_O(       wHost_2__RENDREN_O ),
.CYC_O(           wHost_2__CYC_O     ),
.STB_O(           wHost_2__STB_O     ),
.MST_O(           wHost_2__MST_O     ),
.GRDY_I(          wGPU_2__HOST_HDL   ),
.GACK_O(          wHost_2__GACK_O    ),
.WE_O(            wHost_2__WE_O      ),
.ACK_I(           wGPU_2__ACK        )
);
 

endmodule
