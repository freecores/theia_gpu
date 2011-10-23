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
`ifdef VERILATOR
`include "Collaterals.v"
`endif

`define CU_AFTER_RESET_STATE                0
`define CU_WAIT_FOR_INITIAL_CONFIGURATION   1
`define CU_TRIGGER_CONFIGURATION_DATA_READ  2
`define CU_WAIT_FOR_CONFIG_DATA_READ        3
`define CU_ACK_CONFIG_DATA_READ             4
`define CU_PRECALCULATE_CONSTANTS           5
`define CU_WAIT_FOR_CONSTANT                6
`define CU_ACK_PRECALCULATE_CONSTANTS       7
`define CU_TRIGGER_MAIN                     8
`define CU_WAIT_FOR_MAIN                    9
`define CU_ACK_MAIN                         10
`define CU_CLEAR_REGISTERS                  11
`define CU_WAIT_CLEAR_REGISTERS             12
`define CU_ACK_CLEAR_REGISTERS              13
`define CU_PERFORM_INTIAL_CONFIGURATION     14
`define CU_TRIGGER_USERCONSTANTS            15
`define CU_WAIT_USERCONSTANTS               16
`define CU_ACK_USERCONSTANTS                17
`define CU_DONE                             18
`define CU_WAIT_FOR_RENDER_ENABLE           19
`define CU_WAIT_FOR_HOST_DATA_AVAILABLE     20
`define CU_WAIT_FOR_HOST_DATA_ACK           21
`define CU_COMMIT_PIXEL_RESULT              22
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
//output reg[2:0]                              //oRamBusOwner,
input wire                                   iIODone,
output reg                                   oSetCurrentPitch,
output reg                                   oFlipMemEnabled,
output reg                                   oFlipMem,
output reg                                   oIOWritePixel,
input wire                                   iRenderEnable,
input wire                                   iSceneTraverseComplete,
input wire                                   iHostDataAvailable,
input wire                                   iHostAckDataRead,

`ifdef DEBUG
input wire[`MAX_CORES-1:0]                  iDebug_CoreID,
`endif

output reg                                   oResultCommited,
output reg                                   oDone
		
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
	
	//$display("Opening ucode dump file....\n");
	ucode_file = $fopen("CU.log","w");
	end

`endif
 
 
 
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
	
	`ifdef DEBUG_CU	
		$display("%d CU_AFTER_RESET_STATE\n",$time);
	`endif
	
		//oRamBusOwner 				= 0;
		oCodeInstructioPointer	= `ENTRYPOINT_INDEX_INITIAL; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0;	
		oIOWritePixel				= 0;
		rResetHitFlop				= 1;
		rHitFlopEnable				= 0;
		oTriggerTFF             = 0;
		oSetCurrentPitch        = 1;
		oFlipMemEnabled         = 0; 
		oFlipMem						= 0;
		oDone                   = 0;
		oResultCommited			= 0;
		//oIncCurrentPitch        = 0;
		
		NextState 					= `CU_WAIT_FOR_INITIAL_CONFIGURATION;
		
	end
	//-----------------------------------------
	
	`CU_WAIT_FOR_INITIAL_CONFIGURATION:
	begin
	
		oCodeInstructioPointer	= 0; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0;	
		oIOWritePixel				= 0;		
		rResetHitFlop				= 1;	
		rHitFlopEnable				= 0;
      oTriggerTFF             = 0;		
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;  
		oFlipMem						= 0;
		oDone                   = 0;
		oResultCommited			= 0;
		//oIncCurrentPitch        = 0;		
		
		if ( MST_I  )	
			NextState = `CU_PERFORM_INTIAL_CONFIGURATION;//`CU_WAIT_FOR_CONFIG_DATA_READ;
		else
			NextState = `CU_WAIT_FOR_INITIAL_CONFIGURATION;
						
		
	end
	//-----------------------------------------
	`CU_PERFORM_INTIAL_CONFIGURATION:
	begin
	
	//oRamBusOwner 				= 0;
		oCodeInstructioPointer	= 0; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0;	
		oIOWritePixel				= 0;		
		rResetHitFlop				= 1;	
		rHitFlopEnable				= 0;
      oTriggerTFF             = 0;		
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;  
		oFlipMem						= 0;
		oDone                   = 0;
		oResultCommited			= 0;	
		//oIncCurrentPitch        = 0;		
		
		if ( MST_I  == 0 && iRenderEnable == 1'b1)	
			NextState = `CU_CLEAR_REGISTERS;//`CU_WAIT_FOR_CONFIG_DATA_READ;
		else 
			NextState = `CU_PERFORM_INTIAL_CONFIGURATION;
		
						
	end
	//-----------------------------------------
	`CU_CLEAR_REGISTERS:
	begin
	
	`ifdef DEBUG_CU	
		$display("%d CU_CLEAR_REGISTERS\n",$time);
	`endif	
		
		oCodeInstructioPointer	= `ENTRYPOINT_INDEX_INITIAL; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 1;	//*
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;
		rHitFlopEnable				= 0;
		oTriggerTFF             = 0;
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 1;  
		oFlipMem						= 0;
		oDone                   = 0;
		oResultCommited			= 0;			
	
			
		NextState 					= `CU_WAIT_CLEAR_REGISTERS;
	end
//-----------------------------------------	
	`CU_WAIT_CLEAR_REGISTERS:
	begin

		oCodeInstructioPointer	= `ENTRYPOINT_INDEX_INITIAL; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0; 	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;
      oTriggerTFF             = 0;		
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 1; 
		oFlipMem						= 0;
		oDone                   = 0;	
		oResultCommited			= 0;
		//oIncCurrentPitch        = 0;
		
		if ( iUCodeDone )
			NextState = `CU_ACK_CLEAR_REGISTERS;
		else
			NextState = `CU_WAIT_CLEAR_REGISTERS;
			
	end
	//-----------------------------------------
	`CU_ACK_CLEAR_REGISTERS:
	begin
	
	`ifdef DEBUG_CU
		$display("%d CU_ACK_CLEAR_REGISTERS\n", $time);
	`endif	
	
	//$display("CORE: %d CU_ACK_CLEAR_REGISTERS", iDebug_CoreID);
	
		//oRamBusOwner 				= 0;
		oCodeInstructioPointer	= 0; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0; //* 	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;		
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0; 
		oFlipMem						= 0;
		oDone                   = 0;	
		oResultCommited			= 0;
		//oIncCurrentPitch        = 0;
		
		NextState = `CU_WAIT_FOR_CONFIG_DATA_READ;
	end	
	
	
	
	//-----------------------------------------
	`CU_WAIT_FOR_CONFIG_DATA_READ:
	begin

		oCodeInstructioPointer	= 0; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0;	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;
      oTriggerTFF             = 0;		
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;  
		oFlipMem						= 0;
		oDone                   = 0;
		oResultCommited			= 0;
		//oIncCurrentPitch        = 0;
		
		if ( MST_I == 0  )
			NextState = `CU_PRECALCULATE_CONSTANTS;
		else
			NextState = `CU_WAIT_FOR_CONFIG_DATA_READ;
		
	end
	//-----------------------------------------
	`CU_PRECALCULATE_CONSTANTS:
	begin
//$display("CORE: %d CU_PRECALCULATE_CONSTANTS", iDebug_CoreID);
	`ifdef DEBUG_CU
		$display("%d Control: CU_PRECALCULATE_CONSTANTS\n", $time);
	`endif
	
		//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	= `ENTRYPOINT_INDEX_CPPU; 
		oGFUEnable 				= 0;
		oUCodeEnable				= 1; //*	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;		
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0; 
		oFlipMem						= 0;	
		oDone                   = 0;	
		oResultCommited			= 0;		
		//oIncCurrentPitch        = 0;
		
		NextState = `CU_WAIT_FOR_CONSTANT;
		
	end
	//-----------------------------------------
	`CU_WAIT_FOR_CONSTANT:
	begin
//	`ifdef DEBUG_CU
//		$display("%d Control: CU_WAIT_FOR_CONSTANT\n", $time);
//	`endif


		//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	= `ENTRYPOINT_INDEX_CPPU; 
		oGFUEnable 				   = 0;
		oUCodeEnable				= 0; //* 	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;		
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;
		oFlipMem						= 0;
		oDone                   = 0;	
		oResultCommited			= 0;	
		//oIncCurrentPitch        = 0;
		
		if ( iUCodeDone )
			NextState = `CU_ACK_PRECALCULATE_CONSTANTS;
		else
			NextState = `CU_WAIT_FOR_CONSTANT;
			
	end
	//-----------------------------------------
	`CU_ACK_PRECALCULATE_CONSTANTS:
	begin
	//$display("CORE: %d CU_ACK_PRECALCULATE_CONSTANTS", iDebug_CoreID);
	`ifdef DEBUG_CU
		$display("%d Control: CU_ACK_PRECALCULATE_CONSTANTS\n", $time);
	`endif
	
	
		//oRamBusOwner 				= 0;//`REG_BUS_OWNED_BY_BCU;
		oCodeInstructioPointer	= 0; 
		oGFUEnable 				   = 0;
		oUCodeEnable				= 0; //* 	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;
		oSetCurrentPitch        = 0;		
		oFlipMemEnabled         = 0;
		oFlipMem						= 0;
		oDone                   = 0;	
		oResultCommited			= 0;	
		//oIncCurrentPitch        = 0;
		
		NextState = `CU_TRIGGER_USERCONSTANTS;//CU_WAIT_FOR_TASK;
		
	end
	//-----------------------------------------

	`CU_TRIGGER_USERCONSTANTS:
	begin
	`ifdef DEBUG_CU
		$display("%d Control: CU_TRIGGER_USERCONSTANTS\n",$time);
	`endif
		
		//$display("CORE: %d CU_TRIGGER_USERCONSTANTS", iDebug_CoreID);
		
		//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	= `ENTRYPOINT_INDEX_USERCONSTANTS; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 1;	//*
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;				
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0; 
		oFlipMem						= 0;
		oDone                   = 0;	
		oResultCommited			= 0;	
		//oIncCurrentPitch        = 0;
		
		NextState = `CU_WAIT_USERCONSTANTS;
	end
	//-----------------------------------------
	`CU_WAIT_USERCONSTANTS:
	begin

//	`ifdef DEBUG_CU
//		$display("%d Control: CU_WAIT_FOR_RGU\n",$time);
//	`endif
	
		//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	= `ENTRYPOINT_INDEX_USERCONSTANTS; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0;	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;
		oSetCurrentPitch        = 0;		
		oFlipMemEnabled         = 0; 
		oFlipMem						= 0;
		oDone                   = 0;	
		oResultCommited			= 0;	
		//oIncCurrentPitch        = 0;
		
		if ( iUCodeDone )
			NextState = `CU_ACK_USERCONSTANTS;
		else
			NextState = `CU_WAIT_USERCONSTANTS;
	end
	//-----------------------------------------
	`CU_ACK_USERCONSTANTS:
	begin
	
	`ifdef DEBUG_CU
		$display("%d Control: CU_ACK_RGU\n",$time);
	`endif
	
	//$display("CORE: %d CU_ACK_USERCONSTANTS", iDebug_CoreID);
	
		//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	= 0; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0; //*	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;			
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;  
		oFlipMem						= 0;
		oDone                   = 0;	
		oResultCommited			= 0;	
		//oIncCurrentPitch        = 0;
	
		if ( iUCodeDone  == 0)
			NextState = `CU_WAIT_FOR_RENDER_ENABLE;
		else
			NextState = `CU_ACK_USERCONSTANTS;
		
	end
	//-----------------------------------------
	`CU_WAIT_FOR_RENDER_ENABLE:
	begin
	`ifdef DEBUG_CU
	$display("CORE: %d CU_WAIT_FOR_RENDER_ENABLE", iDebug_CoreID);
	`endif
		//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	= 0; 
		oGFUEnable 					= 0;
		oUCodeEnable				= 0; //*	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;			
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;  
		oFlipMem						= 0;
		oDone                   = 0;	
		oResultCommited			= 0;	
		//oIncCurrentPitch        = 0;
	
		if ( iRenderEnable)
			NextState = `CU_WAIT_FOR_HOST_DATA_AVAILABLE;//`CU_TRIGGER_RGU;
		else
			NextState = `CU_WAIT_FOR_RENDER_ENABLE;
	end
	//-----------------------------------------
	`CU_WAIT_FOR_HOST_DATA_ACK:
	begin
	   oCodeInstructioPointer	= 0;
		oUCodeEnable				= 0;
		oGFUEnable					= 0;	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;
		oTriggerTFF             = 0;      
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;
		oFlipMem						= 0;
		oDone                   = 0;		
		oResultCommited			= 0;
		
		if ( iHostAckDataRead )
			NextState = `CU_WAIT_FOR_HOST_DATA_AVAILABLE;
		else
			NextState = `CU_WAIT_FOR_HOST_DATA_ACK;
	end
	//-----------------------------------------
	//Wait until data from Host becomes available
	`CU_WAIT_FOR_HOST_DATA_AVAILABLE:
	begin
		//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	= 0;
		oUCodeEnable				= 0;
		oGFUEnable					= 0;	
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;
		oTriggerTFF             = 0;      
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;
		oFlipMem						= 0;
		oDone                   = 0;		
		oResultCommited			= 0;
		
		if ( iHostDataAvailable )
			NextState = `CU_TRIGGER_MAIN;
		else
			NextState = `CU_WAIT_FOR_HOST_DATA_AVAILABLE;
			
		
	end
	//-----------------------------------------
	`CU_TRIGGER_MAIN:
	begin
	`ifdef DEBUG_CU
		$display("%d CORE: %d Control: CU_TRIGGER_MAIN\n",$time,iDebug_CoreID);
	`endif
			
			//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
			oCodeInstructioPointer	= `ENTRYPOINT_INDEX_MAIN;
			oUCodeEnable				= 1;
			oGFUEnable					= 1;
			oIOWritePixel				= 0;
			rResetHitFlop				= 0;	
			rHitFlopEnable				= 0;		
         oTriggerTFF             = 0;					
			oSetCurrentPitch        = 0;
			oFlipMemEnabled         = 1;  
			oFlipMem						= 1;
			oDone                   = 0;	
			oResultCommited			= 0;	
			////$display("\n\n %d XOXOXOXOX FLIP XOXOXOXOXOX\n\n",$time);
			//oIncCurrentPitch        = 0;
		//	$stop();
			
			NextState = `CU_WAIT_FOR_MAIN;
		
	end
	//-----------------------------------------
	`CU_WAIT_FOR_MAIN:
	begin
//	`ifdef DEBUG_CU
//		$display("%d Control: CU_WAIT_FOR_MAIN\n",$time);
//	`endif
	
			//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
			oCodeInstructioPointer	= `ENTRYPOINT_INDEX_MAIN;
			oUCodeEnable				= 0;
			oGFUEnable					= 1;
			oIOWritePixel				= 0;
			rResetHitFlop				= 0;	
			rHitFlopEnable				= 1;	
         oTriggerTFF             = 0;
			oSetCurrentPitch        = 0;	
			oFlipMemEnabled         = 1;  
			oFlipMem						= 0;
			oDone                   = 0;	
			oResultCommited			= 0;	
			//oIncCurrentPitch        = 0;
			
			//NextState = `CU_WAIT_FOR_MAIN;
	
	
		if ( iUCodeDone )
			NextState = `CU_ACK_MAIN;
		else
			NextState = `CU_WAIT_FOR_MAIN;
			
	end
	//-----------------------------------------
	/*
		ACK UCODE by setting oUCodeEnable = 0
	*/
	`CU_ACK_MAIN:
	begin
	`ifdef DEBUG_CU
		$display("%d CORE: %d Control: CU_ACK_MAIN\n",$time, iDebug_CoreID);
	`endif
	
			//oRamBusOwner 				= `REG_BUS_OWNED_BY_GFU;
			oCodeInstructioPointer	= 0; //*
			oUCodeEnable				= 0;	//*
			oGFUEnable					= 0; 
			oIOWritePixel				= 0;
			rResetHitFlop				= 0;
			rHitFlopEnable				= 1;			
         oTriggerTFF             = 0;					
			oSetCurrentPitch        = 0;
			oFlipMemEnabled         = 0;  
			oFlipMem						= 0;
			oDone                   = 0;
			oResultCommited			= 0;
	
		if (iUCodeDone == 1'b0 && iUCodeReturnValue == 0)
			NextState = `CU_WAIT_FOR_HOST_DATA_AVAILABLE;
		else if (iUCodeDone == 1'b0 && iUCodeReturnValue == 1)
         NextState = `CU_COMMIT_PIXEL_RESULT;
		else
			NextState = `CU_ACK_MAIN;
		
	end
	//-----------------------------------------
	`CU_COMMIT_PIXEL_RESULT:
	begin
		oCodeInstructioPointer	= 0;
		oUCodeEnable				= 0;
		oGFUEnable					= 0;
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
		oTriggerTFF             = 0;		
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;
		oFlipMem						= 0;		
		oDone                   = 0;
		oResultCommited			= 1;
		
		
		NextState = `CU_WAIT_FOR_HOST_DATA_AVAILABLE;
	end	
	//-----------------------------------------
	//-----------------------------------------
	`CU_DONE:
	begin
		//oRamBusOwner 				= `REG_BUS_OWNED_BY_UCODE;
		oCodeInstructioPointer	= 0;	
		oUCodeEnable				= 0;	
		oGFUEnable					= 0;
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;		
      oTriggerTFF             = 0;				
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;  
		oFlipMem						= 1;
		oDone                   = 1;
		oResultCommited			= 0;
		//oIncCurrentPitch        = 0;
		
		
		NextState = `CU_DONE;
				
	end
	//---------------------------------------------------
	default:
	begin
	
	`ifdef DEBUG_CU
		$display("%d Control: ERROR Undefined State\n",$time);
	`endif
	
		//oRamBusOwner 				= 0;
		oCodeInstructioPointer	= 0;	
		oUCodeEnable				= 0;
		oGFUEnable					= 0;		
		oIOWritePixel				= 0;
		rResetHitFlop				= 0;	
		rHitFlopEnable				= 0;	
      oTriggerTFF             = 0;				
		oSetCurrentPitch        = 0;
		oFlipMemEnabled         = 0;  
		oFlipMem						= 0;
		oDone                   = 0;
		oResultCommited			= 0;
		//oIncCurrentPitch        = 0;
		
		NextState = `CU_AFTER_RESET_STATE;
	end
	//-----------------------------------------

	endcase
	
end //always	
endmodule
