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
/**********************************************************************************
Description:

This is the main Finite State Machine.

**********************************************************************************/

`timescale 1ns / 1ps
`include "aDefinitions.v"

`define CU_AFTER_RESET_STATE 0
`define CU_WAIT_FOR_INITIAL_CONFIGURATION 1
`define CU_TRIGGER_CONFIGURATION_DATA_READ 2
`define CU_WAIT_FOR_CONFIG_DATA_READ	3
`define CU_ACK_CONFIG_DATA_READ 4
`define CU_PRECALCULATE_CONSTANTS 5
`define CU_WAIT_FOR_CONSTANT 6
`define CU_ACK_PRECALCULATE_CONSTANTS 7
`define CU_WAIT_FOR_TASK 8
`define CU_READ_TASK_DATA 9
`define CU_WAIT_TASK_DATA_READ 10
`define CU_ACK_TASK_DATA_READ 11
`define CU_TRIGGER_RGU 12
`define CU_WAIT_FOR_RGU 13
`define CU_ACK_RGU 14
`define CU_TRIGGER_GEO 15
`define CU_WAIT_FOR_GEO_SYNC 16
//`define CU_CHECK_AABBIU_REQUEST 17
`define CU_TRIGGER_TCC 17
//`define CU_CHECK_BIU_REQUEST 18
`define CU_TRIGGER_TFF 18
//`define CU_CHECK_GEO_DONE 19
`define CU_WAIT_FOR_TFF 19
`define CU_TRIGGER_AABBIU 20
`define CU_WAIT_FOR_AABBIU 21
`define CU_TRIGGER_BIU 22
`define CU_WAIT_FOR_BIU 23
`define CU_ACK_UCODE 24
`define CU_TRIGGER_PSU 25
`define CU_WAIT_FOR_PSU 26
`define CU_ACK_PSU 27
`define CU_TRIGGER_PCU 28
`define CU_WAIT_FOR_PCU 29
`define CU_ACK_PCU 30
`define CU_CHECK_HIT 31
`define CU_CLEAR_REGISTERS 32
`define CU_WAIT_CLEAR_REGISTERS 33
`define CU_ACK_CLEAR_REGISTERS	34
`define CU_TRIGGER_PSU_WITH_TEXTURE 35
`define WAIT_FOR_TCC 36
`define CU_TRIGGER_NPU 37
`define CU_WAIT_NPU 38
`define CU_ACK_NPU 39
`define CU_PERFORM_INTIAL_CONFIGURATION 40
`define CU_SET_PICTH 41

//--------------------------------------------------------------
module ControlUnit
(

input  wire                                  Clock,
input  wire                                  Reset,
input  wire[15:0]                            iControlRegister,
output reg                                   oGFUEnable,
input	 wire                                  iTriggerAABBIURequest,
input	wire                                   iTriggerBIURequest,
input wire                                   iTriggertTCCRequest,
output reg                                   oUCodeEnable,
output reg[`ROM_ADDRESS_WIDTH-1:0]           oCodeInstructioPointer,
input	wire                                   iUCodeDone,
input wire                                   iUCodeReturnValue,
input wire                                   iGFUDone,
input wire                                   iGEOSync,
output reg                                   oTriggerTFF,
input wire                                   iTFFDone,
input wire                                   MST_I,
output reg[2:0]                              oRamBusOwner,
input wire                                   iIODone,
output reg                                   oSetCurrentPitch,
output reg                                   oIOWritePixel
		
);

//Internal State Machine varibles
reg	[5:0]	CurrentState;
reg	[5:0]	NextState;
integer ucode_file;
reg rResetHitFlop,rHitFlopEnable;
wire wHit;

`ifdef DUMP_CODE
	integer log;
	
	initial
	begin
	
	$display("Opening ucode dump file....\n");
	ucode_file = $fopen("CU.log","w");
	end

`endif


//wire[`ROM_ADDRESS_WIDTH-1:0] wAABBIUAddress;
//assign wAABBIUAddress = (iControlRegister[`CR_USER_AABBIU] == 1'b1) ? `USER_AABBIU_UCODE_ADDRESS : `ENTRYPOINT_INDEX_AABBIU;
 
 
//--------------------------------------------------------------
FFToggleOnce_1Bit FFTO1
(
	.Clock( Clock ),
	.Reset( rResetHitFlop ),
	.Enable( rHitFlopEnable && iUCodeDone ),
	.S( iUCodeReturnValue ),
	.Q( wHit )
);
//--------------------------------------------------------------

`ifdef DEBUG
	always @ ( wHit )
	begin
		`LOGME "*** Triangle HIT ***\n");
	end
`endif

//Next states logic and Reset sequence
always @(posedge Clock or posedge Reset) 
  begin 
			
    if (Reset)  
		CurrentState <= `CU_AFTER_RESET_STATE; 
    else        
		CurrentState <= NextState; 
		
  end

//--------------------------------------------------------------
always @ ( * )
begin
	case (CurrentState)
	//-----------------------------------------
	`CU_AFTER_RESET_STATE:
	begin
	
	`ifdef DEBUG	
		`LOGME"%d CU_AFTER_RESET_STATE\n",$time);
	`endif
	
		oRamBusOwner 				<= 0;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_INITIAL; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 0;	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 1;
		rHitFlopEnable				<= 0;
		oTriggerTFF             <= 0;
		oSetCurrentPitch        <= 1;
		//oIncCurrentPitch        <= 0;
		
		NextState 					<= `CU_WAIT_FOR_INITIAL_CONFIGURATION;
		
	end
	//-----------------------------------------
	
	`CU_WAIT_FOR_INITIAL_CONFIGURATION:
	begin
	$display("CU_WAIT_FOR_INITIAL_CONFIGURATION");
//		`ifdef DEBUG
//			`LOGME"%d Control: CU_WAIT_FOR_INITIAL_CONFIGURATION\n",$time);
//		`endif
	
		oRamBusOwner 				<= 0;
		oCodeInstructioPointer	<= 0; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 0;	
		oIOWritePixel				<= 0;		
		rResetHitFlop				<= 1;	
		rHitFlopEnable				<= 0;
      oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;		
		
		if ( MST_I  )	
			NextState <= `CU_PERFORM_INTIAL_CONFIGURATION;//`CU_WAIT_FOR_CONFIG_DATA_READ;
		else
			NextState <= `CU_WAIT_FOR_INITIAL_CONFIGURATION;
						
		
	end
	//-----------------------------------------
	`CU_PERFORM_INTIAL_CONFIGURATION:
	begin
	oRamBusOwner 				<= 0;
		oCodeInstructioPointer	<= 0; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 0;	
		oIOWritePixel				<= 0;		
		rResetHitFlop				<= 1;	
		rHitFlopEnable				<= 0;
      oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;		
		
		if ( MST_I  )	
			NextState <= `CU_PERFORM_INTIAL_CONFIGURATION;//`CU_WAIT_FOR_CONFIG_DATA_READ;
		else
			NextState <= `CU_CLEAR_REGISTERS;
						
	end
	//-----------------------------------------
	`CU_CLEAR_REGISTERS:
	begin
	`ifdef DEBUG	
		`LOGME"%d CU_CLEAR_REGISTERS\n",$time);
	`endif	
		
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_INITIAL; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 1;	//*
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;
		rHitFlopEnable				<= 0;
		oTriggerTFF             <= 0;
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		NextState 					<= `CU_WAIT_CLEAR_REGISTERS;
	end
//-----------------------------------------	
	`CU_WAIT_CLEAR_REGISTERS:
	begin
//	`ifdef DEBUG
//		`LOGME"%d CU_WAIT_CLEAR_REGISTERS\n",$time);
//	`endif	
		
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_INITIAL; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 0; 	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;
      oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if ( iUCodeDone )
			NextState <= `CU_ACK_CLEAR_REGISTERS;
		else
			NextState <= `CU_WAIT_CLEAR_REGISTERS;
			
	end
	//-----------------------------------------
	`CU_ACK_CLEAR_REGISTERS:
	begin
	`ifdef DEBUG
		`LOGME"%d CU_ACK_CLEAR_REGISTERS\n", $time);
	`endif	
	
		oRamBusOwner 				<= 0;
		oCodeInstructioPointer	<= 0; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 0; //* 	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		NextState <= `CU_WAIT_FOR_CONFIG_DATA_READ;
	end	
	
	
	
	//-----------------------------------------
	`CU_WAIT_FOR_CONFIG_DATA_READ:
	begin
	$display("CU_WAIT_FOR_CONFIG_DATA_READ");
//		`ifdef DEBUG
//			`LOGME"%d Control: CU_WAIT_FOR_CONFIG_DATA_READ\n",$time);
//		`endif

		oRamBusOwner 				<= 0;//`REG_BUS_OWNED_BY_BCU;
		oCodeInstructioPointer	<= 0; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 0;	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;
      oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if ( MST_I == 0  )
			NextState <= `CU_PRECALCULATE_CONSTANTS;
		else
			NextState <= `CU_WAIT_FOR_CONFIG_DATA_READ;
		
	end
	//-----------------------------------------
	`CU_PRECALCULATE_CONSTANTS:
	begin
	$display("CU_PRECALCULATE_CONSTANTS");
	`ifdef DEBUG
		`LOGME"%d Control: CU_PRECALCULATE_CONSTANTS\n", $time);
	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_CPPU; 
		oGFUEnable 				<= 0;
		oUCodeEnable				<= 1; //*	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		NextState <= `CU_WAIT_FOR_CONSTANT;
		
	end
	//-----------------------------------------
	`CU_WAIT_FOR_CONSTANT:
	begin
//	`ifdef DEBUG
//		`LOGME"%d Control: CU_WAIT_FOR_CONSTANT\n", $time);
//	`endif


		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_CPPU; 
		oGFUEnable 				   <= 0;
		oUCodeEnable				<= 0; //* 	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if ( iUCodeDone )
			NextState <= `CU_ACK_PRECALCULATE_CONSTANTS;
		else
			NextState <= `CU_WAIT_FOR_CONSTANT;
			
	end
	//-----------------------------------------
	`CU_ACK_PRECALCULATE_CONSTANTS:
	begin
	$display("CU_ACK_PRECALCULATE_CONSTANTS");
	`ifdef DEBUG
		`LOGME"%d Control: CU_ACK_PRECALCULATE_CONSTANTS\n", $time);
	`endif
	
	
		oRamBusOwner 				<= 0;//`REG_BUS_OWNED_BY_BCU;
		oCodeInstructioPointer	<= 0; 
		oGFUEnable 				   <= 0;
		oUCodeEnable				<= 0; //* 	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;
		oSetCurrentPitch        <= 0;		
		//oIncCurrentPitch        <= 0;
		
		NextState <= `CU_TRIGGER_RGU;//CU_WAIT_FOR_TASK;
		
	end
	//-----------------------------------------
	`CU_TRIGGER_RGU:
	begin
		
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_RGU\n",$time);
	`endif
		
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_RGU; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 1;	//*
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		NextState <= `CU_WAIT_FOR_RGU;
	end
	//-----------------------------------------
	`CU_WAIT_FOR_RGU:
	begin

//	`ifdef DEBUG
//		`LOGME"%d Control: CU_WAIT_FOR_RGU\n",$time);
//	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= 0; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 0;	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;
		oSetCurrentPitch        <= 0;		
		//oIncCurrentPitch        <= 0;
		
		if ( iUCodeDone )
			NextState <= `CU_ACK_RGU;
		else
			NextState <= `CU_WAIT_FOR_RGU;
	end
	//-----------------------------------------
	`CU_ACK_RGU:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: CU_ACK_RGU\n",$time);
	`endif
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= 0; 
		oGFUEnable 					<= 0;
		oUCodeEnable				<= 0; //*	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;			
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
	
		if ( iUCodeDone  == 0)
			NextState <= `CU_TRIGGER_GEO;
		else
			NextState <= `CU_ACK_RGU;
		
	end
	//-----------------------------------------
	`CU_TRIGGER_GEO:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_GEO\n",$time);
	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0; 
		oUCodeEnable				<= 0;	
		oGFUEnable 					<= 1;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 1;	//*
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		NextState <= `CU_WAIT_FOR_GEO_SYNC;
		
	end
	//-----------------------------------------
	`CU_WAIT_FOR_GEO_SYNC:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: CU_WAIT_FOR_GEO_SYNC\n",$time);
	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0; 
		oUCodeEnable				<= 0;	
		oGFUEnable 					<= 0; //Change AUg 15
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
	if (iGEOSync & iTriggerAABBIURequest )
		NextState <= `CU_TRIGGER_AABBIU;
	else if (iGEOSync & iTriggerBIURequest)
		NextState <= `CU_TRIGGER_BIU;
	else if (iGEOSync & iTriggertTCCRequest )
      NextState <= `CU_TRIGGER_TCC;
   else if (iGEOSync & iGFUDone )
      NextState <= `CU_CHECK_HIT;
   else
      NextState <= `CU_WAIT_FOR_GEO_SYNC;	

	end
	//-----------------------------------------
	`CU_TRIGGER_TCC:
	begin
	//$display("CU_TRIGGER_TCC");
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_TCC\n",$time);
	`endif
	
	   oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_TCC; 
		oUCodeEnable				<= 1;	//*
		oGFUEnable 					<= 0;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;	
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
	  NextState  <= `WAIT_FOR_TCC;
	end
	//-----------------------------------------
	`WAIT_FOR_TCC:
	begin
	
	//$display("WAIT_FOR_TCC");
	   oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_TCC; 
		oUCodeEnable				<= 0;	//*
		oGFUEnable 					<= 0;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;	
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
	   if ( iUCodeDone )
			NextState <= `CU_ACK_UCODE;
		else
			NextState <= `WAIT_FOR_TCC;
	
	end
	//-----------------------------------------
	/*
	Was there any hit at all?
	At this point, all the triangles in the list
	have been traversed looking for a hit with our ray.
	There are 3 possibilities:
	1) The was not a single hit, then just paint a black
	pixel on the screen and send it via PCU.
	2)There was a hit and Texturing is not enabled, then trigger the PSU with
	no texturing
	2) There was a hit and Texturing is enabled, then fetch the texture 
	values corresponding to the triangle that we hitted. 
	*/
	`CU_CHECK_HIT:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: CU_CHECK_HIT\n",$time);
	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0; 
		oUCodeEnable				<= 0;
		oGFUEnable					<= 0;	///CHANGED Aug 15
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
	   oTriggerTFF             <= 0;			
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if (wHit && !iControlRegister[`CR_EN_TEXTURE] )
			NextState <= `CU_TRIGGER_PSU;
		else if (wHit && iControlRegister[`CR_EN_TEXTURE])	
			NextState <= `CU_TRIGGER_TFF;		//Fetch the texture values from external RAM
		else
			NextState <= `CU_TRIGGER_PCU;		//Make sure contents of the OUT_REG are ZERo!
	end
	//-----------------------------------------
	/*
	Get the texture values from external RAM.
	GFU already took care of calculating the correct 
	texture addresses for the 4 coordinates so now lets
	just ask for them.
	*/
	`CU_TRIGGER_TFF:
	begin
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_TFF\n",$time);
	`endif
	
	//$display("CU_TRIGGER_TFF");
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0; 
		oUCodeEnable				<= 0;
		oGFUEnable					<= 1;	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;
		oTriggerTFF             <= 1;       //*
	   oSetCurrentPitch        <= 0;   
		//oIncCurrentPitch        <= 0;
		
		NextState <= `CU_WAIT_FOR_TFF;
	end
	//-----------------------------------------
	`CU_WAIT_FOR_TFF:
	begin
	
	   oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0; 
		oUCodeEnable				<= 0;
		oGFUEnable					<= 0;	 //Changed Aug 14
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;
		oTriggerTFF             <= 0;      
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
	if (iTFFDone)
		NextState <= `CU_TRIGGER_PSU_WITH_TEXTURE;
	else
		NextState <= `CU_WAIT_FOR_TFF;
		
	end
	//-----------------------------------------
	`CU_TRIGGER_PSU_WITH_TEXTURE:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_PSU_WITH_TEXTURE\n",$time);
	`endif
	
	   oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_PSU2;
		oUCodeEnable				<= 1;
		oGFUEnable					<= 0;	
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;
		oTriggerTFF             <= 0;      
		oSetCurrentPitch        <= 0;
	   //oIncCurrentPitch        <= 0;
		
		NextState <= `CU_WAIT_FOR_PSU;
	end
	//-----------------------------------------
	`CU_TRIGGER_AABBIU:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_AABBIU\n",$time);
	`endif
//	$stop();
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		
		oCodeInstructioPointer	<=`ENTRYPOINT_INDEX_AABBIU;
		oUCodeEnable				<= 1;
		oGFUEnable					<= 1;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;			
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
	
		NextState <= `CU_WAIT_FOR_AABBIU;
	end
	//-----------------------------------------
	`CU_WAIT_FOR_AABBIU:
	begin
	
	
//	`ifdef DEBUG
//		`LOGME"%d Control: CU_WAIT_FOR_AABBIU\n",$time);
//	`endif


//	$display("iUCodeDone",iUCodeDone);
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_AABBIU;
		oUCodeEnable				<= 0;
		oGFUEnable					<= 1;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if ( iUCodeDone )
		begin
	//	   $display("iUCodeDone\n",iUCodeDone);
	//		$stop();
			NextState <= `CU_ACK_UCODE;
		end	
		else
			NextState <= `CU_WAIT_FOR_AABBIU;
	end
	//-----------------------------------------
	`CU_TRIGGER_BIU:
	begin
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_BIU\n",$time);
	`endif
		
			oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
			oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_BIU;
			oUCodeEnable				<= 1;
			oGFUEnable					<= 1;
			oIOWritePixel				<= 0;
			rResetHitFlop				<= 0;//1;	
			rHitFlopEnable				<= 1;		
         oTriggerTFF             <= 0;					
			oSetCurrentPitch        <= 0;
			//oIncCurrentPitch        <= 0;
		//	$stop();
			
			NextState <= `CU_WAIT_FOR_BIU;
		
	end
	//-----------------------------------------
	`CU_WAIT_FOR_BIU:
	begin
//	`ifdef DEBUG
//		`LOGME"%d Control: CU_WAIT_FOR_BIU\n",$time);
//	`endif
	
			oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
			oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_BIU;
			oUCodeEnable				<= 0;
			oGFUEnable					<= 1;
			oIOWritePixel				<= 0;
			rResetHitFlop				<= 0;	
			rHitFlopEnable				<= 1;	
         oTriggerTFF             <= 0;
			oSetCurrentPitch        <= 0;	
			//oIncCurrentPitch        <= 0;
			
		if ( iUCodeDone )
			NextState <= `CU_ACK_UCODE;
		else
			NextState <= `CU_WAIT_FOR_BIU;
	end
	//-----------------------------------------
	/*
		ACK UCODE by setting oUCodeEnable = 0
	*/
	`CU_ACK_UCODE:
	begin
	`ifdef DEBUG
		`LOGME"%d Control: CU_ACK_UCODE\n",$time);
	`endif
	
			oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
			oCodeInstructioPointer	<= 0; //*
			oUCodeEnable				<= 0;	//*
			oGFUEnable					<= 0; //Changed Aug 15
			oIOWritePixel				<= 0;
			rResetHitFlop				<= 0;
			rHitFlopEnable				<= 0;			
         oTriggerTFF             <= 0;					
			oSetCurrentPitch        <= 0;
			//oIncCurrentPitch        <= 0;
			
	//		$stop();
			
			if ( iUCodeDone == 0 )
				NextState <= `CU_WAIT_FOR_GEO_SYNC;
			else
				NextState <= `CU_ACK_UCODE;
	end
	//-----------------------------------------
	/*
	Here we no longer use GFU so set Enable to zero
	*/
	`CU_TRIGGER_PSU:
	begin
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_PSU\n",$time);
	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_PSU;
		oUCodeEnable				<= 1;
		oGFUEnable					<= 0;//*
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
		oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;	
		//oIncCurrentPitch        <= 0;
			
			
		NextState <= `CU_WAIT_FOR_PSU;
	end
	//-----------------------------------------
	`CU_WAIT_FOR_PSU:
	begin
	
//	`ifdef DEBUG
//		`LOGME"%d Control: CU_TRIGGER_PSU\n",$time);
//	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_PSU;
		oUCodeEnable				<= 0;
		oGFUEnable					<= 0;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
		oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		
		if ( iUCodeDone )
			NextState <= `CU_ACK_PSU;
		else
			NextState <= `CU_WAIT_FOR_PSU;
		
	end
	//-----------------------------------------
	`CU_ACK_PSU:
	begin
	`ifdef DEBUG
		`LOGME"%d Control: CU_ACK_PSU\n",$time);
	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= 0;	//*
		oUCodeEnable				<= 0;	//*
		oGFUEnable					<= 0;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if ( iUCodeDone  == 0)
			NextState <= `CU_TRIGGER_PCU;
		else
			NextState <= `CU_ACK_PSU;
		
		
	end
	//-----------------------------------------
	/*
		Trigger the Pixel Commit.
	*/
	`CU_TRIGGER_PCU:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_PCU\n",$time);
	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0;	//*
		oUCodeEnable				<= 0;	//*
		oGFUEnable					<= 0;
		oIOWritePixel				<= 1; //*
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;					
		oSetCurrentPitch        <= 0; 
		//oIncCurrentPitch        <= 0;
		
		
		NextState <= `CU_SET_PICTH;
			
	end
	//-----------------------------------------
	`CU_SET_PICTH:
	begin
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0;	//*
		oUCodeEnable				<= 0;	//*
		oGFUEnable					<= 0;
		oIOWritePixel				<= 1; //*
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;					
		oSetCurrentPitch        <= 1; //*
		//oIncCurrentPitch        <= 0;
		
		
		NextState <= `CU_WAIT_FOR_PCU;
	end
	//-----------------------------------------
	`CU_WAIT_FOR_PCU:
	begin
	
//	`ifdef DEBUG
//		`LOGME"%d Control: CU_WAIT_FOR_PCU\n",$time);
//	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0;	//*
		oUCodeEnable				<= 0;	//*
		oGFUEnable					<= 0;
		oIOWritePixel				<= 1;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if ( iIODone )
			NextState <= `CU_ACK_PCU;
		else
			NextState <= `CU_WAIT_FOR_PCU;
		
	end
	//-----------------------------------------
	`CU_ACK_PCU:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: CU_ACK_PCU\n",$time);
	`endif
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_GFU;
		oCodeInstructioPointer	<= 0;	//*
		oUCodeEnable				<= 0;	//*
		oGFUEnable					<= 0;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;	
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;

		NextState <= `CU_TRIGGER_NPU;
		
	end
	//-----------------------------------------
	`CU_TRIGGER_NPU: //Next Pixel Unit
	begin
	`ifdef DEBUG
		`LOGME"%d Control: CU_TRIGGER_NPU\n",$time);
	`endif
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_NPG;	//*
		oUCodeEnable				<= 1;	//*
		oGFUEnable					<= 0;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;	
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;

		NextState <= `CU_WAIT_NPU;
	end
	//-----------------------------------------
	`CU_WAIT_NPU:
	begin
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= `ENTRYPOINT_INDEX_NPG;
		oUCodeEnable				<= 0;
		oGFUEnable					<= 0;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
		oTriggerTFF             <= 0;		
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if ( iUCodeDone )
			NextState <= `CU_ACK_NPU;
		else
			NextState <= `CU_WAIT_NPU;
	end	
	//-----------------------------------------
	`CU_ACK_NPU:
	begin
	`ifdef DEBUG
		`LOGME"%d Control: CU_ACK_PSU\n",$time);
	`endif
	
		oRamBusOwner 				<= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	<= 0;	//*
		oUCodeEnable				<= 0;	//*
		oGFUEnable					<= 0;
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;		
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		if ( iUCodeDone  == 0)
			NextState <= `CU_TRIGGER_RGU;
		else
			NextState <= `CU_ACK_NPU;
		
		
	end	
	//-----------------------------------------
	default:
	begin
	
	`ifdef DEBUG
		`LOGME"%d Control: ERRO Undefined State\n",$time);
	`endif
	
		oRamBusOwner 				<= 0;
		oCodeInstructioPointer	<= 0;	
		oUCodeEnable				<= 0;
		oGFUEnable					<= 0;		
		oIOWritePixel				<= 0;
		rResetHitFlop				<= 0;	
		rHitFlopEnable				<= 0;	
      oTriggerTFF             <= 0;				
		oSetCurrentPitch        <= 0;
		//oIncCurrentPitch        <= 0;
		
		NextState <= `CU_AFTER_RESET_STATE;
	end
	//-----------------------------------------

	endcase
	
end //always	
endmodule
