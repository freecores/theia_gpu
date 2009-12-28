
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
/**
	The Wish Bone bus has a 32 bit words.
	However our internal bus is 96 bits (32 * 3) bits wide 
	for Data or 64 bits wide for Instructions (Hardvard Architecture).
	If the iStore signal is one, WBM2MEMUnit provides a means to 
	store 2 or 3 incomming 32 bits frames into temporary Flip-Flops,
	and then store the 96 or 64 bit value into a specified location 
	in the internal Instruction or Data Memory.
	If the iStore signal is zero, WBMinputFifo passes the
	32 bit value comming from the WB bus, directly through the oData
	pin without storing it.
*/ 

module WBM2MEMUnit
(
	input wire									Clock,
	input wire									Reset,
	input wire									iEnable,
	input	wire									iStore,
	input	wire[`DATA_ADDRESS_WIDTH-1:0] 	iAdr_DataWriteBack,
	input	wire									iWBMDataAvailable,
	input wire                          iWriteBack_Set,
	//input wire[`WIDTH-1:0]					iWBMInitialAddress,
	//input wire									iSetWBMInitialAddress,
	input wire [`WIDTH-1:0]					iWBMData,                 //Comes from WBM
	output wire[`WIDTH-1:0]					oData,                 //Goes back to geo
	output wire 									oEnableWBM,
	//output wire[`WIDTH-1:0]					oAddressWBM,
	output wire[`DATA_ADDRESS_WIDTH-1:0] oDataWriteAddress,
	inout wire [`DATA_ROW_WIDTH-1:0]		oDataBus,
	output wire									oDataWriteEnable,
	output wire 								oDone
);
wire [`WIDTH-1:0] wVx;
wire [`WIDTH-1:0] wVy;
wire [`WIDTH-1:0] wVz;
wire wDelayAfterWriteEnable;

//assign oDataWriteAddress = iAdr_DataWriteBack;

wire CounterClock;
assign CounterClock = wDelayAfterWriteEnable | iWriteBack_Set;

UPCOUNTER_POSEDGE # (`DATA_ADDRESS_WIDTH) UP1
(
	.Clock(Clock), 
	.Reset(iWriteBack_Set | Reset ),
	.Enable(CounterClock),
	.Initial(iAdr_DataWriteBack),
	.Q(oDataWriteAddress)
);


wire[3:0] wSelXYZ;
//Every time WBM says is done, then shift the bit
//one position

CIRCULAR_SHIFTLEFT_POSEDGE # (4) SHL_A
(
 .Clock( Clock ),
 .Enable(iWBMDataAvailable),
 .Reset(~iEnable | Reset ),
 .Initial(4'b1), 
 .O(wSelXYZ)
 
);


FFD_POSEDGE_SYNCRONOUS_RESET # (`WIDTH) FFD32_WBMFIFO_Vx 
(
	.Clock( 	Clock ),
	.Reset( 	~iEnable | Reset ),
	.Enable( wSelXYZ[0] & iWBMDataAvailable ),
	.D( iWBMData ),
	.Q( wVx )
	
);

//The data out is equal to the first vertex that has
//been captured
assign oData = wVx;


FFD_POSEDGE_SYNCRONOUS_RESET # (`WIDTH) FFD32_WBMFIFO_Vy 
(
	.Clock( 	Clock ),
	.Reset( 	~iEnable | Reset),
	.Enable( wSelXYZ[1] & iWBMDataAvailable ),
	.D( iWBMData ),
	.Q( wVy )
	
);

FFD_POSEDGE_SYNCRONOUS_RESET # (`WIDTH) FFD32_WBMFIFO_Vz 
(
	.Clock( 	Clock ),
	.Reset( 	~iEnable | Reset ),
	.Enable( wSelXYZ[2] & iWBMDataAvailable),
	.D( iWBMData ),
	.Q( wVz )
	
);

assign oDataBus = {wVx,wVy,wVz};


assign oDataWriteEnable = wSelXYZ[3];
assign oDone = (iStore) ? wSelXYZ[3] : wSelXYZ[1];
assign oEnableWBM =  ~oDone;

FFD_POSEDGE_SYNCRONOUS_RESET # (1) FFD32_WBMFIFO_V2 
(
	.Clock( 	Clock ),
	.Reset( 	 Reset ),
	.Enable( 1'b1 ),
	.D( wSelXYZ[3] ),
	.Q(wDelayAfterWriteEnable )
	
);

/*
always @ (posedge iWBMDataAvailable)
begin
	$display("%d Got something %h!",$time,iWBMData);
	$display("%d Got wSelXYZ %b!",$time,wSelXYZ);
end
*/
endmodule

//----------------------------------------------------