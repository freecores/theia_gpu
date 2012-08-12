`timescale 1ns / 1ps
`include "aDefinitions.v"

/**********************************************************************************
Theia, Ray Cast Programable graphic Processing Unit.
Copyright (C) 2012  Diego Valverde (diego.valverde.g@gmail.com)

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

module DIVISION_STATION
(
   input wire Clock,
   input wire Reset,
   input wire [`MOD_ISSUE_PACKET_SIZE-1:0]                   iIssueBus,
   input wire [`MOD_COMMIT_PACKET_SIZE-1:0]                  iCommitBus,
	input wire [3:0]                                          iId,
	output wire [`COMMIT_PACKET_SIZE-1:0]                     oCommitData,
	output wire                                               oCommitResquest,
	input wire                                                iCommitGranted,
	output wire                                               oBusy
	
);

wire                           wExeDone;
wire [2:0]                     wExeDoneTmp;
wire                           wRS1_2_ADD_Trigger;
wire [`DATA_ROW_WIDTH-1:0]     wRS1_OperandA;
wire [`DATA_ROW_WIDTH-1:0]     wRS1_OperandB;
wire [`DATA_ROW_WIDTH-1:0]     wResult;
wire [`LONG_WIDTH-1:0]         wDividend64X,wDividendX64_Pre;
wire [`LONG_WIDTH-1:0]         wDividend64Y,wDividendY64_Pre;
wire [`LONG_WIDTH-1:0]         wDividend64Z,wDividendZ64_Pre;
wire [`LONG_WIDTH-1:0]         wDivisor64X,wDivisorX64_Pre;
wire [`LONG_WIDTH-1:0]         wDivisor64Y,wDivisorY64_Pre;
wire [`LONG_WIDTH-1:0]         wDivisor64Z,wDivisorZ64_Pre;
wire [2:0]                     wScaleSelect;

ReservationStation RS
(
	.Clock(              Clock                           ),
	.Reset(              Reset                           ),
	.iIssueBus(          iIssueBus                       ),
	.iCommitBus(         iCommitBus                      ),
	.iMyId(              iId                             ),
	.iExecutionDone(     wExeDone                        ),
	.iResult(             wResult                        ),
	.iCommitGranted(     iCommitGranted                  ),
	
	.oSource1(          wRS1_OperandA                   ),
	.oSource0(          wRS1_OperandB                   ),
	.oBusy(              oBusy                           ),
	.oTrigger(           wRS1_2_ADD_Trigger              ),
	.oCommitRequest(     oCommitResquest                 ),
	.oId(              oCommitData[`COMMIT_RSID_RNG]                                ),
	.oWE(              oCommitData[`COMMIT_WE_RNG]                                  ),
	.oDestination(     oCommitData[`COMMIT_DST_RNG]                               ),
	.oResult(          {oCommitData[`X_RNG],oCommitData[`Y_RNG],oCommitData[`Z_RNG]})
	
);

assign wExeDone = wExeDoneTmp[0] & wExeDoneTmp[1] & wExeDoneTmp[2];



assign  wDividendX64_Pre =  {{32{wRS1_OperandB[95]}},wRS1_OperandB[`X_RNG]};
assign  wDividendY64_Pre =  {{32{wRS1_OperandB[63]}},wRS1_OperandB[`Y_RNG]};
assign  wDividendZ64_Pre =  {{32{wRS1_OperandB[31]}},wRS1_OperandB[`Z_RNG]};

assign  wDivisorX64_Pre =  {{32{wRS1_OperandA[95]}},wRS1_OperandA[`X_RNG]};
assign  wDivisorY64_Pre =  {{32{wRS1_OperandA[63]}},wRS1_OperandA[`Y_RNG]};
assign  wDivisorZ64_Pre =  {{32{wRS1_OperandA[31]}},wRS1_OperandA[`Z_RNG]};

assign wScaleSelect = iIssueBus[`MOD_ISSUE_SCALE_RNG];
//Perform the scale logic, the unscale part is done by the IIU	
assign wDividend64X = (~wScaleSelect[2] & wScaleSelect[1]) ? (wDividendX64_Pre << `SCALE)	: wDividendX64_Pre;
assign wDividend64Y = (~wScaleSelect[2] & wScaleSelect[1]) ? (wDividendY64_Pre << `SCALE)	: wDividendY64_Pre;
assign wDividend64Z = (~wScaleSelect[2] & wScaleSelect[1]) ? (wDividendZ64_Pre << `SCALE)	: wDividendZ64_Pre;
	
assign wDivisor64X = (~wScaleSelect[2] & wScaleSelect[0]) ? (wDivisorX64_Pre << `SCALE)	: wDivisorX64_Pre;
assign wDivisor64Y = (~wScaleSelect[2] & wScaleSelect[0]) ? (wDivisorY64_Pre << `SCALE)	: wDivisorY64_Pre;
assign wDivisor64Z = (~wScaleSelect[2] & wScaleSelect[0]) ? (wDivisorZ64_Pre << `SCALE)	: wDivisorZ64_Pre;


SignedIntegerDivision  DIV_0
(
   .Clock(           Clock                  ),
	.Reset(           Reset                  ),
   .iInputReady(     wRS1_2_ADD_Trigger     ),
   .iDividend(       wDividend64X           ), 
	.iDivisor(        wDivisor64X            ),
	.OutputReady(     wExeDoneTmp[0]         ), 
   .oQuotient(       wResult[`X_RNG]        )
);

SignedIntegerDivision  DIV_1
(
   .Clock(           Clock                ),
	.Reset(           Reset                ),
   .iInputReady(     wRS1_2_ADD_Trigger   ),
   .iDividend(       wDividend64Y         ), 
	.iDivisor(        wDivisor64Y          ),
	.OutputReady(     wExeDoneTmp[1]       ),
   .oQuotient(       wResult[`Y_RNG]      )
);

SignedIntegerDivision  DIV_2
(
   .Clock(           Clock                 ),
	.Reset(           Reset                 ),
   .iInputReady(     wRS1_2_ADD_Trigger    ),
   .iDividend(       wDividend64Z          ), 
	.iDivisor(        wDivisor64Z           ),
	.OutputReady(     wExeDoneTmp[2]        ), 
   .oQuotient(       wResult[`Z_RNG]       )
);

endmodule
