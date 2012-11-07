`timescale 1ns / 1ps
`include "aDefinitions.v"
/**********************************************************************************
Theia, Ray Cast Programable graphic Processing Unit.
Copyright (C) 2010  Diego Valverde (diego.valverde.g@gmail.com)

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
//--------------------------------------------------------

`define MCU_STATE_AFTER_RESET           0
`define MCU_WAIT_FOR_REQUEST            1
`define MCU_TRANSFER_BLOCK_TO_VPCODEMEM 2
`define MCU_TRANSFER_BLOCK_TO_VPDATAMEM 3
`define MCU_INC_TRANSFER_BLOCK_ADDR     4

module MemoryController # (parameter CORE_COUNT=`MAX_CORES )
(
		
		input wire                                          Clock, 
		input wire                                          Reset, 
		input wire [`MCU_REQUEST_SIZE-1:0]                  iRequest,
		
		output wire                                         oMEM_ReadRequest,
		output wire [`WB_WIDTH-1:0]                         oMEM_ReadAddress, 
		input wire [`WB_WIDTH-1:0]                          iMEM_ReadData,		//Data read from Main memory
		output wire                                         oPendingRequests, 	//Connected to FIFO
		output wire                                         oFifoFull,
		output wire                                         oFifoEmpty,
		input wire                                          iMEM_DataAvailable,
		//Wishbone signals
		output wire [`WB_WIDTH-1:0]                         DAT_O,
		output wire [`WB_WIDTH-1:0]                         ADR_O,
		output wire                                         STB_O,
		output wire [CORE_COUNT-1:0]                        WE_O,
		output reg [1:0]                                    TAG_O,
		output reg                                          CYC_O,
		output reg                                          MST_O,
		input wire                                          ACK_I
		
);


reg                               rPopFifo;
wire [`MCU_REQUEST_SIZE-1:0]      wCurrentRequest;
wire                              wMEM_DataAvailable;
reg                               rIncrementAddress;
wire [10:0]                       wCycCount;
reg                               rResetCycCount;
reg                               rMEM_ReadRequest;
wire                              w64BisTransmitted,w96BisTransmitted;
wire                              wRequestDetected;
wire[2:0]                         wStbCount;
reg                               rResetStbCount;
wire                              wLastBlock;
wire                              wRequestType;
wire                              wStall;				//If ACK is not received afte STB_O wait for ACK

assign DAT_O             = iMEM_ReadData;
assign wRequestDetected  = (iRequest[`MCU_COPYMEMBLOCKCMD_VPMASK_RNG] != 0) ? 1'b1 : 1'b0;
assign oMEM_ReadRequest  = rMEM_ReadRequest & ~iMEM_DataAvailable ;


//assign STB_O             = wMEM_DataAvailable;


wire wSTB_O;
UPCOUNTER_POSEDGE # (1) STB_O_UP
(
.Clock(      Clock                                            ), 
.Reset(      Reset | wRequestDetected                         ),
.Initial(    1'b0                                             ),
.Enable(     wMEM_DataAvailable | ACK_I                       ),
.Q(          wSTB_O                                           )
);

assign STB_O =  (wSTB_O );//| wMEM_DataAvailable);// & ~ACK_I;

assign w64BisTransmitted = (wStbCount == 3'd2) ? 1'b1 : 1'b0;
assign w96BisTransmitted = (wStbCount == 3'd3) ? 1'b1 : 1'b0;
assign wLastBlock        = (wCycCount == wCurrentRequest[`MCU_COPYMEMBLOCKCMD_BLKLEN_RNG]) ? 1'b1 : 1'b0;
assign wRequestType      = wCurrentRequest[`MCU_COPYMEMBLOCK_TAG_BIT];



UPCOUNTER_POSEDGE # (`WB_WIDTH) OUT_MEM_ADR_UP
(
.Clock(      Clock                                            ), 
.Reset(      Reset | wRequestDetected                         ),
.Initial(    iRequest[`MCU_COPYMEMBLOCKCMD_SRCOFF_RNG]        ),
.Enable(     ACK_I                                            ),
.Q(          oMEM_ReadAddress                                 )
);


//Incomming requests are stored in the FIFO
sync_fifo  # (`MCU_REQUEST_SIZE,`MCU_FIFO_DEPTH ) IN_FIFO
(
 .clk(    Clock              ),
 .reset(  Reset              ),
 .din(    iRequest           ),
 .wr_en(  wRequestDetected   ),
 .rd_en(  rPopFifo           ),
 .dout(   wCurrentRequest    ),
 .empty(  oFifoEmpty         ),
 .full(   oFifoFull          )
 
);



PULSE P1
(
.Clock( Clock               ),
.Reset( Reset               ),
.Enable( 1'b1               ),
.D(      iMEM_DataAvailable ),
.Q(      wMEM_DataAvailable )
);



UPCOUNTER_POSEDGE # (11) UP_CYC
(
.Clock(      Clock                                      ), 
.Reset(      Reset | rResetCycCount                     ),
.Initial(     11'b1                                      ),
.Enable(     rIncrementAddress                          ),
.Q(          wCycCount                                  )
);

wire wStbPulse;
PULSE P2
(
.Clock( Clock               ),
.Reset( Reset               ),
.Enable( 1'b1               ),
.D(      STB_O              ),
.Q(      wStbPulse          )
);


UPCOUNTER_POSEDGE # (3) UP_STB
(
.Clock(      Clock                                      ), 
.Reset(      Reset | rResetStbCount                     ),
.Initial(    3'b0                                       ),
.Enable(     wStbPulse                                  ),
.Q(          wStbCount                                  )
);

UPCOUNTER_POSEDGE # (`WB_WIDTH) UP_VPADDR
(
.Clock(      Clock                                             ), 
.Reset(      Reset |  wRequestDetected                         ),
.Initial(    {12'b0,iRequest[`MCU_COPYMEMBLOCKCMD_DSTOFF_RNG]} ),
.Enable(     rIncrementAddress                                 ),
.Q(          ADR_O                                             )
);

wire [`MCU_VPMASK_LEN-1:0] wWE_SelectMask;
assign wWE_SelectMask = wCurrentRequest[`MCU_COPYMEMBLOCKCMD_VPMASK_RNG];

SELECT_1_TO_N # ( $clog2(`MAX_CORES), `MAX_CORES ) WESEL
 (
 .Sel(wWE_SelectMask[$clog2(`MAX_CORES)-1:0]),
 .En( ~oFifoEmpty),
 .O(  WE_O )
 );


reg [4:0]  rCurrentState, rNextState;
//Next states logic and Reset sequence
always @(posedge Clock ) 
  begin 
			
    if (Reset )  
		rCurrentState <= `MCU_STATE_AFTER_RESET; 
    else        
		rCurrentState <= rNextState; 
		
end



always @ ( * )
begin
	case (rCurrentState)
	//--------------------------------------
	`MCU_STATE_AFTER_RESET:
	begin
		rPopFifo          = 1'b0;
		rIncrementAddress = 1'b0;
		TAG_O             = `TAG_NULL;
		MST_O             = 1'b0;
		CYC_O             = 1'b0;
		rResetCycCount    = 1'b1;
		rMEM_ReadRequest  = 1'b0;
		rResetStbCount    = 1'b0;
		
		rNextState = `MCU_WAIT_FOR_REQUEST;
	end
	//--------------------------------------
	/*
	Wait until a request becomes available
	*/
	`MCU_WAIT_FOR_REQUEST:
	begin
	   rPopFifo         = 1'b0;
	   rIncrementAddress = 1'b0;
	   TAG_O             = `TAG_NULL;
	   MST_O             = 1'b0;
	   CYC_O             = 1'b0;
	   rResetCycCount    = 1'b1;
		rMEM_ReadRequest  = 1'b0;
		rResetStbCount    = 1'b1;
	
	if (~oFifoEmpty && wRequestType == `MCU_COPYMEMBLOCKCMD_DSTTYPE_VPCODEMEM)
		rNextState = `MCU_TRANSFER_BLOCK_TO_VPCODEMEM;
	else if (~oFifoEmpty && wRequestType == `MCU_COPYMEMBLOCKCMD_DSTTYPE_VPDATAMEM)
		rNextState = `MCU_TRANSFER_BLOCK_TO_VPDATAMEM;
	else 	
		rNextState = `MCU_WAIT_FOR_REQUEST;
		
	end
	//--------------------------------------
	//Code MEM is 64 bits
	`MCU_TRANSFER_BLOCK_TO_VPCODEMEM:
	begin
		rPopFifo          = 1'b0;
		rIncrementAddress = 1'b0;
		TAG_O             = `TAG_INSTRUCTION_ADDRESS_TYPE;
		MST_O             = 1'b1;
		CYC_O             = 1'b1;
		rResetCycCount    = 1'b0;
		rMEM_ReadRequest  = ~w64BisTransmitted;
		rResetStbCount    = 1'b0;
		
		if (w64BisTransmitted)
			rNextState = `MCU_INC_TRANSFER_BLOCK_ADDR;
		else
			rNextState = `MCU_TRANSFER_BLOCK_TO_VPCODEMEM;
	end
	//--------------------------------------
	`MCU_TRANSFER_BLOCK_TO_VPDATAMEM:
	begin
		rPopFifo          = 1'b0;
		rIncrementAddress = 1'b0;
		TAG_O             = `TAG_INSTRUCTION_ADDRESS_TYPE;
		MST_O             = 1'b1;
		CYC_O             = 1'b1;
		rResetCycCount    = 1'b0;
		rMEM_ReadRequest  = ~w96BisTransmitted;
		rResetStbCount    = 1'b0;
		
		if (w96BisTransmitted)
			rNextState = `MCU_INC_TRANSFER_BLOCK_ADDR;
		else
			rNextState = `MCU_TRANSFER_BLOCK_TO_VPDATAMEM;
		
	end
	//--------------------------------------
	`MCU_INC_TRANSFER_BLOCK_ADDR:
	begin
		rPopFifo          = wLastBlock;
		rIncrementAddress = ~wLastBlock;
		TAG_O             = `TAG_NULL;
		MST_O             = 1'b1;
		CYC_O             = 1'b0;
		rResetCycCount    = 1'b0;
		rMEM_ReadRequest  = 1'b0;
		rResetStbCount    = 1'b1;
		
		if (wLastBlock)
			rNextState = `MCU_WAIT_FOR_REQUEST;
		else if (wRequestType == `MCU_COPYMEMBLOCKCMD_DSTTYPE_VPCODEMEM)
			rNextState = `MCU_TRANSFER_BLOCK_TO_VPCODEMEM;
		else if (wRequestType == `MCU_COPYMEMBLOCKCMD_DSTTYPE_VPDATAMEM)
			rNextState = `MCU_TRANSFER_BLOCK_TO_VPDATAMEM;
		else 
			rNextState = `MCU_WAIT_FOR_REQUEST; //Should never reach this!
	end
	//--------------------------------------
	default:
	begin
	   rPopFifo          = 1'b0;
	   rIncrementAddress = 1'b0;
		TAG_O             = `TAG_NULL;
		MST_O             = 1'b0;
		CYC_O             = 1'b0;
		rResetCycCount    = 1'b1;
		rMEM_ReadRequest  = 1'b0;
		rResetStbCount    = 1'b0;
	
	   rNextState = `MCU_STATE_AFTER_RESET;
	end
	//--------------------------------------
	endcase
end	


endmodule
