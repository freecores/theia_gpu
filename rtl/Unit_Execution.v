
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
input wire                               Clock,
input wire                               Reset,
input wire                               iEnable,
input wire [`INSTRUCTION_ADDR_WIDTH-1:0] iInstructionMem_WriteAddress,
input wire                               iInstructionMem_WriteEnable,
input wire [`INSTRUCTION_WIDTH-1:0]      iInstructionMem_WriteData,
//OMEM
output wire [`DATA_ROW_WIDTH-1:0]        oOMEMWriteAddress,
output wire [`DATA_ROW_WIDTH-1:0]        oOMEMWriteData,
output wire                              oOMEMWriteEnable,
//TMEM
output wire [`DATA_ROW_WIDTH-1:0]      oTMEMReadAddress,
input wire [`DATA_ROW_WIDTH-1:0]       iTMEMReadData,
input wire                             iTMEMDataAvailable,
output wire                            oTMEMDataRequest
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
wire [`ISSUE_PACKET_SIZE-1:0]                        wIssueBus;
wire [`MOD_ISSUE_PACKET_SIZE-1:0]                    wModIssue;
wire [`NUMBER_OF_RSVR_STATIONS-1:0]                  wStationCommitRequest;
wire [`NUMBER_OF_RSVR_STATIONS-1:0]                  wStationCommitGrant;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitBus;
wire [`MOD_COMMIT_PACKET_SIZE-1:0]                   wModCommitBus;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Adder0;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Adder1;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Div;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Mul;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Sqrt;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_Logic;
wire [`COMMIT_PACKET_SIZE-1:0]                       wCommitData_IO;
wire                                                 wZeroFlag;
wire                                                 wSignFlag;
wire [`DATA_ADDRESS_WIDTH-1:0]                       wFrameOffset,wIndexRegister;
wire [`WIDTH-1:0]                                    wThreadControl;

// The Register File
RegisterFile # ( `DATA_ROW_WIDTH,`DATA_ADDRESS_WIDTH ) RF
(
 .Clock(                  Clock                            ),
 .Reset(                  Reset                            ),
 .iWriteEnable(           wCommitBus[`COMMIT_WE_RNG]       ),
 .iReadAddress0(          wII_2_RF_Addr0                   ),
 .iReadAddress1(          wII_2_RF_Addr1                   ),
 .iWriteAddress(          wCommitBus[`COMMIT_DST_RNG]      ),
 .oFrameOffset(           wFrameOffset                     ),
 .oIndexRegister(         wIndexRegister                   ),
 .oThreadControlRegister( wThreadControl                   ),
 .iData(                  wCommitBus[`COMMIT_DATA_RNG]     ),
 .oData0(                 wRF_2_II_Data0                   ),
 .oData1(                 wRF_2_II_Data1                   )
);




//Code bank 0
RAM_DUAL_READ_PORT  # (`INSTRUCTION_WIDTH, `INSTRUCTION_ADDR_WIDTH) IM 
(
 .Clock(            Clock                              ),
 .iWriteEnable(      iInstructionMem_WriteEnable       ),
 .iReadAddress0(    wII0_IP0                           ),
 .iReadAddress1(    wII1_IP0                           ),
 .iWriteAddress(    iInstructionMem_WriteAddress       ),
 .iDataIn(          iInstructionMem_WriteData          ),
 .oDataOut0(        wInstrThread0                      ),
 .oDataOut1(        wInstrThread1                      )
);


//**********************************************
parameter MaxThreads = 3;
wire [MaxThreads-1:0] wDelay;


UPCOUNTER_POSEDGE # (MaxThreads) UP111
(
.Clock( Clock), .Reset( Reset),
.Initial(0),
.Enable(1'b1),
.Q(wDelay)
);

wire [`INSTRUCTION_ADDR_WIDTH -1:0]    wII0_IP0,wII0_IP1;
wire [`INSTRUCTION_ADDR_WIDTH -1:0]    wII1_IP0,wII1_IP1;
wire [`DATA_ADDRESS_WIDTH-1:0]     		wII0_RF_Addr0,wII0_RF_Addr1;
wire [`DATA_ADDRESS_WIDTH-1:0]     		wII1_RF_Addr0,wII1_RF_Addr1;
wire [`ISSUE_PACKET_SIZE-1:0]          wII0_IBus,wII1_IBus;


assign wII_2_RF_Addr0 = (wCurrentActiveThread[0]) ? wII0_RF_Addr0 : wII1_RF_Addr0;

assign wII_2_RF_Addr1 = (wCurrentActiveThread[0]) ? wII0_RF_Addr1 : wII1_RF_Addr1;

assign wIssueBus = (wCurrentActiveThread[0]) ? wII0_IBus: wII1_IBus;


wire [`MAX_THREADS-1:0] wCurrentActiveThread,wCurrentActiveThread_Pre,wCurrentActiveThread_Pre2;

CIRCULAR_SHIFTLEFT_POSEDGE_EX # ( `MAX_THREADS ) THREAD_SELECT
(
  .Clock( Clock ), 
  .Reset( Reset ),
  .Initial(`MAX_THREADS'b1), 
  .Enable( wDelay[0] /*& wDelay[1]*/ & wThreadControl[`SPR_TCONTROL0_MT_ENABLED]),
  .O( wCurrentActiveThread_Pre )
  );

FFD_POSEDGE_SYNCRONOUS_RESET # ( `MAX_THREADS ) FFD12
( 	Clock, Reset, 1'b1 , wCurrentActiveThread_Pre , wCurrentActiveThread_Pre2  );

assign wCurrentActiveThread = (wThreadControl[`SPR_TCONTROL0_MT_ENABLED]) ? wCurrentActiveThread_Pre2 : `MAX_THREADS'b1;


//**********************************************
wire [`INSTRUCTION_WIDTH-1:0] wInstrThread0;
//When the thread is inactive I want to keep this input just the way it was,
//sort of "time freezing"...



InstructionIssue II0
(
   .Clock(                Clock                   ),
	.Reset(                Reset                   ),
	.iEnable(             wCurrentActiveThread[0] &  iEnable),
	.iFrameOffset(         wFrameOffset            ),
	/* New Apr 06*/.iCodeOffset(   `INSTRUCTION_ADDR_WIDTH'b0     ),
	.iMtEnabled(wThreadControl[`SPR_TCONTROL0_MT_ENABLED]),
	.iIndexRegister(       wIndexRegister          ),
	.iInstruction0(        wInstrThread0           ),
//	.iInstruction1(        wIM_2_II_Instruction1   ),
	.iSourceData0(         wRF_2_II_Data0          ),
	.iSourceData1(         wRF_2_II_Data1          ),
	.iRStationBusy(        wRS_2_II_Busy           ),    
	.iResultBcast(         wCommitBus              ),         
	.iSignFlag(            wSignFlag               ),
	.iZeroFlag(            wZeroFlag               ),
	.iIgnoreResultBcast(   wResultBCastDst[7] &  wThreadControl[`SPR_TCONTROL0_MT_ENABLED] ),
	.oSourceAddress0(      wII0_RF_Addr0           ),//wII_2_RF_Addr0        ),
	.oSourceAddress1(      wII0_RF_Addr1           ),//wII_2_RF_Addr1        ),
	.oIssueBcast(          wII0_IBus               ),//wIssueBus             ), 
	.oIP0(                 wII0_IP0                )//wII_2_IM_IP0          ),
	//.oIP1(                 wII0_IP1                )//wII_2_IM_IP1          )
	
);



wire [`INSTRUCTION_WIDTH-1:0] wInstrThread1;
//When the thread is inactive I want to keep this input just the way it was,
//sort of "time freezing"...

//Add the offset to the thread instructions... 1 16 bit adder wasted :(
//assign wInstrThread1 = wInstrThread1_Pre;

wire [`DATA_ADDRESS_WIDTH-1:0] wResultBCastDst;
assign wResultBCastDst = wCommitBus[`COMMIT_DST_RNG];


InstructionIssue II1
(
   .Clock(                Clock                                                       ),
	.Reset(                Reset  ||  ~wThreadControl[`SPR_TCONTROL0_MT_ENABLED]       ),
	.iEnable(              wCurrentActiveThread[1]    & iEnable                        ),
	.iFrameOffset(         wFrameOffset                                                ),
	 .iCodeOffset(         wThreadControl[`SPR_TCONTROL0_T0_INST_OFFSET_RNG]           ),       
	.iMtEnabled(           wThreadControl[`SPR_TCONTROL0_MT_ENABLED]                   ),
	.iIndexRegister(       wIndexRegister        ),
	.iInstruction0(        wInstrThread1         ),
	.iSourceData0(         wRF_2_II_Data0        ),
	.iSourceData1(         wRF_2_II_Data1        ),
	.iRStationBusy(        wRS_2_II_Busy         ),    
	.iResultBcast(         wCommitBus            ),         
	.iSignFlag(            wSignFlag             ),
	.iZeroFlag(            wZeroFlag             ),
	
	.iIgnoreResultBcast(   ~wResultBCastDst[7]   ),
	.oSourceAddress0(      wII1_RF_Addr0 ),
	.oSourceAddress1(      wII1_RF_Addr1 ),
	.oIssueBcast(          wII1_IBus ),
	.oIP0(                 wII1_IP0 )
	//.oIP1(                 wII1_IP1 )
	
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
   .Clock(               Clock                       ),
	.Reset(               Reset                       ),
	.iId(                 `RS_ADD0                    ),
   .iIssueBus(           wModIssue                   ),
   .iCommitBus(          wModCommitBus               ),
	.oCommitData(         wCommitData_Adder0          ),
	.oCommitResquest(     wStationCommitRequest[0]    ),
	.iCommitGranted(      wStationCommitGrant[0]      ),
	.oBusy(               wRS_2_II_Busy[ 0 ]          )
	
);

ADDER_STATION ADD_STA1
(
   .Clock(               Clock                        ),
	.Reset(               Reset                        ),
	.iId(                 `RS_ADD1                     ),
   .iIssueBus(           wModIssue                    ),
   .iCommitBus(          wModCommitBus                ),
	.oCommitData(         wCommitData_Adder1           ),
	.oCommitResquest(     wStationCommitRequest[1]     ),
	.iCommitGranted(      wStationCommitGrant[1]       ),
	.oBusy(               wRS_2_II_Busy[ 1 ]           )
	
);


DIVISION_STATION DIV_STA
(
   .Clock(               Clock                       ),
	.Reset(               Reset                       ),
	.iId(                 `RS_DIV                     ),
   .iIssueBus(           wModIssue                   ),
   .iCommitBus(          wModCommitBus               ),
	.oCommitData(         wCommitData_Div             ),
	.oCommitResquest(     wStationCommitRequest[2]    ),
	.iCommitGranted(      wStationCommitGrant[2]      ),
	.oBusy(               wRS_2_II_Busy[2]            )
	
);


MUL_STATION MUL_STA
(
   .Clock(               Clock                       ),
	.Reset(               Reset                       ),
	.iId(                 `RS_MUL                     ),
   .iIssueBus(           wModIssue                   ),
   .iCommitBus(          wModCommitBus               ),
	.oCommitData(         wCommitData_Mul             ),
	.oCommitResquest(     wStationCommitRequest[3]    ),
	.iCommitGranted(      wStationCommitGrant[3]      ),
	.oBusy(               wRS_2_II_Busy[3]            )
	
);


SQRT_STATION SQRT_STA
(
   .Clock(               Clock                    ),
	.Reset(               Reset                    ),
	.iId(                 `RS_SQRT                 ),
   .iIssueBus(           wModIssue                ),
   .iCommitBus(          wModCommitBus            ),
	.oCommitData(         wCommitData_Sqrt         ),
	.oCommitResquest(     wStationCommitRequest[4] ),
	.iCommitGranted(      wStationCommitGrant[4]   ),
	.oBusy(               wRS_2_II_Busy[4]         )
	
);



LOGIC_STATION LOGIC_STA
(
   .Clock(               Clock                    ),
	.Reset(               Reset                    ),
	.iId(                 `RS_LOGIC                ),
   .iIssueBus(           wModIssue                ),
   .iCommitBus(          wModCommitBus            ),
	.oCommitData(         wCommitData_Logic        ),
	.oCommitResquest(     wStationCommitRequest[5] ),
	.iCommitGranted(      wStationCommitGrant[5]   ),
	.oBusy(               wRS_2_II_Busy[5]         )
	
);

IO_STATION IO_STA
(
   .Clock(               Clock                    ),
	.Reset(               Reset                    ),
	.iId(                 `RS_IO                  ),
   .iIssueBus(           wModIssue                ),
   .iCommitBus(          wModCommitBus            ),
	.oCommitData(         wCommitData_IO           ),
	.oCommitResquest(     wStationCommitRequest[6] ),
	.iCommitGranted(      wStationCommitGrant[6]   ),
	.oBusy(               wRS_2_II_Busy[6]         ),
	//OMEM
	.oOMEMWriteAddress(   oOMEMWriteAddress        ),
   .oOMEMWriteData(      oOMEMWriteData           ),
   .oOMEMWriteEnable(    oOMEMWriteEnable         ),
	//TMEM
	.oTMEMReadAddress(    oTMEMReadAddress         ),
   .iTMEMReadData(       iTMEMReadData            ),
   .iTMEMDataAvailable(  iTMEMDataAvailable       ),
   .oTMEMDataRequest(    oTMEMDataRequest         )
	
);

ROUND_ROBIN_7_ENTRIES ARB
//ROUND_ROBIN_6_ENTRIES ARB
(
.Clock( Clock ),
.Reset( Reset ),
.iRequest0( wStationCommitRequest[0] ),
.iRequest1( wStationCommitRequest[1] ),
.iRequest2( wStationCommitRequest[2] ),
.iRequest3( wStationCommitRequest[3] ),
.iRequest4( wStationCommitRequest[4] ),
.iRequest5( wStationCommitRequest[5] ),
.iRequest6( wStationCommitRequest[6] ),
.oGrant0(    wStationCommitGrant[0]   ),
.oGrant1(    wStationCommitGrant[1]   ),
.oGrant2(    wStationCommitGrant[2]   ),
.oGrant3(    wStationCommitGrant[3]   ),
.oGrant4(    wStationCommitGrant[4]   ),
.oGrant5(    wStationCommitGrant[5]   ),
.oGrant6(    wStationCommitGrant[6]   )

);

wire [5:0] wBusSelector_Tmp;
wire[2:0] wBusSelector;
DECODER_ONEHOT_2_BINARY DECODER
(
.iIn( wStationCommitGrant ),
.oOut(  wBusSelector_Tmp    )
);
assign wBusSelector = wBusSelector_Tmp[3:0];

MUXFULLPARALELL_3SEL_GENERIC # (`COMMIT_PACKET_SIZE ) MUX		//TODO I need one more entry for the IO
 (
 .Sel(wBusSelector),
 .I1(`COMMIT_PACKET_SIZE'b0), 
 .I2(wCommitData_Adder0),
 .I3(wCommitData_Adder1),
 .I4(wCommitData_Div),
 .I5(wCommitData_Mul),
 .I6(wCommitData_Sqrt),
 .I7(wCommitData_Logic),
 .I8(wCommitData_IO        ),
 .O1(wCommitBus)
 );
 

endmodule
