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


`define CONTROL_PROCESSOR_OP_WIDTH            5
`define CONTROL_PROCESSOR_ADDR_WIDTH          8
`define CONTROL_PROCESSOR_ISSUE_CMD_RNG       24:0
`define CONTROL_PROCESSOR_INSTRUCTION_WIDTH   32

`define CONTROL_PROCESSOR_INST_OP_RNG         31:24
`define CONTROL_PROCESSOR_INST_OP_DST_RNG     23:16
`define CONTROL_PROCESSOR_INST_OP_SRC1_RNG    15:8
`define CONTROL_PROCESSOR_INST_OP_SRC0_RNG    7:0


`define CONTROL_PROCESSOR_OP_NOP             `CONTROL_PROCESSOR_OP_WIDTH'd0
`define CONTROL_PROCESSOR_OP_DELIVER_COMMAND `CONTROL_PROCESSOR_OP_WIDTH'd1
`define CONTROL_PROCESSOR_OP_ADD             `CONTROL_PROCESSOR_OP_WIDTH'd2
`define CONTROL_PROCESSOR_OP_SUB             `CONTROL_PROCESSOR_OP_WIDTH'd3
`define CONTROL_PROCESSOR_OP_AND             `CONTROL_PROCESSOR_OP_WIDTH'd4
`define CONTROL_PROCESSOR_OP_OR              `CONTROL_PROCESSOR_OP_WIDTH'd5
`define CONTROL_PROCESSOR_OP_BRANCH          `CONTROL_PROCESSOR_OP_WIDTH'd6
`define CONTROL_PROCESSOR_OP_BEQ             `CONTROL_PROCESSOR_OP_WIDTH'd7
`define CONTROL_PROCESSOR_OP_BNE             `CONTROL_PROCESSOR_OP_WIDTH'd8
`define CONTROL_PROCESSOR_OP_BG              `CONTROL_PROCESSOR_OP_WIDTH'd9
`define CONTROL_PROCESSOR_OP_BL              `CONTROL_PROCESSOR_OP_WIDTH'd10
`define CONTROL_PROCESSOR_OP_BGE             `CONTROL_PROCESSOR_OP_WIDTH'd11
`define CONTROL_PROCESSOR_OP_BLE             `CONTROL_PROCESSOR_OP_WIDTH'd12
`define CONTROL_PROCESSOR_ASSIGN             `CONTROL_PROCESSOR_OP_WIDTH'd13
`define CONTROL_PROCESSOR_OP_COPYBLOCK       `CONTROL_PROCESSOR_OP_WIDTH'd14
`define CONTROL_PROCESSOR_OP_EXIT            `CONTROL_PROCESSOR_OP_WIDTH'd15
`define CONTROL_PROCESSOR_OP_NOT             `CONTROL_PROCESSOR_OP_WIDTH'd16
`define CONTROL_PROCESSOR_OP_SHL             `CONTROL_PROCESSOR_OP_WIDTH'd17
`define CONTROL_PROCESSOR_OP_SHR             `CONTROL_PROCESSOR_OP_WIDTH'd18


module ControlProcessor
(
input wire                              Clock,
input wire                              Reset,
output wire[`CBC_BUS_WIDTH-1:0]         oControlBus,
input wire                              iMCUFifoEmpty,
output reg [`MCU_REQUEST_SIZE-1:0]      oCopyBlockCommand
);



wire [`CONTROL_PROCESSOR_ADDR_WIDTH-1:0]                     wIP,wIP_temp;
reg                                                          rWriteEnable,rBranchTaken;
reg  [`CBC_BUS_WIDTH-1:0]                                    rIssueCommand;
wire [`CONTROL_PROCESSOR_INSTRUCTION_WIDTH-1:0]              wInstruction;
wire [`CONTROL_PROCESSOR_OP_WIDTH-1:0]                       wOperation;
reg  [`WIDTH-1:0]                                            rResult;
wire [`WIDTH-1:0]                                            wPrevResult;
wire [`CONTROL_PROCESSOR_ADDR_WIDTH-1:0]                     wSourceAddr0,wSourceAddr1,wDestination,wPrevDestination;
wire [`WIDTH-1:0]                                            wSourceData0,wSourceData1,wIPInitialValue,wImmediateValue;


assign oControlBus = rIssueCommand;

RAM_SINGLE_READ_PORT # (`CONTROL_PROCESSOR_INSTRUCTION_WIDTH, `CONTROL_PROCESSOR_ADDR_WIDTH, 256) InstructionRam 
(
	.Clock(         Clock       ),
	.iWriteEnable(  1'b0        ),
	.iReadAddress0(     wIP     ),
	.oDataOut0( wInstruction    )
);


wire [`WIDTH-1:0]  wSourceData0_FromMem,wSourceData1_FromMem,wSourceData0_FromMem_Pre,wSourceData1_FromMem_Pre;
RAM_DUAL_READ_PORT # (`WIDTH,`CONTROL_PROCESSOR_ADDR_WIDTH) DataRam
(
	.Clock(         Clock        ),
	.iWriteEnable(  rWriteEnable ),
	.iReadAddress0( wInstruction[`CONTROL_PROCESSOR_INST_OP_SRC0_RNG] ),
	.iReadAddress1( wInstruction[`CONTROL_PROCESSOR_INST_OP_SRC1_RNG] ),
	.iWriteAddress( wDestination ),
	.iDataIn(       rResult      ),
	.oDataOut0(     wSourceData0_FromMem_Pre ),
	.oDataOut1(     wSourceData1_FromMem_Pre )
);

wire [`WIDTH-1:0]  wSprBlockDestination;
FFD_POSEDGE_SYNCRONOUS_RESET # (`WIDTH ) FFD_SPR_COREID
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(rWriteEnable && (wDestination == `CONTROL_PROCESSOR_REG_BLOCK_DST)),
	.D(rResult),
	.Q(wSprBlockDestination)
);

assign wSourceData0_FromMem  = (wSourceAddr0 == `CONTROL_PROCESSOR_REG_STATUS) ? { 30'b0,iMCUFifoEmpty} : wSourceData0_FromMem_Pre;
assign wSourceData1_FromMem  = (wSourceAddr1 == `CONTROL_PROCESSOR_REG_STATUS) ? { 30'b0,iMCUFifoEmpty} :wSourceData1_FromMem_Pre;
 
assign wSourceData0 = ( wSourceAddr0 == wPrevDestination ) ? wPrevResult : wSourceData0_FromMem ;
assign wSourceData1 = ( wSourceAddr1 == wPrevDestination) ? wPrevResult : wSourceData1_FromMem ;

assign wIPInitialValue = (Reset) ? `CONTROL_PROCESSOR_ADDR_WIDTH'b0 : wDestination;
UPCOUNTER_POSEDGE # (`CONTROL_PROCESSOR_ADDR_WIDTH) IP
(
.Clock(   Clock                ), 
.Reset(   Reset | rBranchTaken ),
.Initial( wIPInitialValue + 1  ),
.Enable(  1'b1                 ),
.Q(       wIP_temp             )
);
assign wIP = (rBranchTaken) ? wIPInitialValue : wIP_temp;



FFD_POSEDGE_SYNCRONOUS_RESET # ( `CONTROL_PROCESSOR_OP_WIDTH ) FFD1 
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wInstruction[`CONTROL_PROCESSOR_INST_OP_RNG]),
	.Q(wOperation)
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `WIDTH ) FFD2 
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(rResult),
	.Q(wPrevResult)
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `CONTROL_PROCESSOR_ADDR_WIDTH ) FFD255
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wInstruction[`CONTROL_PROCESSOR_INST_OP_SRC0_RNG]),
	.Q(wSourceAddr0)
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `CONTROL_PROCESSOR_ADDR_WIDTH ) FFD3
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wInstruction[`CONTROL_PROCESSOR_INST_OP_SRC1_RNG]),
	.Q(wSourceAddr1)
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `CONTROL_PROCESSOR_ADDR_WIDTH ) FFD4
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wInstruction[`CONTROL_PROCESSOR_INST_OP_DST_RNG]),
	.Q(wDestination)
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `CONTROL_PROCESSOR_ADDR_WIDTH ) FFD44
(
	.Clock(Clock),
	.Reset(Reset),
	.Enable(1'b1),
	.D(wDestination),
	.Q(wPrevDestination)
);


assign wImmediateValue = {wSourceAddr1,wSourceAddr0};



always @ ( * )
begin
	case (wOperation)
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_COPYBLOCK:
	begin
	
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		oCopyBlockCommand = 
		{wSprBlockDestination[15:0],wSourceData1,wSourceData0[`MCU_COPYMEMBLOCK_TAG_BIT],wSourceData0[`MCU_COPYMEMBLOCKCMD_BLKLEN_RNG],wSourceData0[`MCU_COPYMEMBLOCKCMD_DSTOFF_RNG]};
		rWriteEnable = 1'b0;
		rResult      = 0;
		rBranchTaken = 1'b0;
		
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_DELIVER_COMMAND:
	begin
	   oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
	   rIssueCommand = {wDestination[7:0],wSourceData1[7:0],wSourceData0[15:0]};
		rWriteEnable = 1'b0;
		rResult      = 0;
		rBranchTaken = 1'b0;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_NOP:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
	   rIssueCommand = `CBC_BUS_WIDTH'b0;
		rBranchTaken = 1'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_ADD:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rBranchTaken = 1'b0;
		rWriteEnable = 1'b1;
		rResult      = wSourceData1 + wSourceData0;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_SUB:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rBranchTaken = 1'b0;
		rWriteEnable = 1'b1;
		rResult      = wSourceData1 - wSourceData0;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_AND:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rBranchTaken = 1'b0;
		rWriteEnable = 1'b1;
		rResult      = wSourceData1 & wSourceData0;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_SHL:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rBranchTaken = 1'b0;
		rWriteEnable = 1'b1;
		rResult      = wSourceData1 << wSourceData0;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_SHR:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rBranchTaken = 1'b0;
		rWriteEnable = 1'b1;
		rResult      = wSourceData1 >> wSourceData0;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_OR:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rBranchTaken = 1'b0;
		rWriteEnable = 1'b1;
		rResult      = wSourceData1 | wSourceData0;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_BLE:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
		if (wSourceData1 <= wSourceData0 )
			rBranchTaken = 1'b1;
		else
			rBranchTaken = 1'b0;
		
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_BL:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
		if (wSourceData1 < wSourceData0 )
			rBranchTaken = 1'b1;
		else
			rBranchTaken = 1'b0;
		
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_BG:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
		if (wSourceData1 > wSourceData0 )
			rBranchTaken = 1'b1;
		else
			rBranchTaken = 1'b0;
		
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_BGE:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
		if (wSourceData1 >= wSourceData0 )
			rBranchTaken = 1'b1;
		else
			rBranchTaken = 1'b0;
		
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_BEQ:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
		if (wSourceData1 == wSourceData0 )
			rBranchTaken = 1'b1;
		else
			rBranchTaken = 1'b0;
		
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_OP_BNE:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
		if (wSourceData1 != wSourceData0 )
			rBranchTaken = 1'b1;
		else
			rBranchTaken = 1'b0;
		
	end
	//-------------------------------------	
	`CONTROL_PROCESSOR_OP_BRANCH:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
		rBranchTaken = 1'b1;
	end
	//-------------------------------------
	`CONTROL_PROCESSOR_ASSIGN:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
		rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b1;
		rResult      = wImmediateValue;
		rBranchTaken = 1'b0;
		
	end
	//-------------------------------------
	default:
	begin
		oCopyBlockCommand = `MCU_REQUEST_SIZE'b0;
	   rIssueCommand = `CBC_BUS_WIDTH'b0;
		rWriteEnable = 1'b0;
		rResult      = 0;
		rBranchTaken = 1'b0;
	end	
	//-------------------------------------	
	endcase	
end





endmodule
