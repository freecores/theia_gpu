`include "aDefinitions.v"
`define COMMIT_DST_RANGE 96+`DATA_ADDRESS_WIDTH:96


module AND_STATION
(
   input wire Clock,
   input wire Reset,
   input wire [`ISSUE_PACKET_SIZE-1:0]                       iIssueBus,
   input wire [`COMMIT_PACKET_SIZE-1:0]                      iCommitBus,
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

ReservationStation RS1
(
	.Clock(              Clock                           ),
	.Reset(              Reset                           ),
	.iIssueBus(          iIssueBus                       ),
	.iCommitBus(         iCommitBus                      ),
	.iMyId(              4'b0010                         ),
	.iExecutionDone(     wExeDone                        ),
	.iResult(             wResult                        ),
	.iCommitGranted(     iCommitGranted                  ),
	
	.oOperandA(          wRS1_OperandA                   ),
	.oOperandB(          wRS1_OperandB                   ),
	.oBusy(              oBusy                           ),
	.oTrigger(           wRS1_2_ADD_Trigger              ),
	.oCommitRequest(     oCommitResquest                 ),
	.oId(              oCommitData[`COMMIT_RSID_RNG]                                ),
	.oWE(              oCommitData[`COMMIT_WE_RNG]                                  ),
	.oDestination(     oCommitData[`COMMIT_DST_RNG]                               ),
	.oResult(          {oCommitData[`X_RNG],oCommitData[`Y_RNG],oCommitData[`Z_RNG]})
	
);

assign wExeDone = wExeDoneTmp[0] & wExeDoneTmp[1] & wExeDoneTmp[2];

AND # (`WIDTH) AND_0
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`X_RNG]   ), 
	.iB(        wRS1_OperandB[`X_RNG]   ),
	.oDone(     wExeDoneTmp[0]          ), 
   .oR(        wResult[`X_RNG]         )
);

AND # (`WIDTH) AND_1
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`Y_RNG]   ), 
	.iB(        wRS1_OperandB[`Y_RNG]   ),
	.oDone(     wExeDoneTmp[1]          ),
   .oR(        wResult[`Y_RNG]         )
);

AND # (`WIDTH) AND_2
(
   .Clock(     Clock                   ),
	.Reset(     Reset                   ),
   .iTrigger(   wRS1_2_ADD_Trigger     ),
   .iA(        wRS1_OperandA[`Z_RNG]   ), 
	.iB(        wRS1_OperandB[`Z_RNG]   ),
	.oDone(     wExeDoneTmp[2]          ), 
   .oR(        wResult[`Z_RNG]         )
);

endmodule
