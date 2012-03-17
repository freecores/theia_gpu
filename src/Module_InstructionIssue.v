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

//`define ADDRESSING_MODES_DISABLED 1
//`define NO_STALL_ON_BRANCH_DEPS 1

`define II_STATE_AFTER_RESET             0
`define II_FETCH_INSTRUCTION             1
`define II_ISSUE_REQUEST_WITH_DATA_FWD   2
`define II_ISSUE_REQUEST                 3
`define II_FIFO_UPDATE                   4
`define II_ISSUE_BRANCH_OPERATION        5 
`define II_UPDATE_PC_BRANCH_OPERATION    6 

`define TAGMEM_OWNER_ISSUE      1'b0
`define TAGMEM_OWNER_FIFO       1'b1

module InstructionIssue
(
   input wire                                   Clock,
	input wire                                   Reset,
	input wire                                   iEnable,
	input wire [`INSTRUCTION_WIDTH-1:0]          iInstruction0,        //Instruction fetched from IM
	input wire [`INSTRUCTION_WIDTH-1:0]          iInstruction1,			 //Branch taken instruction prefetch
	input wire [`DATA_ROW_WIDTH-1:0]             iSourceData0,         //Source0 value from RF
	input wire [`DATA_ROW_WIDTH-1:0]             iSourceData1,         //Source1 value from RF
	input wire [`NUMBER_OF_RSVR_STATIONS-1:0]    iRStationBusy,    
	input wire [`COMMIT_PACKET_SIZE-1:0]         iResultBcast,         //Contains DST and RsId from last commited operation
	input wire                                   iSignFlag,
	input wire                                   iZeroFlag,
	output wire [`DATA_ADDRESS_WIDTH-1:0]        oSourceAddress0,
	output wire [`DATA_ADDRESS_WIDTH-1:0]        oSourceAddress1,
	output wire  [`ISSUE_PACKET_SIZE-1:0]        oIssueBcast, 
   input wire [`DATA_ADDRESS_WIDTH -1:0]        iFrameOffset,	
	output wire  [`INSTRUCTION_ADDR_WIDTH -1:0]  oIP0,
	output wire  [`INSTRUCTION_ADDR_WIDTH -1:0]  oIP1
	
);


parameter  SB_ENTRY_WIDTH = 4;

wire[SB_ENTRY_WIDTH-1:0]                wSource0_Station;     //Reservation Station that is currently calculationg Source0, zero means none
wire[SB_ENTRY_WIDTH-1:0]                wSource1_Station;     //Reservation Station that is currently calculationg Source1, zero means none
wire[SB_ENTRY_WIDTH-1:0]                wSource0_RsSb;           
wire[`DATA_ADDRESS_WIDTH-1:0]           wSBWriteAddress;
wire [SB_ENTRY_WIDTH-1:0]               wSBWriteData;
wire                                    wStall;
wire [`DATA_ROW_WIDTH-1:0]              wSourceData0;
wire [`DATA_ROW_WIDTH-1:0]              wSourceData1;
wire                                    wFIFO_ReadEnable;
wire [`DATA_ADDRESS_WIDTH-1:0]          wFIFO_Dst;
wire [`DATA_ADDRESS_WIDTH-1:0]          wIssue_Dst;
wire                                    wSBWriteEnable;
wire[`DATA_ROW_WIDTH-1:0]               wSignedSourceData0;
wire[`DATA_ROW_WIDTH-1:0]               wSignedSourceData1;
wire[`DATA_ROW_WIDTH-1:0]               wSwizzledSourceData0;
wire[`DATA_ROW_WIDTH-1:0]               wSwizzledSourceData1;
wire [`DATA_ROW_WIDTH-1:0]              wResultData;
wire [`DATA_ROW_WIDTH-1:0]              wSourceData1Temp;
wire [`DATA_ROW_WIDTH-1:0]              wScaledSourceData0;
wire [`DATA_ROW_WIDTH-1:0]              wScaledSourceData1;
wire [`DATA_ROW_WIDTH-1:0]              wScaledSourceData0_Pre;
wire [`DATA_ROW_WIDTH-1:0]              wScaledSourceData1_Pre;
wire [`DATA_ROW_WIDTH-1:0]              wUnscaleSourceData0_Pre;
wire [`DATA_ROW_WIDTH-1:0]              wUnscaleSourceData1_Pre;

wire wBranchTaken;
wire wCommitBusInputFifo_Empty;
wire wCommitBusDataAvailabe;
wire wReservationStationBusy;
wire [`COMMIT_PACKET_SIZE-1:0] wResultFifoData;
reg rTagMemoryWE,rTagMemOwner,rIssueNow,rIncrementPC,rPopFifo,rBypassFifo,rUseForwardedData;
reg rSetPCBranchTaken;
wire wBranchWithDependency;

assign wStall = 0;//iInstruction0[`INST_EOF_RNG];

reg [4:0]  rCurrentState, rNextState;
//Next states logic and Reset sequence
always @(posedge Clock ) 
  begin 
			
    if (Reset | ~iEnable)  
		rCurrentState <= `II_STATE_AFTER_RESET; 
    else        
		rCurrentState <= rNextState; 
		
end




always @ ( * )
begin
	case (rCurrentState)
	//--------------------------------------
	`II_STATE_AFTER_RESET:
	begin
	   rTagMemoryWE   = 1'b0;
		rTagMemOwner   = 1'b0;
		rIssueNow      = 1'b0;
		rIncrementPC   = 1'b0;
		rPopFifo       = 1'b0;
		rBypassFifo    = 1'b0;
		rUseForwardedData  = 1'b0;
		rSetPCBranchTaken  = 1'b0;
		
		rNextState = `II_FETCH_INSTRUCTION;
	end
	//--------------------------------------
	/*The PC will be incremented except for the scenario where we need to wait
	for reservation stations to become available. If we increment the PC, then the
	value of PC will get update the next clock cycle, and another clock cycle 
	after that the instruction will get updated.
	1- If there is data waiting on the commit bus input port this cycle,
	then do not queue this data into the FIFO but instead set
	set the score board write enable to 1, set the wSBWriteAddress 
	to the CommitPacket Destination range 	and update the score board
	bit to zero, so than in the next state the score board bit associated
	to the commit data has been updated.
	2 - If there is no data waiting on the commit bus this clock cycle, but there
	is data that has been queued into the input FIFO, then go to a state where this
	data status on the scoreboard gets updated.
	3 - If there are no available reservation stations left to handle this 
	instruction (structural hazard) then just stay in these same state to wait for 
	a reservation station to become availabe.
	*/
	`II_FETCH_INSTRUCTION:
	begin
		rTagMemoryWE   = wCommitBusDataAvailabe;
		rTagMemOwner   = `TAGMEM_OWNER_ISSUE;
		rIssueNow      = 1'b0;
		rIncrementPC   = ( ~wReservationStationBusy & ~iInstruction0[`INST_BRANCH_BIT] & wCommitBusInputFifo_Empty) | (~wReservationStationBusy & ~iInstruction0[`INST_BRANCH_BIT] & wCommitBusDataAvailabe);		
		rPopFifo       = 1'b0;
		rBypassFifo    = wCommitBusDataAvailabe;			//Write iCommitBus data directly into tag mem
		rUseForwardedData  = 1'b0;
		rSetPCBranchTaken  = 1'b0;
		
		if (wCommitBusDataAvailabe & ~wReservationStationBusy)
			rNextState = `II_ISSUE_REQUEST_WITH_DATA_FWD;
		else if (~wCommitBusInputFifo_Empty)
			rNextState = `II_FIFO_UPDATE;	
		else if ( wReservationStationBusy )
			rNextState = `II_FETCH_INSTRUCTION;
		else	
			rNextState = `II_ISSUE_REQUEST;
	end
		//--------------------------------------
		//TODO: If the reservation station is Busy (static hazard)
		//Then we shall stall the machine...
	`II_ISSUE_REQUEST:
	begin
		rTagMemoryWE   = ~iInstruction0[`INST_BRANCH_BIT];
		rTagMemOwner   = `TAGMEM_OWNER_ISSUE;
		rIssueNow      = 1'b1;
		rIncrementPC   = (iInstruction0[`INST_BRANCH_BIT] & ~wBranchWithDependency);
		rPopFifo       = 1'b0;
		rBypassFifo    = 1'b0;
		rUseForwardedData  = 1'b0;
		rSetPCBranchTaken  = 1'b0;
		
		if (iInstruction0[`INST_BRANCH_BIT])
			rNextState = `II_UPDATE_PC_BRANCH_OPERATION;
		else
		   rNextState = `II_FETCH_INSTRUCTION;
	end
	//--------------------------------------
	/*
	Here the instruction remains the same as in the
	previous clock cycle.
	*/
	`II_ISSUE_REQUEST_WITH_DATA_FWD:
	begin
		rTagMemoryWE   = ~iInstruction0[`INST_BRANCH_BIT];
		rTagMemOwner   = `TAGMEM_OWNER_ISSUE;
		rIssueNow      = 1'b1;
		rIncrementPC   = (iInstruction0[`INST_BRANCH_BIT] & ~wBranchWithDependency);
		rPopFifo       = 1'b1;
		rBypassFifo    = 1'b0;
		rUseForwardedData  = 1'b1;
		rSetPCBranchTaken  = 1'b0;//wBranchTaken;
		
		if (iInstruction0[`INST_BRANCH_BIT])
			rNextState = `II_UPDATE_PC_BRANCH_OPERATION;
		else
		   rNextState = `II_FETCH_INSTRUCTION;
	end
	//--------------------------------------
	`II_FIFO_UPDATE:
	begin
		rTagMemoryWE   = 1'b1;
		rTagMemOwner   = `TAGMEM_OWNER_FIFO;
		rIssueNow      = 1'b0;
		rIncrementPC   = 1'b0;
		rPopFifo       = 1'b1;
		rBypassFifo    = 1'b0;
		rUseForwardedData  = 1'b0;
		rSetPCBranchTaken  = 1'b0;
		
		if (wBranchWithDependency)
			rNextState = `II_UPDATE_PC_BRANCH_OPERATION;
		else
			rNextState = `II_FETCH_INSTRUCTION;
	end
	//--------------------------------------
	//FIXME: You are assuming that the branch takes 1 cycle.
	//This may noy always be the case..
	`II_UPDATE_PC_BRANCH_OPERATION:
	begin
	   rTagMemoryWE   = 1'b0;
		rTagMemOwner   = `TAGMEM_OWNER_FIFO;
		rIssueNow      = 1'b0;
		rIncrementPC   = 1'b0;
		rPopFifo       = 1'b1;
		rBypassFifo    = 1'b0;
		rUseForwardedData  = 1'b0;
		rSetPCBranchTaken  = wBranchTaken;
		
`ifdef NO_STALL_ON_BRANCH_DEPS	
		rNextState = `II_FETCH_INSTRUCTION;
`else
		if (~wBranchWithDependency)
			rNextState = `II_FETCH_INSTRUCTION;
		else if (~wCommitBusInputFifo_Empty)
			rNextState = `II_FIFO_UPDATE;		
		else
			rNextState = `II_UPDATE_PC_BRANCH_OPERATION;
`endif		
	end
	//--------------------------------------
	default:
	begin
		rTagMemOwner   = `TAGMEM_OWNER_ISSUE;
	   rTagMemoryWE   = 1'b0;
		rIssueNow      = 1'b0;
		rIncrementPC   = 1'b0;
		rPopFifo       = 1'b0;
		rBypassFifo    = 1'b0;
		rUseForwardedData  = 1'b0;
		rSetPCBranchTaken  = 1'b0;
		
		rNextState = `II_STATE_AFTER_RESET;
	end
	//--------------------------------------
	endcase
	
		
end

wire [2:0] wInstructionBranchSelection;
assign wInstructionBranchSelection = iInstruction0[`INST_BRANCH_OP_RNG];

assign wBranchTaken = 
iInstruction0[`INST_BRANCH_BIT] &
(
~wInstructionBranchSelection[2] & ~wInstructionBranchSelection[1] & ~wInstructionBranchSelection[0] |                          //inconditional BRANCH  
~wInstructionBranchSelection[2] & ~wInstructionBranchSelection[1] & wInstructionBranchSelection[0] & iZeroFlag |                 //==
~wInstructionBranchSelection[2] & wInstructionBranchSelection[1] & ~wInstructionBranchSelection[0] & ~iZeroFlag |                //!=
~wInstructionBranchSelection[2] & wInstructionBranchSelection[1] & wInstructionBranchSelection[0] & iSignFlag |                  //<
wInstructionBranchSelection[2] & ~wInstructionBranchSelection[1] & ~wInstructionBranchSelection[0] & (~iSignFlag & ~iZeroFlag)|  //>
wInstructionBranchSelection[2] & ~wInstructionBranchSelection[1] & wInstructionBranchSelection[0] & (iSignFlag | iZeroFlag) |    //<=
wInstructionBranchSelection[2] & wInstructionBranchSelection[1] & ~wInstructionBranchSelection[0] & (~iSignFlag | iZeroFlag)     //>=
);

wire [`COMMIT_PACKET_SIZE-1:0] wCommitData_Latched;
FFD_POSEDGE_SYNCRONOUS_RESET # ( `COMMIT_PACKET_SIZE ) ICOMMIT_BYPASS_FFD
( 	Clock, Reset, 1'b1 ,iResultBcast  , wCommitData_Latched  );


//The Reservation Station scoreboard
wire [SB_ENTRY_WIDTH-1:0] wSBDataPort0;
wire [SB_ENTRY_WIDTH-1:0] wSBDataPort1;
wire[3:0] wReservationStation;

 `ifdef ADDRESSING_MODES_DISABLED
 
assign wSBWriteAddress
 = (rTagMemOwner == `TAGMEM_OWNER_ISSUE) ? ((rBypassFifo)?iResultBcast[`COMMIT_DST_RNG]:iInstruction0[`INST_DST_RNG]) 
 : wResultFifoData[`COMMIT_DST_RNG];
 
 `else
 
 assign wSBWriteAddress
 = (rTagMemOwner == `TAGMEM_OWNER_ISSUE) ? ((rBypassFifo)?iResultBcast[`COMMIT_DST_RNG]:wDestinationIndex) 
 : wResultFifoData[`COMMIT_DST_RNG];
`endif
 
assign wSBWriteData    
= (rTagMemOwner == `TAGMEM_OWNER_ISSUE) ? ((rBypassFifo)?1'b0:wReservationStation) : 4'b0;


RAM_DUAL_READ_PORT # ( SB_ENTRY_WIDTH, `DATA_ADDRESS_WIDTH ) SB
(
 .Clock(             Clock                          ),
 .iWriteEnable(      rTagMemoryWE                   ),
 .iReadAddress0(     oSourceAddress0                ),
 .iReadAddress1(     oSourceAddress1                ),
 .iWriteAddress(     wSBWriteAddress                ),
 .iDataIn(           wSBWriteData                   ),
 .oDataOut0(         wSBDataPort0                   ),
 .oDataOut1(         wSBDataPort1                   )
);


wire [`INSTRUCTION_ADDR_WIDTH-1:0]  wPCInitialValue;
wire [`INSTRUCTION_ADDR_WIDTH-1:0] wPCInitialTmp;
assign wPCInitialTmp = (iInstruction0[`INST_IMM])? wSourceData0[7:0] : {2'b0,iInstruction0[`INST_DST_RNG]};

assign wPCInitialValue =  (rSetPCBranchTaken & ~Reset) ? wPCInitialTmp : `INSTRUCTION_ADDR_WIDTH'b0;


//The program counter
UPCOUNTER_POSEDGE # (`INSTRUCTION_ADDR_WIDTH ) PC
(
	.Clock(    Clock                       ),
	.Reset(    Reset | rSetPCBranchTaken   ),
	.Enable(   rIncrementPC  & ~wStall     ),
	.Initial(  wPCInitialValue             ),
	.Q(        oIP0                        )
);

assign oIP1 = iInstruction0[`INST_DST_RNG];


`ifdef ADDRESSING_MODES_DISABLED
assign oSourceAddress1     = iInstruction0[`INST_SCR1_ADDR_RNG];
`else
assign oSourceAddress1     = 
(iInstruction0[`INST_SRC1_DISPLACED]) ? (iInstruction0[`INST_SCR1_ADDR_RNG] + iFrameOffset): iInstruction0[`INST_SCR1_ADDR_RNG];
`endif


`ifdef ADDRESSING_MODES_DISABLED
assign oSourceAddress0     = (iInstruction0[`INST_IMM]) ? iInstruction0[`INST_DST_RNG] : iInstruction0[`INST_SRC0_ADDR_RNG];
`else

//(iInstruction0[`INST_IMM])  ? iInstruction0[`INST_DST_RNG] : iInstruction0[`INST_SRC0_ADDR_RNG];//oSourceAddress0;
assign oSourceAddress0     = (iInstruction0[`INST_IMM]) ? iInstruction0[`INST_DST_RNG] : 
((iInstruction0[`INST_SRC0_DISPLACED]) ? (iInstruction0[`INST_SRC0_ADDR_RNG] + iFrameOffset): iInstruction0[`INST_SRC0_ADDR_RNG]);
`endif


assign wCommitBusDataAvailabe = iResultBcast[`COMMIT_RSID_RNG] != `OPERATION_NOP;


sync_fifo  # (`COMMIT_PACKET_SIZE,2 ) RESULT_IN_FIFO
(
 .clk(    Clock              ),
 .reset(  Reset              ),
 .din(    iResultBcast       ),
 .wr_en(  wCommitBusDataAvailabe  ),
 .rd_en(  rPopFifo           ),
 .dout(   wResultFifoData    ),
 .empty(  wCommitBusInputFifo_Empty   )
 
);





//Source 1 for IMM values is really DST

//Reservation station for SRC0 when handling IMM values is zero

wire wSB0FromInCommit,wSB0ForwardDetected;
wire wSB1FromInCommit,wSB1ForwardDetected;

assign wSB0FromInCommit = 1'b0;//(rIssueNow && (iResultBcast[`COMMIT_DST_RNG] == oSourceAddress0)) ? 1'b1 : 1'b0;
assign wSB1FromInCommit = 1'b0;//(rIssueNow && (iResultBcast[`COMMIT_DST_RNG] == oSourceAddress1)) ? 1'b1 : 1'b0;

`ifdef ADDRESSING_MODES_DISABLED
wire [`DATA_ADDRESS_WIDTH-1:0] wTmpAddr0;
assign wTmpAddr0 = (iInstruction0[`INST_IMM])  ? iInstruction0[`INST_DST_RNG] : iInstruction0[`INST_SRC0_ADDR_RNG];

assign wSB0ForwardDetected = (rUseForwardedData && (wCommitData_Latched[`COMMIT_DST_RNG] == wTmpAddr0) ) ? 1'b1 : 1'b0;
assign wSB1ForwardDetected = (rUseForwardedData && (wCommitData_Latched[`COMMIT_DST_RNG] == iInstruction0[`INST_SCR1_ADDR_RNG]) ) ? 1'b1 : 1'b0;
`else
wire [`DATA_ADDRESS_WIDTH-1:0] wTmpAddr0,wTmpAddr1;
assign wTmpAddr0 = oSourceAddress0;
assign wTmpAddr1 = oSourceAddress1;

assign wSB0ForwardDetected = (rUseForwardedData && (wCommitData_Latched[`COMMIT_DST_RNG] == wTmpAddr0) ) ? 1'b1 : 1'b0;
assign wSB1ForwardDetected = (rUseForwardedData && (wCommitData_Latched[`COMMIT_DST_RNG] == wTmpAddr1) ) ? 1'b1 : 1'b0;
`endif

assign wSource0_Station = (wSB0FromInCommit | wSB0ForwardDetected) ? 4'b0    : wSBDataPort0;
assign wSource1_Station = (iInstruction0[`INST_IMM] | wSB1FromInCommit | wSB1ForwardDetected) ? 4'b0: wSBDataPort1;


//Handle literal values for IMM. IMM is stored in SRC1.X


wire [`DATA_ROW_WIDTH-1:0]  wImmValue,wSource1_Temp,wSource0_Temp;
assign wImmValue[`X_RNG] = (iInstruction0[`INST_WE_X]) ? iInstruction0[`INST_IMM_RNG] : `WIDTH'b0;
assign wImmValue[`Y_RNG] = (iInstruction0[`INST_WE_Y]) ? iInstruction0[`INST_IMM_RNG] : `WIDTH'b0;
assign wImmValue[`Z_RNG] = (iInstruction0[`INST_WE_Z]) ? iInstruction0[`INST_IMM_RNG] : `WIDTH'b0;



assign wSource1_Temp[`X_RNG] = (wSB1FromInCommit & iResultBcast[`COMMIT_WE_X]) ? iResultBcast[`COMMIT_X_RNG] : 
( (wSB1ForwardDetected & wCommitData_Latched[`COMMIT_WE_X])? wCommitData_Latched[`X_RNG] : iSourceData1[`X_RNG]);

assign wSource1_Temp[`Y_RNG] = (wSB1FromInCommit & iResultBcast[`COMMIT_WE_Y]) ? iResultBcast[`COMMIT_Y_RNG] :
( (wSB1ForwardDetected & wCommitData_Latched[`COMMIT_WE_Y]) ? wCommitData_Latched[`Y_RNG] : iSourceData1[`Y_RNG]);
 
 
assign wSource1_Temp[`Z_RNG] = (wSB1FromInCommit & iResultBcast[`COMMIT_WE_Z]) ? iResultBcast[`COMMIT_Z_RNG] :
( (wSB1ForwardDetected & wCommitData_Latched[`COMMIT_WE_Z]) ?  wCommitData_Latched[`Z_RNG] : iSourceData1[`Z_RNG]);

assign wSource0_Temp[`X_RNG] =  (wSB0FromInCommit & iResultBcast[`COMMIT_WE_X]) ? iResultBcast[`COMMIT_X_RNG]:
( (wSB0ForwardDetected & & wCommitData_Latched[`COMMIT_WE_X] )? wCommitData_Latched[`X_RNG]:iSourceData0[`X_RNG]);
 
 
assign wSource0_Temp[`Y_RNG] =  (wSB0FromInCommit & iResultBcast[`COMMIT_WE_Y]) ? iResultBcast[`COMMIT_Y_RNG]:
( (wSB0ForwardDetected & & wCommitData_Latched[`COMMIT_WE_Y])? wCommitData_Latched[`Y_RNG] : iSourceData0[`Y_RNG]);

assign wSource0_Temp[`Z_RNG] =  (wSB0FromInCommit & iResultBcast[`COMMIT_WE_Z]) ? iResultBcast[`COMMIT_Z_RNG]:
( (wSB0ForwardDetected & & wCommitData_Latched[`COMMIT_WE_Z])? wCommitData_Latched[`Z_RNG] : iSourceData0[`Z_RNG]);



//If the data we are looking for just arrived at iResultBcast the use that
//other wise used the data from the Register file or the Immediate values
assign wSourceData1 = (iInstruction0[`INST_IMM]) ? wImmValue : wSource1_Temp;
assign wSourceData0 = (iInstruction0[`INST_IMM] && iInstruction0[`INST_DEST_ZERO]) ? `DATA_ROW_WIDTH'd0 : wSource0_Temp;



assign wReservationStationBusy = 
(
((iInstruction0[`INST_CODE_RNG] == `OPERATION_ADD ) && (iRStationBusy[ 0  ] && iRStationBusy[ 1  ])) ||
((iInstruction0[`INST_CODE_RNG] == `OPERATION_DIV ) &&  iRStationBusy[ 2  ]) ||
((iInstruction0[`INST_CODE_RNG] == `OPERATION_MUL ) &&  iRStationBusy[ 3  ])
);

assign wBranchWithDependency = (iInstruction0[`INST_BRANCH_BIT] && (wSource0_Station != 0 || wSource1_Station != 0));

wire [6:0] wOp;
assign wOp = iInstruction0[`INST_CODE_RNG];

assign wReservationStation[0] =
(wOp[0] & ~wOp[1] & ~wOp[2] & ~wOp[3] & ~iRStationBusy[ 0  ]  ) |
(~wOp[0] & wOp[1] & ~wOp[2] & ~wOp[3] & ~iRStationBusy[ 2  ]) |
(~wOp[0] & ~wOp[1] & wOp[2] & ~wOp[3] & ~iRStationBusy[ 4  ]);


assign wReservationStation[1] =
(wOp[0] & ~wOp[1] & ~wOp[2] & ~wOp[3] & iRStationBusy[ 0  ] & ~iRStationBusy[1]) |
(~wOp[0] & wOp[1] & ~wOp[2] & ~wOp[3] & ~iRStationBusy[ 2  ]);

//assign wReservationStation[2] = 1'b0;
assign wReservationStation[2] = 
(wOp[0] & wOp[1] & ~wOp[2] & ~wOp[3] & ~iRStationBusy[3]) |
(~wOp[0] & ~wOp[1] & wOp[2] & ~wOp[3] & ~iRStationBusy[ 4  ]);

assign wReservationStation[3] = 1'b0;

//Sign control logic.
//Only works for non literal opeations (INST_IMM == 0)
wire [`ISSUE_SRCTAG_SIZE-1:0]  wIssueTag0,wIssueTag1;

 assign wIssueTag0 = (iInstruction0[`INST_IMM]) ? `ISSUE_SRCTAG_SIZE'b0 : {iInstruction0[`INST_SRC0_SIGN_RNG],iInstruction0[`INST_SRC0_SWZL_RNG] };
 assign wIssueTag1 = (iInstruction0[`INST_IMM]) ? `ISSUE_SRCTAG_SIZE'b0 : {iInstruction0[`INST_SRC1_SIGN_RNG],iInstruction0[`INST_SCR1_SWZL_RNG] };
 
wire [`DATA_ADDRESS_WIDTH -1:0] wDestinationIndex; 


`ifdef ADDRESSING_MODES_DISABLED
assign wDestinationIndex = iInstruction0[`INST_DST_RNG];
`else
//assign wDestinationIndex = 
//(iInstruction0[`INST_IMM] == 0 && iInstruction0[`INST_DEST_ZERO]) ? (iInstruction0[`INST_DST_RNG] + iFrameOffset) : iInstruction0[`INST_DST_RNG];

wire [`DATA_ADDRESS_WIDTH -1:0] wDestIndexDisplaced,wDestinationIndex_NoIMM,wDestinationIndex_IMM; 

assign wDestIndexDisplaced     = (iInstruction0[`INST_DST_RNG] + iFrameOffset);
assign wDestinationIndex_NoIMM = (iInstruction0[`INST_DEST_ZERO]) 		? wDestIndexDisplaced : iInstruction0[`INST_DST_RNG];
assign wDestinationIndex_IMM   = (iInstruction0[`INST_SRC0_DISPLACED])	? wDestIndexDisplaced : iInstruction0[`INST_DST_RNG];

assign wDestinationIndex = (iInstruction0[`INST_IMM]) ? wDestinationIndex_IMM : wDestinationIndex_NoIMM;
`endif

assign oIssueBcast = (Reset | ~rIssueNow | wStall ) ? `ISSUE_PACKET_SIZE'b0 : 
{
wReservationStation,
//iInstruction0[`INST_DST_RNG],
wDestinationIndex, 
iInstruction0[`INST_WE_RNG],
iInstruction0[`INST_SCOP_RNG],
wSource1_Station, 
wIssueTag1,
wSourceData1,

wSource0_Station, 
wIssueTag0,
wSourceData0

};

endmodule
