
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

module Unit_Execution
(
input wire Clock,
input wire Reset,
input wire iEnable

);

wire [`INSTRUCTION_ADDR_WIDTH -1:0]                  wII_2_IM_IP0;
wire [`INSTRUCTION_ADDR_WIDTH -1:0]                  wII_2_IM_IP1;
wire [`INSTRUCTION_WIDTH-1:0]                        wIM_2_II_Instruction0;
wire [`INSTRUCTION_WIDTH-1:0]                        wIM_2_II_Instruction1;
wire [`DATA_ADDRESS_WIDTH-1:0]                       wII_2_RF_Addr0;
wire [`DATA_ADDRESS_WIDTH-1:0]                       wII_2_RF_Addr1;
wire [`DATA_ROW_WIDTH-1:0]                           wRF_2_II_Data0;
wire [`DATA_ROW_WIDTH-1:0]                           wRF_2_II_Data1;
wire [`NUMBER_OF_RSVR_STATIONS-1:0]                  wRS_2_II_Busy;
wire [`ISSUE_PACKET_SIZE-1:0]                        wIssueBus,wModIssue;
wire [`NUMBER_OF_RSVR_STATIONS-1:0]                  wStationCommitRequest;
wire [`NUMBER_OF_RSVR_STATIONS-1:0]                  wStationCommitGrant;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitBus;
wire [`MOD_COMMIT_PACKET_SIZE-1:0]                   wModCommitBus;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Adder0;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Adder1;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Div;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Mul;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Sqrt;
wire                                                 wZeroFlag;
wire                                                 wSignFlag;
wire [`DATA_ADDRESS_WIDTH-1:0]                       wFrameOffset;


// The Register File
RegisterFile # ( `DATA_ROW_WIDTH,`DATA_ADDRESS_WIDTH ) RF
(
 .Clock(            Clock                            ),
 .Reset(            Reset                            ),
 .iWriteEnable(     wCommitBus[`COMMIT_WE_RNG]       ),
 .iReadAddress0(    wII_2_RF_Addr0                   ),
 .iReadAddress1(    wII_2_RF_Addr1                   ),
 .iWriteAddress(    wCommitBus[`COMMIT_DST_RNG]      ),
 .oFrameOffset(     wFrameOffset                     ),
 .iData(            wCommitBus[`COMMIT_DATA_RNG]     ),
 .oData0(           wRF_2_II_Data0                   ),
 .oData1(           wRF_2_II_Data1                   )
);




//Code bank 0
RAM_DUAL_READ_PORT  # (`INSTRUCTION_WIDTH, `INSTRUCTION_ADDR_WIDTH) IM 
(
 .Clock(            Clock                    ),
 .iWriteEnable(     0                        ),
 .iReadAddress0(    wII_2_IM_IP0             ),
 .iReadAddress1(    wII_2_IM_IP1             ),
 //.iWriteAddress(                           ),
 //.iDataIn(                                 ),
 .oDataOut0(        wIM_2_II_Instruction0    ),
 .oDataOut1(        wIM_2_II_Instruction1    )
);

InstructionIssue II
(
   .Clock(                Clock                 ),
	.Reset(                Reset                 ),
	.iEnable(              iEnable               ),
	.iFrameOffset(         wFrameOffset          ),
	.iInstruction0(        wIM_2_II_Instruction0 ),
	.iInstruction1(        wIM_2_II_Instruction1 ),
	.iSourceData0(         wRF_2_II_Data0        ),
	.iSourceData1(         wRF_2_II_Data1        ),
	.iRStationBusy(        wRS_2_II_Busy         ),    
	.iResultBcast(         wCommitBus            ),         
	.oSourceAddress0(      wII_2_RF_Addr0        ),
	.oSourceAddress1(      wII_2_RF_Addr1        ),
	.oIssueBcast(          wIssueBus             ), 
	.iSignFlag(            wSignFlag             ),
	.iZeroFlag(            wZeroFlag             ),
	.oIP0(                 wII_2_IM_IP0          ),
	.oIP1(                 wII_2_IM_IP1          )
	
);



OperandModifiers SMU
(
	.Clock(                Clock                 ),
	.Reset(                Reset                 ),
	.iIssueBus(            wIssueBus             ),
	.iCommitBus(           wCommitBus            ),
	.oModIssue(            wModIssue             ),
	.oCommitBus(           wModCommitBus         )
	
);

assign wSignFlag = wCommitBus[`COMMIT_SIGN_X] & wCommitBus[`COMMIT_SIGN_Y] & wCommitBus[`COMMIT_SIGN_Z];
assign wZeroFlag = (wCommitBus[`COMMIT_DATA_RNG] == `DATA_ROW_WIDTH'b0) ? 1'b1 : 1'b0;


ADDER_STATION ADD_STA0
(
   .Clock(               Clock                    ),
	.Reset(               Reset                    ),
	.iId(                 `RS_ADD0                ),
   .iIssueBus(           wModIssue                ),
   .iCommitBus(          wModCommitBus               ),
	.oCommitData(         wCommitData_Adder0        ),
	.oCommitResquest(     wStationCommitRequest[0] ),
	.iCommitGranted(      wStationCommitGrant[0]   ),
	.oBusy(               wRS_2_II_Busy[ 0 ]          )
	
);

ADDER_STATION ADD_STA1
(
   .Clock(               Clock                    ),
	.Reset(               Reset                    ),
	.iId(                 `RS_ADD1                     ),
   .iIssueBus(           wModIssue                ),
   .iCommitBus(          wModCommitBus               ),
	.oCommitData(         wCommitData_Adder1        ),
	.oCommitResquest(     wStationCommitRequest[1] ),
	.iCommitGranted(      wStationCommitGrant[1]   ),
	.oBusy(               wRS_2_II_Busy[ 1 ]          )
	
);


DIVISION_STATION DIV_STA
(
   .Clock(               Clock                    ),
	.Reset(               Reset                    ),
	.iId(                 `RS_DIV                     ),
   .iIssueBus(           wModIssue                ),
   .iCommitBus(          wModCommitBus               ),
	.oCommitData(         wCommitData_Div          ),
	.oCommitResquest(     wStationCommitRequest[2] ),
	.iCommitGranted(      wStationCommitGrant[2]   ),
	.oBusy(               wRS_2_II_Busy[2]           )
	
);


MUL_STATION MUL_STA
(
   .Clock(               Clock                    ),
	.Reset(               Reset                    ),
	.iId(                 `RS_MUL                   ),
   .iIssueBus(           wModIssue                ),
   .iCommitBus(          wModCommitBus               ),
	.oCommitData(         wCommitData_Mul          ),
	.oCommitResquest(     wStationCommitRequest[3] ),
	.iCommitGranted(      wStationCommitGrant[3]   ),
	.oBusy(               wRS_2_II_Busy[3]           )
	
);


SQRT_STATION SQRT_STA
(
   .Clock(               Clock                    ),
	.Reset(               Reset                    ),
	.iId(                 `RS_SQRT                 ),
   .iIssueBus(           wModIssue                ),
   .iCommitBus(          wModCommitBus               ),
	.oCommitData(         wCommitData_Sqrt         ),
	.oCommitResquest(     wStationCommitRequest[4] ),
	.iCommitGranted(      wStationCommitGrant[4]   ),
	.oBusy(               wRS_2_II_Busy[4]         )
	
);


ROUND_ROBIN_5_ENTRIES ARB
(
.Clock( Clock ),
.Reset( Reset ),
.iRequest0( wStationCommitRequest[0] ),
.iRequest1( wStationCommitRequest[1] ),
.iRequest2( wStationCommitRequest[2] ),
.iRequest3( wStationCommitRequest[3] ),
.iRequest4( wStationCommitRequest[4] ),
.oGrant0(    wStationCommitGrant[0]   ),
.oGrant1(    wStationCommitGrant[1]   ),
.oGrant2(    wStationCommitGrant[2]   ),
.oGrant3(    wStationCommitGrant[3]   ),
.oGrant4(    wStationCommitGrant[4]   )


);

wire[3:0] wBusSelector;
DECODER_ONEHOT_2_BINARY DECODER
(
.iIn( wStationCommitGrant ),
.oOut( wBusSelector        )
);


MUXFULLPARALELL_3SEL_GENERIC # (`COMMIT_PACKET_SIZE ) MUX
 (
 .Sel(wBusSelector),
 .I1(`COMMIT_PACKET_SIZE'b0), 
 .I2(wCommitData_Adder0),
 .I3(wCommitData_Adder1),
 .I4(wCommitData_Div),
 .I5(wCommitData_Mul),
 .I6(wCommitData_Sqrt),
 .O1(wCommitBus)
 );

endmodule
