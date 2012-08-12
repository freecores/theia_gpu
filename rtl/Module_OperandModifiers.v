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

//-----------------------------------------------------------------------------------
module ModfierQueue
(
input wire                              Clock,
input wire                              Reset,
input wire                              iKeep,
input wire                              iGranted,
input wire [3:0]                        iRs,
input wire [2:0]                        iScale,
output wire [2:0]                       oScale,
input wire[`ISSUE_SRCTAG_SIZE-1:0]      iTag,
input wire[`COMMIT_PACKET_SIZE-1:0]     iData,
output wire[`COMMIT_PACKET_SIZE-1:0]    oData,
output wire[3:0]                        oRsID,
input wire[3:0]                         iKey,
output wire                             oRequest,
output wire                             oBusy,
output wire[`ISSUE_SRCTAG_SIZE-1:0]     oTag
);

wire wMatch,wGranted;

PULSE P1
(
.Clock( Clock               ),
.Reset( Reset               ),
.Enable( 1'b1 ),
.D(iGranted),
.Q(wGranted)
);
UPCOUNTER_POSEDGE # (1) UPBUSY
(
.Clock( Clock               ),
.Reset( Reset               ),
.Initial( 1'b0              ),
.Enable( iKeep | wGranted   ),
.Q(     oBusy               )
);

UPCOUNTER_POSEDGE # (1) UPREQ
(
.Clock( Clock               ),
.Reset( Reset               ),
.Initial( 1'b0              ),
.Enable( wMatch | (wGranted & oRequest)  ),
.Q(     oRequest            )
);


assign wMatch = (iKey == oRsID && oBusy == 1'b1)? 1'b1 : 1'b0;

//20 DST, SWZZL 6 bits, SCALE 3 bits, SIGN 3 bits = 15

FFD_POSEDGE_SYNCRONOUS_RESET # ( `ISSUE_SRCTAG_SIZE ) FFD1
( 	Clock, Reset, iKeep ,iTag  , oTag  );

FFD_POSEDGE_SYNCRONOUS_RESET # ( `COMMIT_PACKET_SIZE ) FFD2
( 	Clock, Reset, wMatch ,iData  , oData  );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 4 ) FFD3
( 	Clock, Reset, iKeep ,iRs  , oRsID  );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 3 ) FFD4
( 	Clock, Reset, iKeep ,iScale  , oScale  );

endmodule
//-----------------------------------------------------------------------------------

module ModifierBlock
 (
	input wire                           Clock,
	input wire                           Reset,
	input wire [`ISSUE_SRCTAG_SIZE-1:0]  iTag,
	input wire [1:0]                     iScale,
	input wire [`DATA_ROW_WIDTH-1:0]      iData,
	output wire [`DATA_ROW_WIDTH-1:0]     oData
 );
 
 wire [`DATA_ROW_WIDTH-1:0] wSignedData;
 wire [`DATA_ROW_WIDTH-1:0] wScaledData;
 wire [`DATA_ROW_WIDTH-1:0] wSwizzledData;
 
`ifdef DISABLE_FEATURE_SIGN_CONTROL
	assign wSignedData = iData;

`else
	assign wSignedData[`X_RNG] = (iTag[`TAG_SIGNX]) ? -iData[`X_RNG] : iData[`X_RNG];
	assign wSignedData[`Y_RNG] = (iTag[`TAG_SIGNY]) ? -iData[`Y_RNG] : iData[`Y_RNG];
	assign wSignedData[`Z_RNG] = (iTag[`TAG_SIGNZ]) ? -iData[`Z_RNG] : iData[`Z_RNG];

`endif

`ifdef DISABLE_FEATURE_SCALE_CONTROL

	assign wScaledData = wSignedData;


`else
	wire signed [`WIDTH-1:0] wSignedData_X,wSignedData_Y,wSignedData_Z;
	wire [`DATA_ROW_WIDTH-1:0] wScaledData_Pre,wUnscaledData_Pre;
	
	assign wSignedData_X  = wSignedData[`X_RNG];
	assign wSignedData_Y  = wSignedData[`Y_RNG];
	assign wSignedData_Z  = wSignedData[`Z_RNG];
	

	assign wScaledData_Pre  = wSignedData;//{(wSignedData_X << `SCALE),(wSignedData_Y << `SCALE),(wSignedData_Z << `SCALE)};
	assign wUnscaledData_Pre = {(wSignedData_X >>> `SCALE),(wSignedData_Y >>> `SCALE),(wSignedData_Z >>> `SCALE)};
	
	
	assign wScaledData = (iScale[0]) ? ((iScale[1]) ? wUnscaledData_Pre : wScaledData_Pre ): wSignedData;
	/*
	MUXFULLPARALELL_3SEL_GENERIC # ( `DATA_ROW_WIDTH ) MUX_SCALE0
 (
 .Sel( iScale   ),
 .I1( wSignedData                ),
 .I2( wScaledData_Pre     ),
 .I3( wSignedData             ), 
 .I4( wScaledData_Pre         ),
 .I5( wSignedData             ),
 .I6( wUnscaledData_Pre        ),
 .I7( wSignedData             ),
 .I8( wUnscaledData_Pre        ),
 .O1( wScaledData             )
 );
 */
 
`endif

`ifdef DISABLE_FEATURE_SWIZZLE_CONTROL
	assign wSwizzledData = wScaledData;
	
`else
MUXFULLPARALELL_3SEL_EN SWIZZLE0X
(
    .I1(wScaledData[`X_RNG]),
	 .I2(wScaledData[`Z_RNG]),
	 .I3(wScaledData[`Y_RNG]),
	 .EN(1'b1),
    .SEL(iTag[`TAG_SWLX_RNG]),   
    .O1(wSwizzledData[`X_RNG])
 );

MUXFULLPARALELL_3SEL_EN SWIZZLE0Y
(
    .I1(wScaledData[`Y_RNG]),
	 .I2(wScaledData[`Z_RNG]),
	 .I3(wScaledData[`X_RNG]),
	 .EN(1'b1),
    .SEL(iTag[`TAG_SWLY_RNG]),   
    .O1(wSwizzledData[`Y_RNG])
);	 

MUXFULLPARALELL_3SEL_EN SWIZZLE0Z
(
    .I1(wScaledData[`Z_RNG]),
	 .I2(wScaledData[`Y_RNG]),
	 .I3(wScaledData[`X_RNG]),
	 .EN(1'b1),
    .SEL(iTag[`TAG_SWLZ_RNG]),   
    .O1(wSwizzledData[`Z_RNG])
);

`endif

assign oData = wSwizzledData;
 
 endmodule
//-----------------------------------------------------------------------------------
module OperandModifiers
(
input wire Clock,
input wire Reset,
input wire [`ISSUE_PACKET_SIZE-1:0]                       iIssueBus,
input wire [`COMMIT_PACKET_SIZE-1:0]                      iCommitBus,
output wire [`MOD_ISSUE_PACKET_SIZE-1:0]                  oModIssue,
output wire [`MOD_COMMIT_PACKET_SIZE-1:0]                 oCommitBus
);


wire [`ISSUE_PACKET_SIZE-1:0]                    wIssueBus;
wire [2:0]                                       wStationRequest;
wire [2:0]                                       wStationGrant;
wire                                             wIssue;
wire [3:0]                                       wBusy;
wire [3:0]                                       wKeep;
wire                                             wFifoEmpty;
wire                                             wDependencySrc0,wDependencySrc1;
wire [`ISSUE_SRCTAG_SIZE-1:0]                    wInTag0,wInTag1,wInTag2,wInTag3;		//8+3+ISSUE_SRCTAG_SIZE(9) = 20
wire [`ISSUE_SRCTAG_SIZE-1:0]                    wOutTag0,wOutTag1,wOutTag2,wOutTag3;		//8+3+ISSUE_SRCTAG_SIZE(9) = 20
wire [`DATA_ROW_WIDTH-1:0]                   wData0,wData1,wData2,wData3;
wire [(`ISSUE_SRCTAG_SIZE+`DATA_ROW_WIDTH)-1:0]  wSrcA_Pre;
wire [4:0]                                       wRequest,wGranted;
wire [3:0]                                       wInRs0,wInRs1,wInRs2,wInRs3;
wire [3:0]                                       wOutRs0,wOutRs1,wOutRs2,wOutRs3,wOutRsCommit;
wire [2:0]                                       wOutScale0,wOutScale1,wOutScale2,wOutScale3,wSrcA_Scale;
wire [2:0]                                       wInScale0,wInScale1,wInScale2,wInScale3;


assign wIssueBus = iIssueBus;

//If at least 1 bit of the RSID is 1 then IIU is currently Issuing a packet
assign wIssue = (iIssueBus[`ISSUE_RSID_RNG]) ? 1'b1 : 1'b0;

assign wDependencySrc0 = (iIssueBus[`ISSUE_SRC0RS_RNG] != 0) ? 1 : 0;
assign wDependencySrc1 = (iIssueBus[`ISSUE_SRC1RS_RNG] != 0) ? 1 : 0;

assign wKeep[0] = wDependencySrc0 & ~wBusy[0] |
					    wDependencySrc1 & ~wDependencySrc0 & ~wBusy[0] & wBusy[1];
				  
assign wKeep[1] = wDependencySrc1 & ~wBusy[1] |
						 wDependencySrc0 & ~wDependencySrc0 & wBusy[0] & ~wBusy[1];

assign wKeep[2] = wDependencySrc0 & wBusy[0] & ~wBusy[2]; //|
                   //wDependencySrc1 & ~wDependencySrc0 & wBusy[0] & wBusy[1] & ~wBusy[2];
						 
assign wKeep[3] = wDependencySrc1 &  wBusy[1] & ~wBusy[3];// |
						 //wDependencySrc0 & ~wDependencySrc1 & wBusy[0] & wBusy[1] & wBusy[2] & ~wBusy[3];


assign wInTag0 = ( wDependencySrc0 ) ? iIssueBus[`ISSUE_SRC0_TAG_RNG] : iIssueBus[`ISSUE_SRC1_TAG_RNG];
assign wInTag1 = ( wDependencySrc1 ) ? iIssueBus[`ISSUE_SRC1_TAG_RNG] : iIssueBus[`ISSUE_SRC0_TAG_RNG];
assign wInTag2 = ( wDependencySrc0 ) ? iIssueBus[`ISSUE_SRC0_TAG_RNG] : iIssueBus[`ISSUE_SRC1_TAG_RNG];
assign wInTag3 = ( wDependencySrc1 ) ? iIssueBus[`ISSUE_SRC1_TAG_RNG] : iIssueBus[`ISSUE_SRC0_TAG_RNG];

assign wInRs0 = ( wDependencySrc0 ) ? iIssueBus[`ISSUE_SRC0RS_RNG] : iIssueBus[`ISSUE_SRC1RS_RNG];
assign wInRs1 = ( wDependencySrc1 ) ? iIssueBus[`ISSUE_SRC1RS_RNG] : iIssueBus[`ISSUE_SRC0RS_RNG];
assign wInRs2 = ( wDependencySrc0 ) ? iIssueBus[`ISSUE_SRC0RS_RNG] : iIssueBus[`ISSUE_SRC1RS_RNG];
assign wInRs3 = ( wDependencySrc1 ) ? iIssueBus[`ISSUE_SRC1RS_RNG] : iIssueBus[`ISSUE_SRC0RS_RNG];


assign wInScale0 = ( wDependencySrc0 ) ? {iIssueBus[`ISSUE_SCALER],iIssueBus[`ISSUE_SCALE_OP],iIssueBus[`ISSUE_SCALE0]} : {iIssueBus[`ISSUE_SCALER],iIssueBus[`ISSUE_SCALE_OP],iIssueBus[`ISSUE_SCALE1]};
assign wInScale1 = ( wDependencySrc1 ) ? {iIssueBus[`ISSUE_SCALER],iIssueBus[`ISSUE_SCALE_OP],iIssueBus[`ISSUE_SCALE1]} : {iIssueBus[`ISSUE_SCALER],iIssueBus[`ISSUE_SCALE_OP],iIssueBus[`ISSUE_SCALE0]};
assign wInScale2 = ( wDependencySrc0 ) ? {iIssueBus[`ISSUE_SCALER],iIssueBus[`ISSUE_SCALE_OP],iIssueBus[`ISSUE_SCALE0]} : {iIssueBus[`ISSUE_SCALER],iIssueBus[`ISSUE_SCALE_OP],iIssueBus[`ISSUE_SCALE1]};
assign wInScale3 = ( wDependencySrc1 ) ? {iIssueBus[`ISSUE_SCALER],iIssueBus[`ISSUE_SCALE_OP],iIssueBus[`ISSUE_SCALE1]} : {iIssueBus[`ISSUE_SCALER],iIssueBus[`ISSUE_SCALE_OP],iIssueBus[`ISSUE_SCALE0]};
assign wRequest[0] = 1'b0;
ModfierQueue Q0
(
.Clock( Clock    ),
.Reset( Reset    ),
.iRs(      wInRs0 ),
.oRsID(    wOutRs0 ),
.iTag(      wInTag0 ),
.iScale(    wInScale0  ),
.oScale(    wOutScale0 ),
.iKeep(     wKeep[0]                       ),
.iKey(      iCommitBus[`COMMIT_RSID_RNG]    ),
.iData(     iCommitBus                     ),
.oTag(      wOutTag0                       ),
.oData(     wData0                         ),
.oRequest(  wRequest[1]                    ),
.iGranted(  wGranted[1]                    ),
.oBusy(     wBusy[0]                       )
);


ModfierQueue Q1
(
.Clock( Clock    ),
.Reset( Reset    ),
.iRs(      wInRs1 ),
.oRsID(    wOutRs1 ),
.iTag(      wInTag1 ),
.iScale(    wInScale1 ),
.oScale(    wOutScale1 ),
.iKeep(     wKeep[1]                       ),
.iKey(      iCommitBus[`COMMIT_RSID_RNG]    ),
.iData(     iCommitBus                     ),
.oTag(      wOutTag1                       ),
.oData(     wData1                         ),
.oRequest(  wRequest[2]                    ),
.iGranted(  wGranted[2]                    ),
.oBusy(     wBusy[1]                       )
);


ModfierQueue Q2
(
.Clock( Clock    ),
.Reset( Reset    ),
.iRs(      wInRs2 ),
.iTag(      wInTag2 ),
.iScale(    wInScale2 ),
.oScale(    wOutScale2 ),
.oRsID(    wOutRs2 ),
.iKeep(     wKeep[2]                       ),
.iKey(      iCommitBus[`COMMIT_RSID_RNG]    ),
.iData(     iCommitBus                     ),
.oTag(      wOutTag2                       ),
.oData(     wData2                         ),
.oRequest(  wRequest[3]                    ),
.iGranted(  wGranted[3]                    ),
.oBusy(     wBusy[2]                       )
);

ModfierQueue Q3
(
.Clock( Clock    ),
.Reset( Reset    ),
.iRs(      wInRs3 ),
.oRsID(    wOutRs3 ),
.iTag(      wInTag3 ),
.iScale(    wInScale3 ),
.oScale(    wOutScale3 ),
.iKeep(     wKeep[3]                       ),
.iKey(      iCommitBus[`COMMIT_RSID_RNG]    ),
.iData(     iCommitBus                     ),
.oTag(      wOutTag3                       ),
.oData(     wData3                         ),
.oRequest(  wRequest[4]                    ),
.iGranted(  wGranted[4]                    ),
.oBusy(     wBusy[3]                       )
);


ROUND_ROBIN_5_ENTRIES ARBXXX
(
.Clock(      Clock ),
.Reset(      Reset ),
.iRequest0(  wIssue),
.iRequest1(  wRequest[1] & ~wIssue ),  //Issues from IIU have priority
.iRequest2(  wRequest[2] & ~wIssue ),  //Issues from IIU have priority
.iRequest3(  wRequest[3] & ~wIssue ),  //Issues from IIU have priority,
.iRequest4(  wRequest[4] & ~wIssue ),

.oPriorityGrant(    wGranted[0]   ),
.oGrant1(    wGranted[1]   ),
.oGrant2(    wGranted[2]   ),
.oGrant3(    wGranted[3]   ),
.oGrant4(    wGranted[4]   )

);


wire[3:0] wBusSelector;
DECODER_ONEHOT_2_BINARY DECODER
(
.iIn( {1'b0,wGranted} ),
.oOut( wBusSelector        )
);

MUXFULLPARALELL_3SEL_GENERIC # (`ISSUE_SRCTAG_SIZE + `DATA_ROW_WIDTH ) MUX
 (
 .Sel(wBusSelector),
 .I1( {`ISSUE_SRCTAG_SIZE'b0,`DATA_ROW_WIDTH'b0}  ), 
 .I2( {wIssueBus[`ISSUE_SRC0_TAG_RNG],wIssueBus[`ISSUE_SRC0_DATA_RNG]} ),
 .I3(  {wOutTag0,wData0} ),
 .I4(  {wOutTag1,wData1} ),
 .I5(  {wOutTag2,wData2} ),
 .I6(  {wOutTag3,wData3} ),
 .O1( wSrcA_Pre )
 );
 
 MUXFULLPARALELL_3SEL_GENERIC # ( 4 ) MUX2
 (
 .Sel(wBusSelector),
 .I1( 4'b0  ), 
 .I2( 4'b0  ),
 .I3(  wOutRs0 ),
 .I4(  wOutRs1 ),
 .I5(  wOutRs2 ),
 .I6(  wOutRs3  ),
 .O1(  wOutRsCommit  )
 );
 
 
 MUXFULLPARALELL_3SEL_GENERIC # ( 3 ) MUX3
 (
 .Sel(wBusSelector),
 .I1( 3'b0  ), 
 .I2( 3'b0  ),
 .I3(  wOutScale0 ),
 .I4(  wOutScale1 ),
 .I5(  wOutScale2 ),
 .I6(  wOutScale3  ),
 .O1(  wSrcA_Scale  )
 );
 
 wire [`DATA_ROW_WIDTH-1:0] wModIssueSource0, wModIssueSource1;
 
 ModifierBlock MD1
 (
	.Clock( Clock                           ),
	.Reset( Reset                           ),
	.iScale( {wSrcA_Scale[1:0]}                    ),
	.iTag(  wSrcA_Pre[`ISSUE_SRC0_TAG_RNG]  ),
	.iData( wSrcA_Pre[`ISSUE_SRC0_DATA_RNG] ),
	.oData( wModIssueSource0                )
 );
 
 assign oCommitBus = {wSrcA_Scale,wSrcA_Pre[`ISSUE_SRC0_TAG_RNG],wOutRsCommit,oModIssue[`MOD_ISSUE_SRC0_DATA_RNG]};
 wire [3:0] wScale;
 assign wScale = wIssueBus[`ISSUE_SCALE_RNG];
 
 ModifierBlock MD2
 (
	.Clock( Clock                           ),
	.Reset( Reset                           ),
	.iScale(  {wScale[`SCALE_OP],wScale[`SCALE_SRC1_EN]}   ),
	.iTag(  wIssueBus[`ISSUE_SRC1_TAG_RNG]  ),
	.iData( wIssueBus[`ISSUE_SRC1_DATA_RNG] ),
	.oData( wModIssueSource1              )
 );
 
 assign oModIssue[`MOD_ISSUE_SRC1_DATA_RNG] = (wDependencySrc1) ? {`MOD_ISSUE_SRC_SIZE'b0,wInTag1} : wModIssueSource1;
 assign oModIssue[`MOD_ISSUE_SRC0_DATA_RNG] = (wDependencySrc0) ? {`MOD_ISSUE_SRC_SIZE'b0,wInTag0} : wModIssueSource0;
 
 assign oModIssue[`MOD_ISSUE_SRC0RS_RNG] = wIssueBus[`ISSUE_SRC0RS_RNG];
 assign oModIssue[`MOD_ISSUE_SRC1RS_RNG] = wIssueBus[`ISSUE_SRC1RS_RNG];
 assign oModIssue[`MOD_ISSUE_WE_RNG]     = wIssueBus[`ISSUE_WE_RNG];
 assign oModIssue[`MOD_ISSUE_SCALE_RNG]  = wIssueBus[`ISSUE_SCALE_RNG];
 assign oModIssue[`MOD_ISSUE_DST_RNG]    = wIssueBus[`ISSUE_DST_RNG];
 assign oModIssue[`MOD_ISSUE_RSID_RNG]   = wIssueBus[`ISSUE_RSID_RNG];
  
 endmodule
 //-----------------------------------------------------------------------------------