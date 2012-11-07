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


module LOGIC_STATION
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
wire [`DATA_ROW_WIDTH-1:0]     wAND,wOR,wResult;
wire [`SCALE_SIZE-1:0]         wResultSelector_Temp;
wire [1:0]                     wResultSelector;

ReservationStation_1Cycle RS
(
	.Clock(              Clock                                                       ),
	.Reset(              Reset                                                       ),
	.iIssueBus(          iIssueBus                                                   ),
	.iCommitBus(         iCommitBus                                                  ),
	.iMyId(              iId                                                         ),
	.iExecutionDone(     wExeDone                                                    ),
	.iResult(             wResult                                                    ),
	.iCommitGranted(     iCommitGranted                                              ),
	.oSource1(          wRS1_OperandA                                                ),
	.oSource0(          wRS1_OperandB                                                ),
	.oBusy(              oBusy                                                       ),
	.oTrigger(           wRS1_2_ADD_Trigger                                          ),
	.oCommitRequest(     oCommitResquest                                             ),
	.oId(              oCommitData[`COMMIT_RSID_RNG]                                 ),
	.oWE(              oCommitData[`COMMIT_WE_RNG]                                   ),
	.oDestination(     oCommitData[`COMMIT_DST_RNG]                                  ),
	.oScale(            wResultSelector_Temp                                         ),
	.oResult(          {oCommitData[`X_RNG],oCommitData[`Y_RNG],oCommitData[`Z_RNG]} )
	
);

assign wResultSelector = wResultSelector_Temp[1:0];

 MUXFULLPARALELL_2SEL_GENERIC # ( `DATA_ROW_WIDTH ) MUX1
 (
 .Sel( wResultSelector ),
 .I1( wAND ), 
 .I2( wOR ), 
 .I3(`DATA_ROW_WIDTH'b0),
 .I4(`DATA_ROW_WIDTH'b0),
 .O1(wResult)
 );

assign wExeDone = wExeDoneTmp[0] & wExeDoneTmp[1] & wExeDoneTmp[2];

//TODO: For now I am only supporting AND, eventually you will have to use the MOD_ISSUE_SCALE_RNG
//to select between AND, OR, NOT, etc.
AND # (`WIDTH) AND_0
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`X_RNG]   ), 
	.iB(        wRS1_OperandB[`X_RNG]   ),
	.oDone(     wExeDoneTmp[0]          ), 
   .oR(        wAND[`X_RNG]         )
);

AND # (`WIDTH) AND_1
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`Y_RNG]   ), 
	.iB(        wRS1_OperandB[`Y_RNG]   ),
	.oDone(     wExeDoneTmp[1]          ),
   .oR(        wAND[`Y_RNG]         )
);

AND # (`WIDTH) AND_2
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`Z_RNG]   ), 
	.iB(        wRS1_OperandB[`Z_RNG]   ),
	.oDone(     wExeDoneTmp[2]          ), 
   .oR(        wAND[`Z_RNG]         )
);

OR # (`WIDTH) OR_0
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`X_RNG]   ), 
	.iB(        wRS1_OperandB[`X_RNG]   ),
	.oDone(     wExeDoneTmp[0]          ), 
   .oR(        wOR[`X_RNG]         )
);

OR # (`WIDTH) OR_1
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`Y_RNG]   ), 
	.iB(        wRS1_OperandB[`Y_RNG]   ),
	.oDone(     wExeDoneTmp[1]          ),
   .oR(        wOR[`Y_RNG]         )
);

OR # (`WIDTH) OR_2
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`Z_RNG]   ), 
	.iB(        wRS1_OperandB[`Z_RNG]   ),
	.oDone(     wExeDoneTmp[2]          ), 
   .oR(        wOR[`Z_RNG]         )
);
endmodule
