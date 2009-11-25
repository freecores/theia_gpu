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
`define IDU_AFTER_RESET	0
`define IDU_WAIT_FOR_NEXT_INSTRUCTION	1
`define IDU_WAIT_FOR_RAM	2
`define IDU_DISPATCH_DECODE_INSTRUCTION	3
`define IDU_LATCH_RAM_VALUES	4
`define IDU_WAIT_FOR_FIRST_INTRUCTION 5
`define IDU_INITIAL_DELAY	6



module InstructionDecode
(
input wire											Clock,
input wire											Reset,
input wire											iTrigger,
input	wire[`INSTRUCTION_WIDTH-1:0]			iEncodedInstruction,
input wire											iExecutioUnitLatchedValues,
input	wire											iInstructionAvailable,
output reg											oBusy,
input	wire[`DATA_ROW_WIDTH-1:0]					iRamValue0,										
input	wire[`DATA_ROW_WIDTH-1:0]					iRamValue1,										
output  wire[`DATA_ADDRESS_WIDTH-1:0]		oRamAddress0,oRamAddress1,

output  wire[`INSTRUCTION_OP_LENGTH-1:0]	oOperation,
output  wire [`DATA_ROW_WIDTH-1:0]				oSource0,oSource1,

output reg oInputsLatched,
//output reg oBusBusy,
output reg oDataReadyForExe,
//input wire iExecutionReady,


output  wire [`DATA_ADDRESS_WIDTH-1:0]	oDestination,

`ifdef DEBUG
	input wire [`ROM_ADDRESS_WIDTH-1:0] iDebug_CurrentIP,
	output wire [`ROM_ADDRESS_WIDTH-1:0] oDebug_CurrentIP,
`endif

input wire [`DATA_ROW_WIDTH-1:0] iDataForward,
input wire [`DATA_ADDRESS_WIDTH-1:0] iLastDestination
);


`ifdef DEBUG
assign oDebug_CurrentIP = iDebug_CurrentIP;

`endif


reg rFirstInstruction;
wire wLatchNow;
wire[`DATA_ADDRESS_WIDTH-1:0] wFF16_2_SourceAddress0;



`define IFU_WAIT_FOR_FIRST_INSTRUCTION 		0
`define IFU_WAIT_FOR_EXE_TO_LATCH				1
`define IFU_WAIT_FOR_INSTRUCTION_AVAILABLE 	2
`define SELECT_ZERO 			1'd0
`define SELECT_IAVAILABLE	1'd1

`define INSTRUCTION_OPCODE iEncodedInstruction[`INSTRUCTION_WIDTH-1:`INSTRUCTION_WIDTH-`INSTRUCTION_OP_LENGTH]

//The next logic is to control when to latch incoming values.
//Values coming from IFU will be latched by IDU everytime the
//'wLatchNow' signal is set to 1. We need to garanteed that the wLatchNow is set only if: 
// 1) There is a instruction available from IFU. ie 'iInstructionAvailable' is set.
// 2) EXE unit already latched the decoded values we provided from the previous cycle.
// ie. we won't read new values until we are sure EXE latched the previous values
//Since the previous 2 conditions don't necesarily happens cocurrently and the pipeline
//is asynchronous, a FSM is implemented to correctly represent this behavior.
//This FSM has only 2 states and also controls the 'oBusy' signal, the 'oDataReadyForExe'
//signal and the 'oInputsLatched' signal.

reg rLatchNowSelector;
 
MUXFULLPARALELL_1Bit_1SEL iInstructionAvailable_MUX
 (
 .Sel( rLatchNowSelector ),
 .I1( 1'b0 ), 
 .I2( iInstructionAvailable ),
 .O1( wLatchNow )
 );



reg[1:0] rLatchNow_CurrentState;
reg[1:0] rLatchNow_NextState;

//Next State logic for the LatchNow signal
always @ (posedge Clock)
begin
	if (Reset)
		rLatchNow_CurrentState <= `IFU_WAIT_FOR_INSTRUCTION_AVAILABLE;
	else	
		rLatchNow_CurrentState <= rLatchNow_NextState;
end

always @ ( * )
begin
	case ( rLatchNow_CurrentState )
		//--------------------------------------
		`IFU_WAIT_FOR_INSTRUCTION_AVAILABLE:
		begin
			rLatchNowSelector <= `SELECT_IAVAILABLE;
			oDataReadyForExe  <= 0;
			oBusy					<= 0;
			oInputsLatched		<= 0;
			
			if ( iInstructionAvailable )
				rLatchNow_NextState <= `IFU_WAIT_FOR_EXE_TO_LATCH;
			else
				rLatchNow_NextState <= `IFU_WAIT_FOR_INSTRUCTION_AVAILABLE;
		end
		//--------------------------------------
		`IFU_WAIT_FOR_EXE_TO_LATCH:
		begin
			rLatchNowSelector <= `SELECT_ZERO;
			oDataReadyForExe  <= 1;
			oBusy					<= 1;
			oInputsLatched		<= 1;
			
			if ( iExecutioUnitLatchedValues )
				rLatchNow_NextState <= `IFU_WAIT_FOR_INSTRUCTION_AVAILABLE;
			else
				rLatchNow_NextState <= `IFU_WAIT_FOR_EXE_TO_LATCH;
		end
		//--------------------------------------
	endcase
end


//There are 2 types of operations to be decoded:
//1) Operations that read thier parameters from memory locations. 
//2) Operations that use inmediate values instead of address locations.
//The way IDU distinguishes between both is via the wInmediateOperand bit.
//This is bit 5 of the operation part of the instruction.

wire wInmediateOperand;
assign wInmediateOperand = (oOperation[`INSTRUCTION_IMM_BIT ] == 1 || oOperation == `INSTRUCTION_OP_LENGTH'b0) ? 1 : 0;

//Here we decode the 2 Data sources for the instruction: wSource0 and wSource1.
//wSource0 will always be assigned to the contents of memory address location,
//however wSource1 can either the contents of a memory location or inmediate 
//operand.

wire[`DATA_ROW_WIDTH-1:0] wSource0,wSource1;

assign wSource0 = iRamValue0;
assign wSource1 = ( wInmediateOperand ) ? {oRamAddress1,wFF16_2_SourceAddress0,32'b0,32'b0} : iRamValue1;

//Since we are implementing a pipeline, data hazards such as RAW may arise.
//in order to avoid such race conditions without inserting aditional stall cycles,
//a data forward approach has been taken. 2 separe data forwarding signals are available
//to indicate weather fordwarding is needed on either of the Source ports.

wire rTriggerSource0DataForward,rTriggerSource1DataForward;
wire wSource0AddrssEqualsLastDestination,wSource1AddrssEqualsLastDestination;

assign wSource0AddrssEqualsLastDestination = (oRamAddress0 == iLastDestination) ? 1'b1: 1'b0;
assign wSource1AddrssEqualsLastDestination = (oRamAddress1 == iLastDestination) ? 1'b1: 1'b0;
assign rTriggerSource0DataForward = wSource0AddrssEqualsLastDestination;
assign rTriggerSource1DataForward = wSource1AddrssEqualsLastDestination && !wInmediateOperand;

//Once we made a decicions on weather the Sources must be forwarded or not, a series of muxes
//are used to routed the correct data into the decoded Source outputs

MUXFULLPARALELL_96bits_2SEL Source0_Mux
(
	.Sel( rTriggerSource0DataForward ),
	.I1( wSource0  ),
	.I2( iDataForward ),
	.O1( oSource0 )
);

MUXFULLPARALELL_96bits_2SEL Source1_Mux
(
	.Sel( rTriggerSource1DataForward ),
	.I1( wSource1  ),
	.I2( iDataForward ),
	.O1( oSource1 )
);

//Next we instance the pipestage Flip Flops to store the stage's data
FF16_POSEDGE_SYNCRONOUS_RESET PSRegSource0Address
(
	.Clock( wLatchNow ),
	.Clear( Reset ),
	.D( iEncodedInstruction[15:0] ),
	.Q( wFF16_2_SourceAddress0 )
	
);


MUXFULLPARALELL_16bits_2SEL RAMAddr0MUX
 (
  .Sel( wInmediateOperand ),
  .I1( wFF16_2_SourceAddress0 ),
  .I2( oDestination ),
  .O1( oRamAddress0 )
 );

FF16_POSEDGE_SYNCRONOUS_RESET PSRegSource1Address
(
	.Clock( wLatchNow ),
	.Clear( Reset ),
	.D( iEncodedInstruction[31:16] ),
	.Q( oRamAddress1 )
);


FFD16_POSEDGE PSRegDestination
(
	.Clock( wLatchNow ),
	.D( iEncodedInstruction[47:32]  ),
	.Q( oDestination )
	
);

/*
FFD6_POSEDGE PSRegOperation
(
	.Clock( wLatchNow ),
	.D( `INSTRUCTION_OPCODE  ),
	.Q( oOperation )
	
);
*/
FFD_OPCODE_POSEDGE PSRegOperation
(
	.Clock( wLatchNow ),
	.D( `INSTRUCTION_OPCODE  ),
	.Q( oOperation )
	
);
//------------------------------------------------


`ifdef DEBUG2
always @ ( negedge Clock  )
begin
	if ( iInstructionAvailable )
	begin
		
		if ( oRamAddress0 == iLastDestination || oRamAddress1 == iLastDestination)
			$display("%d Data Forward %h ",$time, iDataForward);
	end	
end
`endif


//------------------------------------------------



reg	[6:0]	CurrentState, 	NextState;
//------------------------------------------------
  always @(posedge Clock or posedge Reset) 
  begin 
  		
    if (Reset)// || iTrigger )  
		CurrentState <= `IDU_AFTER_RESET; 
    else        
		CurrentState <= NextState; 
		
  end
//------------------------------------------------

always @ ( * )
begin
	case ( CurrentState )
	//------------------------------------
	/*
		By the time the trigger gets to 1,
		there will be data already waiting..
		
	*/
	`IDU_AFTER_RESET:
	begin

	//	oBusBusy				<= 0;
		rFirstInstruction <= 1;
		
		if (iInstructionAvailable) 
			NextState <= `IDU_WAIT_FOR_NEXT_INSTRUCTION; 
		else
			NextState <= `IDU_AFTER_RESET;
	end
		//------------------------------------
	`IDU_WAIT_FOR_NEXT_INSTRUCTION:
	begin

		//oBusBusy				<= 0;
		rFirstInstruction <= 0;	
		
		if ( iExecutioUnitLatchedValues )
			NextState <= `IDU_WAIT_FOR_RAM;
		else
			NextState <= `IDU_WAIT_FOR_NEXT_INSTRUCTION;
		
	end
	//------------------------------------
	`IDU_WAIT_FOR_RAM:
	begin
		//oBusBusy				<= 1;
		rFirstInstruction <= 0;
		
		if (iInstructionAvailable ||  oOperation == `INSTRUCTION_OP_LENGTH'd0)
			NextState <= `IDU_WAIT_FOR_NEXT_INSTRUCTION;
		else
			NextState <= `IDU_WAIT_FOR_RAM;
			
	end
	
	//------------------------------------
	default:
	begin
		//oBusBusy				<= 0;
		rFirstInstruction <= 0;
		
		NextState <= `IDU_WAIT_FOR_NEXT_INSTRUCTION;
	
	end
	//------------------------------------
	endcase
end  





`ifdef DEBUG2
always @ ( posedge wLatchNow )
begin
	
		$display("( %d %d [%d %d] - %d)",
		iEncodedInstruction[53:48],iEncodedInstruction[47:32],
		iEncodedInstruction[31:16],iEncodedInstruction[15:0], $time );
	
end
`endif


endmodule
