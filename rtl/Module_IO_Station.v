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
   output wire [`DATA_ROW_WIDTH-1:0]                         oOMEMWriteAddress,
   output wire [`DATA_ROW_WIDTH-1:0]                         oOMEMWriteData,
   output wire                                               oOMEMWriteEnable
	
);

wire                           wExeDone;
wire [2:0]                     wExeDoneTmp;
wire                           wRS_OMWRITE_Trigger;
wire [`DATA_ROW_WIDTH-1:0]     wRS1_OperandA;
wire [`DATA_ROW_WIDTH-1:0]     wRS1_OperandB;
wire [`DATA_ROW_WIDTH-1:0]     wResult;
wire                           wCommitGranted;

//ReservationStation_1Cycle RS
ReservationStation RS
(
	.Clock(              Clock                           ),
	.Reset(              Reset                           ),
	.iIssueBus(          iIssueBus                       ),
	.iCommitBus(         iCommitBus                      ),
	.iMyId(              iId                             ),
	.iExecutionDone(     wExeDone                        ),
	.iResult(            wResult                         ),
	.iCommitGranted(     wCommitGranted                  ),
	.oSrc1Latched(       wRS1_OperandB                   ),
	.oSrc0Latched(       wRS1_OperandA                   ),
	.oBusy(              oBusy                           ),
	.oTrigger(           wRS_OMWRITE_Trigger             )
	
	
);


assign oCommitResquest   = 1'b0;		                  //This is always zero since we are writting anything into the RF
assign oCommitData       = `COMMIT_PACKET_SIZE'd0;    //This is always zero since we are writting anything into the RF
assign oOMEMWriteData    = wRS1_OperandA;             //Write 96 bits to external memory OMEM
assign oOMEMWriteAddress = wRS1_OperandB;             //Each 32 bit words has the write address

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD0
( 	Clock, Reset, 1'b1 , wRS_OMWRITE_Trigger | wExeDone_pre1 | wExeDone_pre2, oOMEMWriteEnable );

//It takes 3 clock cycles to write the 96 bits into OMEM
wire wExeDone_pre1,wExeDone_pre2;
FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD1
( 	Clock, Reset, 1'b1 , wRS_OMWRITE_Trigger, wExeDone_pre1 );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD2
( 	Clock, Reset, 1'b1 , wExeDone_pre1, wExeDone_pre2 );

FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) DONE_FFD3
( 	Clock, Reset, 1'b1 , wExeDone_pre2, wExeDone );

assign wCommitGranted = wExeDone;

endmodule
