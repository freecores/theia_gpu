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
	In order to read the geometry, we will behave as a master.
	Performing single Reads Bus cycles should be sufficient. 
	Choosing 32 bit for bus width for simplicity.
*/

module WishBoneMasterUnit
(
//WB Input signals
input wire 						   CLK_I,
input wire						   RST_I,
input wire 						   ACK_I,
input wire [`WB_WIDTH-1:0 ] 	DAT_I,
output wire [`WB_WIDTH-1:0]   DAT_O,


//WB Output Signals
output wire [`WB_WIDTH-1:0 ] ADR_O,
output wire 				     WE_O,
output wire 				     STB_O,
output wire  				     CYC_O,
output wire [1:0]			     TGC_O,

//Signals from inside the GPU
input wire 					 	iEnable,
input wire                 iBusCyc_Type,
input wire [`WIDTH-1:0 ] 	iAddress,
input wire                 iAddress_Set,
output wire					 	oDataReady,
input wire  [`WIDTH-1:0 ]  iData,
output wire	[`WIDTH-1:0 ]  oData
				 

);
wire wReadOperation;
//assign ADR_O = iAddress;
assign wReadOperation = (iBusCyc_Type == `WB_SIMPLE_READ_CYCLE) ? 1 : 0;
assign WE_O = (iBusCyc_Type == `WB_SIMPLE_WRITE_CYCLE && iEnable) ? 1 : 0;

assign STB_O = iEnable & ~ACK_I;
assign CYC_O = iEnable;

assign DAT_O = (wReadOperation | ~iEnable ) ? `WB_WIDTH'bz : iData;


//The ADR_O, it increments with each ACK_I, and it resets
//to the value iAddress everytime iAddress_Set is 1.
UPCOUNTER_POSEDGE # (`WIDTH) WBM_O_ADDRESS
(
	.Clock(CLK_I), 
	.Reset( iAddress_Set ),
	.Enable(ACK_I | iAddress_Set),
	.Initial(iAddress),
	.Q(ADR_O)
);



FFD_POSEDGE_SYNCRONOUS_RESET # ( `WIDTH ) FFD1
(
	.Clock(ACK_I),
	.Reset(~iEnable),
	.Enable(wReadOperation),
	.D(DAT_I),
	.Q(oData)
);

wire wDelayDataReady;
FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) FFD2
(
	.Clock(CLK_I),
	.Reset(~iEnable),
	.Enable(wReadOperation),
	.D(ACK_I),
	.Q(wDelayDataReady)
);
/*
always @ (posedge wDelayDataReady)
begin
	$display("WBM Got data: %h ",oData);
	$display("oDataReady = %d",oDataReady );
end
*/

assign oDataReady = wDelayDataReady & iEnable;

endmodule

