`include "aDefinitions.v"

module ReservationStation
(
	input wire                                                Clock,
	input wire                                                Reset,
	input wire [`MOD_ISSUE_PACKET_SIZE-1:0]                   iIssueBus,
	input wire [`MOD_COMMIT_PACKET_SIZE-1:0]                  iCommitBus,
	input wire [3:0]                                          iMyId,
	input wire                                                iExecutionDone,
	input wire                                                iCommitGranted,
	input wire [`DATA_ROW_WIDTH-1:0]                          iResult,
	output wire [`DATA_ROW_WIDTH-1:0]                         oSource1,
	output wire [`DATA_ROW_WIDTH-1:0]                         oSource0,
	output wire [`DATA_ADDRESS_WIDTH-1:0]                     oDestination,
	output wire [`DATA_ROW_WIDTH-1:0]                         oResult,
	output wire [2:0]                                         oWE,
	output wire [3:0]                                         oId,
	output wire                                               oBusy,
	output wire                                               oTrigger,
	output wire                                               oCommitRequest
	
);

wire                                wStall;
wire                                wLatchRequest;
wire [3:0]                          wSource1_RS;
wire [3:0]                          wSource0_RS;
wire [3:0]                          wMyId;
wire                                wTrigger;
//wire                                wFIFO_Pop;

wire [`MOD_ISSUE_PACKET_SIZE-1:0]   wIssue_Latched;
wire [`DATA_ADDRESS_WIDTH-1:0]      wDestination;
wire [3:0]                          wID;
wire [2:0]                          wWE;
wire                                wCommitFifoFull;
wire [`ISSUE_SRCTAG_SIZE-1:0] wTag0,wTag1;


//assign wFIFO_Pop = iExecutionDone;
assign oCommitRequest = iExecutionDone;
assign wLatchRequest = ( iIssueBus[`MOD_ISSUE_RSID_RNG] == iMyId) ? 1'b1 : 1'b0;
//If there are no dependencies then just trigger execution
//assign oTrigger = (wTrigger /*&& (iIssueBus[`ISSUE_SRC0RS_RNG] == 0) && (iIssueBus[`ISSUE_SRC1RS_RNG] == 0)*/ ) ? 1'b1 : 0;
assign oTrigger = ( (wLatchRequest | wLatchData0FromCommitBus | wLatchData1FromCommitBus) & ~wStall);

assign wStall = (wLatchRequest && (iIssueBus[`MOD_ISSUE_SRC1RS_RNG] != 0 || iIssueBus[`MOD_ISSUE_SRC0RS_RNG] != 0)) ? 1'b1 : 1'b0;
//assign wStall = (wSource1_RS == 0 & wSource0_RS == 0) ? 1'b0 : 1'b1;

wire wLatchData0FromCommitBus;
wire wLatchData1FromCommitBus;


assign wLatchData0FromCommitBus = ((wStall == 1'b1) && (iCommitBus[`MOD_COMMIT_RSID_RNG] == wSource0_RS)) ? 1'b1 : 1'b0;
assign wLatchData1FromCommitBus = ((wStall == 1'b1) && (iCommitBus[`MOD_COMMIT_RSID_RNG] == wSource1_RS)) ? 1'b1 : 1'b0;

wire wBusy;
assign oBusy = wBusy | wCommitFifoFull & ~iCommitGranted; 
wire wCommitGrantedDelay;

UPCOUNTER_POSEDGE # ( 1 ) BUSY
(
	.Clock(    Clock                       ),
	.Reset(    Reset                       ),
	.Enable(   wLatchRequest |  iCommitGranted        ),
	.Initial( 1'b0   ),
	.Q(        wBusy                        )
);





assign oSource1 =  (wLatchData0FromCommitBus) ? iCommitBus[`MOD_COMMIT_DATA_RNG] : iIssueBus[`MOD_ISSUE_SRC0_DATA_RNG];
assign oSource0 =  (wLatchData1FromCommitBus) ? (/*(wDstZero)?`DATA_ROW_WIDTH'b0:*/iCommitBus[`MOD_COMMIT_DATA_RNG]) : iIssueBus[`MOD_ISSUE_SRC1_DATA_RNG];
assign wTrigger = ( wLatchRequest | wLatchData0FromCommitBus | wLatchData1FromCommitBus);


wire [`DATA_ROW_WIDTH-1:0]                    wSrc1,wSrc0;
//FFD_POSEDGE_SYNCRONOUS_RESET # ( `MOD_ISSUE_PACKET_SIZE ) ISSUE_FFD
//( 	Clock, Reset, wLatchRequest , iIssueBus, {wDstZero,wID,wWE,wDestination,wSource1_RS,wSource0_RS,wSrc1,wSrc0} );

wire [3:0] wScale;
FFD_POSEDGE_SYNCRONOUS_RESET # ( `MOD_ISSUE_PACKET_SIZE ) ISSUE_FFD
( 	Clock, Reset, wLatchRequest , iIssueBus, {wID,wDestination,wWE,wScale,wSource1_RS,wSrc1,wSource0_RS,wSrc0} );

assign wTag0 = wSrc0[`MOD_ISSUE_TAG0_RNG];
assign wTag1 = wSrc1[`MOD_ISSUE_TAG0_RNG];
 
sync_fifo  # (`COMMIT_PACKET_SIZE ) COMMIT_OUT_FIFO
(
 .clk(   Clock          ),
 .reset( Reset          ),
 .din(   {wID,wWE,wDestination,iResult}     ),
 .wr_en( iExecutionDone ),
 .rd_en( iCommitGranted ),
 .dout(  {oId,oWE,oDestination,oResult}        ),
 .full(  wCommitFifoFull          )
 
);

/*
FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) FFD_Trigger
( 	Clock, Reset, 1'b1 , wLatchRequest, wTrigger );

*/
endmodule

//-------------------------------------------------------------------------------------------------
module ReservationStation_1Cycle
(
	input wire                                                Clock,
	input wire                                                Reset,
	input wire [`MOD_ISSUE_PACKET_SIZE-1:0]                   iIssueBus,
	input wire [`MOD_COMMIT_PACKET_SIZE-1:0]                  iCommitBus,
	input wire [3:0]                                          iMyId,
	input wire                                                iExecutionDone,
	input wire                                                iCommitGranted,
	input wire [`DATA_ROW_WIDTH-1:0]                          iResult,
	output wire [`DATA_ROW_WIDTH-1:0]                         oSource1,
	output wire [`DATA_ROW_WIDTH-1:0]                         oSource0,
	output wire [`DATA_ADDRESS_WIDTH-1:0]                     oDestination,
	output wire [`DATA_ROW_WIDTH-1:0]                         oResult,
	output wire [`SCALE_SIZE-1:0]                             oScale,
	output wire [2:0]                                         oWE,
	output wire [3:0]                                         oId,
	output wire                                               oBusy,
	output wire                                               oTrigger,
	output wire                                               oCommitRequest
	
);


wire [3:0]                          wSource1_RS;
wire [3:0]                          wSource0_RS;
wire [3:0]                          wMyId;
wire                                wTrigger;
wire [`DATA_ADDRESS_WIDTH-1:0]      wDestination;
wire [3:0]                          wID;
wire [2:0]                          wWE;
wire [`DATA_ROW_WIDTH-1:0]          wSrc1,wSrc0,wResult;
//wire                                wDstZero;
wire [`DATA_ROW_WIDTH-1:0]          wSrc1_Fwd;
wire [`DATA_ROW_WIDTH-1:0]          wSrc0_Fwd;

wire wSrc0_Dependency_Initial, wSrc0_Dependency;
wire wSrc1_Dependency_Initial, wSrc1_Dependency;
wire wSrc0_DependencyResolved, wSrc0_DependencyLatch;
wire wSrc1_DependencyResolved, wSrc1_DependencyLatch;
wire wWaitingDependency;
wire wHandleCurrentIssue;
wire wDependencyResolved;
wire [`ISSUE_SRCTAG_SIZE-1:0] wTag0,wTag1;
wire wSrc0_DependencyLatch_Pre,wSrc1_DependencyLatch_Pre;

assign wHandleCurrentIssue = ( iIssueBus[`MOD_ISSUE_RSID_RNG] == iMyId) ? 1'b1 : 1'b0;
assign wSrc0_Dependency_Initial     = wHandleCurrentIssue & (iIssueBus[96] | iIssueBus[97] | iIssueBus[98] | iIssueBus[99]);
assign wSrc1_Dependency_Initial     = wHandleCurrentIssue & (iIssueBus[196] | iIssueBus[197] | iIssueBus[198] | iIssueBus[199]);


assign oTrigger = 
	 (~wWaitingDependency & wHandleCurrentIssue & ~wSrc0_Dependency_Initial & ~wSrc1_Dependency_Initial)
	|(wWaitingDependency  & ~wSrc1_Dependency  &  wSrc0_Dependency  & wSrc0_DependencyResolved )
	|(wWaitingDependency  &  wSrc1_Dependency &  ~wSrc0_Dependency  & wSrc1_DependencyResolved )
	|(wWaitingDependency  &  wSrc1_Dependency  &  wSrc0_Dependency  & wSrc1_DependencyResolved & wSrc0_DependencyResolved );
	
assign wDependencyResolved = wWaitingDependency & ~wSrc1_Dependency & ~wSrc0_Dependency;

assign wSrc0_DependencyLatch_Pre = ( wSrc0_Dependency && (iCommitBus[`MOD_COMMIT_RSID_RNG] == wSource0_RS && iCommitBus[`MOD_COMMIT_TAG_RNG] == wTag0)  ) ? 1'b1 : 1'b0;  
assign wSrc1_DependencyLatch_Pre = ( wSrc1_Dependency && (iCommitBus[`MOD_COMMIT_RSID_RNG] == wSource1_RS && iCommitBus[`MOD_COMMIT_TAG_RNG] == wTag1)  ) ? 1'b1 : 1'b0;  

PULSE P1 (	Clock,Reset, 1'b1, wSrc0_DependencyLatch_Pre, wSrc0_DependencyLatch);
PULSE P2 (	Clock,Reset, 1'b1, wSrc1_DependencyLatch_Pre, wSrc1_DependencyLatch);

wire wWaitingForCommitGranted;
UPCOUNTER_POSEDGE # ( 1 ) FFD_101
( Clock, Reset,  1'b0, (oBusy & (iCommitGranted ^ wDependencyResolved)  ), wWaitingForCommitGranted );

UPCOUNTER_POSEDGE # ( 1 ) FFD_10
( Clock, Reset,  1'b0, wSrc0_DependencyLatch | wDependencyResolved, wSrc0_DependencyResolved );

UPCOUNTER_POSEDGE # ( 1 ) FFD_11
( Clock, Reset,  1'b0, wSrc1_DependencyLatch | wDependencyResolved,  wSrc1_DependencyResolved );

FFD_POSEDGE_SYNCRONOUS_RESET # ( `DATA_ROW_WIDTH ) FFD_DEP0
( Clock, Reset, wSrc1_DependencyLatch, iCommitBus[`MOD_COMMIT_DATA_RNG],wSrc1_Fwd );

FFD_POSEDGE_SYNCRONOUS_RESET # ( `DATA_ROW_WIDTH ) FFD_DEP1
( Clock, Reset, wSrc0_DependencyLatch, iCommitBus[`MOD_COMMIT_DATA_RNG],wSrc0_Fwd );


//assign oBusy = wWaitingDependency;
UPCOUNTER_POSEDGE # ( 1 ) BUSY
(
	.Clock(    Clock                                                                           ),
	.Reset(    Reset                                                                           ),
	.Enable(   wSrc0_Dependency_Initial | wSrc1_Dependency_Initial |   ((wWaitingForCommitGranted|wDependencyResolved)/*WaitingDependency*/ & iCommitGranted)     ),//***
	.Initial( 1'b0                                                                             ),
	.Q(        oBusy                                                              )
);

wire wCommitRequest;
UPCOUNTER_POSEDGE # ( 1 ) CRQ
(
	.Clock(    Clock                                                                           ),
	.Reset(    Reset                                                                           ),
	.Enable(   oTrigger |  iCommitGranted ),
	.Initial( 1'b0                                                                             ),
	.Q(        wCommitRequest                                                              )
);
assign oCommitRequest = oTrigger | (wCommitRequest & ~iCommitGranted);

assign oResult      = iResult;
assign oSource1    = (wWaitingDependency) ? ((wSrc1_Dependency)? (wSrc1_Fwd):wSrc1) : iIssueBus[`MOD_ISSUE_SRC1_DATA_RNG];
assign oSource0    = (wWaitingDependency) ? ((wSrc0_Dependency)? (wSrc0_Fwd):wSrc0) : iIssueBus[`MOD_ISSUE_SRC0_DATA_RNG];

UPCOUNTER_POSEDGE # ( 1 ) DEP
(
	.Clock(    Clock                                                                           ),
	.Reset(    Reset                                                                           ),
	.Enable(   wSrc0_Dependency_Initial | wSrc1_Dependency_Initial |  wDependencyResolved      ),//***
	.Initial( 1'b0                                                                             ),
	.Q(        wWaitingDependency                                                              )
);
	
UPCOUNTER_POSEDGE # ( 1 ) DEPA
(
	.Clock(    Clock                                                     ),
	.Reset(    Reset                                                     ),
	.Enable(   wSrc0_Dependency_Initial |  wSrc0_DependencyResolved      ),
	.Initial(  1'b0                                                      ),
	.Q(        wSrc0_Dependency                                          )
);

UPCOUNTER_POSEDGE # ( 1 ) DEPB
(
	.Clock(    Clock                                                     ),
	.Reset(    Reset                                                     ),
	.Enable(   wSrc1_Dependency_Initial |  wSrc1_DependencyResolved      ),
	.Initial(  1'b0                                                      ),
	.Q(        wSrc1_Dependency                                          )
);


FFD_POSEDGE_SYNCRONOUS_RESET # ( `MOD_ISSUE_PACKET_SIZE ) ISSUE_FFD
( 	Clock, Reset, wHandleCurrentIssue , iIssueBus, {oId,oDestination,oWE,oScale,wSource1_RS,wSrc1,wSource0_RS,wSrc0} );

assign wTag0 = wSrc0[`MOD_ISSUE_TAG0_RNG];
assign wTag1 = wSrc1[`MOD_ISSUE_TAG0_RNG];

endmodule

//-------------------------------------------------------------------------------------------------
