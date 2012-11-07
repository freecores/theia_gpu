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


module IO_STATION
(
   input wire Clock,
   input wire Reset,
   input wire [`MOD_ISSUE_PACKET_SIZE-1:0]                   iIssueBus,
   input wire [`MOD_COMMIT_PACKET_SIZE-1:0]                  iCommitBus,
	input wire [3:0]                                          iId,
	output wire [`COMMIT_PACKET_SIZE-1:0]                     oCommitData,
	output wire                                               oCommitResquest,
	input wire                                                iCommitGranted,
	output wire                                               oBusy,
	//OMEM
   output wire [`DATA_ROW_WIDTH-1:0]                         oOMEMWriteAddress,
   output wire [`DATA_ROW_WIDTH-1:0]                         oOMEMWriteData,
   output wire                                               oOMEMWriteEnable,
	//TMEM
	output wire [`DATA_ROW_WIDTH-1:0]                         oTMEMReadAddress,         //3 * 32 addresses to read from TMEM
	input wire [`DATA_ROW_WIDTH-1:0]                          iTMEMReadData,            //Contains the data read from the TMEM, 3 * 32 bit words
	input wire                                                iTMEMDataAvailable,			//This is set to one once the TMEM read transaction is complete
   output wire                                               oTMEMDataRequest          //Set to one to indicate a TMEM read request
	
);

wire                           wExeDone;
wire [2:0]                     wExeDoneTmp;
wire                           wRS_OMWRITE_Trigger;
wire [`DATA_ROW_WIDTH-1:0]     wRS1_OperandA;
wire [`DATA_ROW_WIDTH-1:0]     wRS1_OperandB;
wire                           wCommitGranted;

wire [2:0]                     wIOOperation;
wire                           wIOTrigger,wIOTrigger_Pre;
wire                           ReadInProgress_Delay;
wire                           wExeDone_pre1,wExeDone_pre2,wExeDone_pre3,wExeDone_pre4;
wire                           wCommitResquest;

//assign oTMEMDataRequest    = (wIOTrigger && wIOOperation == `IO_OPERATION_TMREAD ) ? wIOTrigger : 1'b0;
wire ReadInProgress;
assign ReadInProgress = (wIOOperation == `IO_OPERATION_TMREAD) ? 1'b1 : 1'b0;

assign oTMEMDataRequest    = ((wIOTrigger | ~iTMEMDataAvailable) & ReadInProgress ) ? 1'b1:1'b0;//wIOTrigger : 1'b0;


assign oTMEMReadAddress    = wRS1_OperandA;             //Three separate 32 bit addresses comes here, for 3 addresses


FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) WOP_FFD0 //TODO: This should be 1 bit
( 	Clock, Reset, 1'b1 , wIOTrigger_Pre | wExeDone_pre1 | wExeDone_pre2, wIOTrigger );


FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) WOP_CR //TODO: This should be 1 bit
( 	Clock, Reset, ReadInProgress , wCommitResquest, oCommitResquest );
///////////////////////////
//
// wIOOperation     
//  000             OMEM
//  001             TMEM
//  010             MAILBOX
//  
///////////////////////////
wire wBusy;

ReservationStation_EX RS_EX
(
	.Clock(              Clock                           ),
	.Reset(              Reset                           ),
	.iIssueBus(          iIssueBus                       ),
	.iCommitBus(         iCommitBus                      ),
	.iMyId(              iId                             ),
	.iExecutionDone(     wExeDone                        ),
	.iResult(            iTMEMReadData                   ),
	.iCommitGranted(     wCommitGranted                  ),
	.oSrc1Latched(       wRS1_OperandB                   ),
	.oSrc0Latched(       wRS1_OperandA                   ),
	.oBusy(              wBusy                           ),
	.oScale(             wIOOperation                    ),
	.oTrigger(           wIOTrigger_Pre                  ),
	///
	.oCommitRequest(     wCommitResquest                 ),
	.oId(              oCommitData[`COMMIT_RSID_RNG]                                 ),
	.oWE(              oCommitData[`COMMIT_WE_RNG]                                   ),
	.oDestination(     oCommitData[`COMMIT_DST_RNG]                                  ),
	.oResult(          {oCommitData[`X_RNG],oCommitData[`Y_RNG],oCommitData[`Z_RNG]} )

	
	
);

assign oBusy = (ReadInProgress)? /*oTMEMDataRequest*/ ~iTMEMDataAvailable : wBusy; /// | wIOTrigger_Pre |  wExeDone_pre1 | wExeDone_pre2 | wExeDone;

//assign oCommitResquest      = 1'b0;		                  //This is always zero since we are not writting anything into the RF
//assign oCommitData          = `COMMIT_PACKET_SIZE'd0;    //This is always zero since we are not writting anything into the RF
assign oOMEMWriteEnable     = (wIOTrigger && wIOOperation == `IO_OPERATION_OMWRITE ) ? wIOTrigger : 1'b0;

FFD_POSEDGE_SYNCRONOUS_RESET # ( 96 ) FFD_SRC0
( 	Clock, Reset, wIOTrigger_Pre , wRS1_OperandA, oOMEMWriteData );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 96 ) FFD_SRC1
( 	Clock, Reset, wIOTrigger_Pre , wRS1_OperandB, oOMEMWriteAddress );


//assign oOMEMWriteData    = wRS1_OperandA;             //Write 96 bits to external memory OMEM
//assign oOMEMWriteAddress = wRS1_OperandB;             //Each 32 bit words has the write address

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD0
( 	Clock, Reset, 1'b1 , wIOTrigger_Pre | wExeDone_pre1 | wExeDone_pre2, wIOTrigger );

//It takes 3 clock cycles to write the 96 bits into OMEM

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD1
( 	Clock, Reset, 1'b1 , wIOTrigger_Pre, wExeDone_pre1 );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD2
( 	Clock, Reset, 1'b1 , wExeDone_pre1, wExeDone_pre2 );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD3
( 	Clock, Reset, 1'b1 , wExeDone_pre2, wExeDone_pre3 );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD4
( 	Clock, Reset, 1'b1 , wExeDone_pre3, wExeDone_pre4 );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD5
( 	Clock, Reset, 1'b1 ,oTMEMDataRequest , ReadInProgress_Delay );

assign wExeDone = (ReadInProgress_Delay) ? iTMEMDataAvailable : wExeDone_pre3;
assign wCommitGranted = (ReadInProgress_Delay) ? wExeDone : wExeDone_pre4;
//assign wCommitGranted = wExeDone;

endmodule
