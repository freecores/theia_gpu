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

`define IFU_AFTER_RESET 			0
`define IFU_INITIAL_STATE					1
`define IFU_WAIT_FOR_LAST_INSTRUCTION_LATCHED_BY_IDU						2
`define IFU_STALLED		3
`define IFU_FETCH_NEXT				4
`define FU_WAIT_FOR_EXE_UNIT		5
`define IFU_DONE						6
`define IFU_CHECK_FOR_JUMP_PENDING			7


`define IP_SET_VALUE_INITIAL_ADDRESS 0
`define IP_SET_VALUE_BRANCH_ADDRESS 1

//-----------------------------------------------------------------------------
module InstructionFetchUnit
(
	input wire										Clock,
	input wire										Reset,
	input	wire										iBranchTaken,
	input wire										iBranchNotTaken,
	input wire[`ROM_ADDRESS_WIDTH-1:0]		iJumpIp,
	input	wire										iTrigger,
	input	wire										iIDUBusy,
	input	wire										iExeBusy,
	input wire[`INSTRUCTION_WIDTH-1:0]		iEncodedInstruction,
	input wire[`ROM_ADDRESS_WIDTH-1:0]		iInitialCodeAddress,
	input wire										iDecodeUnitLatchedValues,
	output reg										oExecutionDone,
	output wire										oMicroCodeReturnValue,
	output wire										oInstructionAvalable,
	output wire [`ROM_ADDRESS_WIDTH-1:0]	oInstructionPointer,
	output wire[`INSTRUCTION_WIDTH-1:0]		oCurrentInstruction
	
	
);

//Alling the Jump Signal to the negedge of Clock,
//I do this because I finded out the simulator
//behaves funny if you change a value at the edge
//of the clock and read from a bus that has changed
wire rJumpNow;

assign oCurrentInstruction = iEncodedInstruction;

assign oMicroCodeReturnValue = iEncodedInstruction[0];

wire [`ROM_ADDRESS_WIDTH-1:0] wInstructionPointer;
reg rEnable;

assign oInstructionPointer = wInstructionPointer; 

reg rPreviousInstructionIsJump;

`define INSTRUCTION_OPCODE iEncodedInstruction[`INSTRUCTION_WIDTH-1:`INSTRUCTION_WIDTH-`INSTRUCTION_OP_LENGTH]

wire wLastInstruction;
assign wLastInstruction = 
(`INSTRUCTION_OPCODE == 0) ? 1'b1 : 1'b0;

wire rInstructionAvalable;
assign rInstructionAvalable = (iTrigger || iDecodeUnitLatchedValues) && rEnable;


//if it is jump delay 1 cycle
wire wInstructionAvalableDelayed_1Cycle;
wire wInstructionAvalableDelayed_2Cycle;
wire wInstructionAvalableDelayed_3Cycle;
wire wInstructionAvalableDelayed_4Cycle;
wire wJumpNow_Delayed_1Cycle,wJumpNow_Delayed_2Cycle,wJumpNow_Delayed_3Cycle;


FFD_POSEDGE_ASYNC_RESET # ( 1 ) FFDelayJump
(
	.Clock( Clock ),
	.Clear( Reset ),
	.D( rJumpNow ),
	.Q( wJumpNow_Delayed_1Cycle )
);
	
FFD_POSEDGE_ASYNC_RESET # ( 1 ) FFDelayJump2
(
	.Clock( Clock ),
	.Clear( Reset ),
	.D( wJumpNow_Delayed_1Cycle ),
	.Q( wJumpNow_Delayed_2Cycle )
);


FFD_POSEDGE_ASYNC_RESET # ( 1 ) FFDelayJump3
(
	.Clock( Clock ),
	.Clear( Reset ),
	.D( wJumpNow_Delayed_2Cycle ),
	.Q( wJumpNow_Delayed_3Cycle )
);



FFD_POSEDGE_ASYNC_RESET # ( 1 ) FFDelay1
(
	.Clock( Clock ),
	.Clear( Reset ),
	.D( rInstructionAvalable ),
	.Q( wInstructionAvalableDelayed_1Cycle )
);



FFD_POSEDGE_ASYNC_RESET # ( 1 ) FFDelay2
(
	.Clock( Clock ),
	.Clear( Reset ),
	.D( wInstructionAvalableDelayed_1Cycle ),
	.Q( wInstructionAvalableDelayed_2Cycle )
);



FFD_POSEDGE_ASYNC_RESET # ( 1 ) FFDelay3
(
	.Clock( Clock ),
	.Clear( Reset ),
	.D( wInstructionAvalableDelayed_2Cycle ),
	.Q( wInstructionAvalableDelayed_3Cycle )
);


FFD_POSEDGE_ASYNC_RESET # ( 1 ) FFDelay4A
(
	.Clock( Clock ),
	.Clear( Reset ),
	.D( wInstructionAvalableDelayed_3Cycle ),
	.Q( wInstructionAvalableDelayed_4Cycle )
);


assign oInstructionAvalable = (wInstructionAvalableDelayed_1Cycle && !rJumpNow) || 
								(wInstructionAvalableDelayed_3Cycle && wJumpNow_Delayed_2Cycle);

wire wInstructionAvalableDelayed;

FFD_POSEDGE_ASYNC_RESET # ( 1 ) FFDelay4
(
	.Clock( Clock ),
	.Clear( Reset ),
	.D( oInstructionAvalable ),
	.Q( wInstructionAvalableDelayed )
);


//----------------------------------------------
assign rJumpNow = iBranchTaken && !iBranchNotTaken;
//This sucks, should be improved

wire JumpInstructinDetected;
assign JumpInstructinDetected = 
	(
	 `INSTRUCTION_OPCODE == `JGEX || `INSTRUCTION_OPCODE == `JLEX || 
	 `INSTRUCTION_OPCODE == `JGEY || `INSTRUCTION_OPCODE == `JLEY || 
	 `INSTRUCTION_OPCODE == `JGEZ || `INSTRUCTION_OPCODE == `JLEZ ||
	 `INSTRUCTION_OPCODE == `JEQX || `INSTRUCTION_OPCODE == `JNEX ||
	 `INSTRUCTION_OPCODE == `JEQY || `INSTRUCTION_OPCODE == `JNEY ||
	 `INSTRUCTION_OPCODE == `JEQZ || `INSTRUCTION_OPCODE == `JNEZ
	 ) ; 


//Stall logic. 
//it basically tells IFU to stall on Branches. 
//The Stall begins when a Branch instruction
//is detected, the Stall ends when EXE tells us it made
//a branch taken or branch not taken decision

wire wStall;
assign wStall = JumpInstructinDetected && !iBranchTaken && !iBranchNotTaken;

//Increment the IP everytime IDU tells us it has Latched the previous I we gave him,
//except when we reached the last instruction in the flow, or we are in a Stall

wire wIncrementInstructionPointer;
assign wIncrementInstructionPointer = (wStall || wLastInstruction) ?  1'b0 : iDecodeUnitLatchedValues; 


//-------------------------------------------------
wire wIP_AlternateValue;
wire wIP_SetValueSelector;
wire [`ROM_ADDRESS_WIDTH-1:0] wInstructionPointerAlternateValue;

MUXFULLPARALELL_16bits_2SEL InstructionPointerSetValueMUX
 (
  .Sel( wIP_SetValueSelector ),
  .I1( iInitialCodeAddress    ),
  .I2(  iJumpIp ),
  .O1( wInstructionPointerAlternateValue )
 );

reg rIpControl;
MUXFULLPARALELL_1Bit_1SEL InstructionPointerControlMUX
 (
  .Sel( rIpControl ),
  .I1(  1'b0   ),
  .I2(  iBranchTaken  ),
  .O1( wIP_SetValueSelector )
 );
 


UPCOUNTER_POSEDGE # (16) InstructionPointer
(
	.Clock(wIncrementInstructionPointer || wJumpNow_Delayed_1Cycle || iTrigger), 
	.Reset(iTrigger ||  wJumpNow_Delayed_1Cycle ),
	.Enable(1'b1),
	.Initial(wInstructionPointerAlternateValue),
	.Q(wInstructionPointer)
);


reg	[5:0]	CurrentState, 	NextState;

//------------------------------------------------
always @(posedge Clock or posedge Reset) 
begin 
  		
		 
    if (Reset)  
		CurrentState <= `IFU_AFTER_RESET; 
    else        
		CurrentState <= NextState; 
		
end
//------------------------------------------------
always @ ( * )
begin
	case ( CurrentState )
	//------------------------------------
	`IFU_AFTER_RESET:
	begin

		 rEnable		<= iTrigger;
		 rIpControl <= `IP_SET_VALUE_INITIAL_ADDRESS;//0;
		 oExecutionDone <= 0;
		
		if (iTrigger)
			NextState <= `IFU_INITIAL_STATE;
		else
			NextState <= `IFU_AFTER_RESET;
	end
	//------------------------------------
	`IFU_INITIAL_STATE:
	begin

		rEnable	  <= 1;
		rIpControl <= `IP_SET_VALUE_BRANCH_ADDRESS; //1;
		oExecutionDone <= 0;
		
		//We reached last instrcution (RETURN), and IDU latched the one before that
		if ( wLastInstruction && iDecodeUnitLatchedValues && !rJumpNow ) 
			NextState <= `IFU_WAIT_FOR_LAST_INSTRUCTION_LATCHED_BY_IDU;
		else
			NextState <= `IFU_INITIAL_STATE;
		
	end
	
	//------------------------------------	
	//Here, we wait until IDU latches the last
	//instruction, ie. the RETURN instruction
	`IFU_WAIT_FOR_LAST_INSTRUCTION_LATCHED_BY_IDU:
	begin
		rEnable	  <= ~iDecodeUnitLatchedValues;
		rIpControl <= `IP_SET_VALUE_BRANCH_ADDRESS;
		oExecutionDone <= 0;
			
		if ( iDecodeUnitLatchedValues && !rJumpNow)//&& !iExeBusy && !iIDUBusy )
			NextState <= `IFU_DONE;
		else if ( rJumpNow )
			NextState <= `IFU_INITIAL_STATE;
		else
			NextState <= `IFU_WAIT_FOR_LAST_INSTRUCTION_LATCHED_BY_IDU;
	end
	//------------------------------------
	`IFU_DONE:
	begin
		rEnable	  <= 0;
		rIpControl <= `IP_SET_VALUE_BRANCH_ADDRESS;
		oExecutionDone <= !iExeBusy && !iIDUBusy;//1'b1;
		
				
		if (!iExeBusy && !iIDUBusy)
			NextState <= `IFU_AFTER_RESET;
		else
			NextState <= `IFU_DONE;
		
	end
	//------------------------------------
	default:
	begin
		rEnable	 <= 0;
		rIpControl <= `IP_SET_VALUE_INITIAL_ADDRESS; //0;
		oExecutionDone <= 0;
	
		NextState <= `IFU_AFTER_RESET;
	end
	//------------------------------------	
	endcase
end// always	


//------------------------------------------------------
//
//
`ifdef DEBUG2
	always @ ( negedge iTrigger or negedge iDecodeUnitLatchedValues )
	begin
		$write("(%dns %d)",$time,oInstructionPointer);
	end
	
	
	always @ ( negedge wLastInstruction )
	begin
		$display(" %dns RETURN %d",$time,oMicroCodeReturnValue);
	end
`endif

`ifdef DEBUG2	
	always @ (posedge wStall)
	begin
		$write("<S>");
	end
`endif




endmodule
//-------------------------------------------------------------------------------