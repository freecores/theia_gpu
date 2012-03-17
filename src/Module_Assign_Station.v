`include "aDefinitions.v"



module ASSIGN_STATION
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


FFD_POSEDGE_SYNCRONOUS_RESET # (1) FFD0 (Clock,Reset,1'b1,wRS1_2_ADD_Trigger,wExeDone);


assign wResult = wRS1_OperandA;

endmodule
