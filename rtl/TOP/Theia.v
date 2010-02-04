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
 This is the top level block for THEIA.
 THEIA core has 5 main logical blocks called Units.
 This module implements the interconections between the Units.
 
 Units:
  > EXE: Mananges execution logic for the SHADERS.
  > GEO: Manages geometry data structures.
  > IO: Input/Output (Wishbone).
  > MEM: Internal memory, separate for Instructions and data.
  > CONTROL: Main control Finite state machine.
  
 Internal Buses: 
	THEIA has separate instruction and data buses.
	THEIA avoids using tri-state buses by having separate input/output
	for each bus. 
	There are 2 separate data buses since the Data memory 
	has a Dual read channel.
   Please see the MEM unit chapter in the documentation for more details.
 
 External Buses:
	External buses are managed by the IO Unit.
	External buses follow the wishbone protocol.
	Please see the IO unit chapter in the documentation for more details.
**********************************************************************************/

`timescale 1ns / 1ps
`include "aDefinitions.v"

module THEIACORE
(

input wire                    CLK_I,	//Input clock
input wire                    RST_I,	//Input reset
//Theia Interfaces
input wire                    MST_I,	//Master signal, THEIA enters configuration mode
                                       //when this gets asserted (see documentation)
//Wish Bone Interface
input wire [`WB_WIDTH-1:0]    DAT_I,	//Input data bus  (Wishbone)
output wire [`WB_WIDTH-1:0]   DAT_O,	//Output data bus (Wishbone)
input wire                    ACK_I,	//Input ack
output wire                   ACK_O,	//Output ack
output wire [`WB_WIDTH-1:0]   ADR_O,	//Output address
input wire [`WB_WIDTH-1:0]    ADR_I,	//Input address
output wire                   WE_O,		//Output write enable
input wire                    WE_I,    //Input write enable
output wire                   STB_O,	//Strobe signal, see wishbone documentation
input wire                    STB_I,	//Strobe signal, see wishbone documentation
output wire                   CYC_O,	//Bus cycle signal, see wishbone documentation
input wire                    CYC_I,   //Bus cycle signal, see wishbone documentation
output wire	[1:0]             TGC_O,   //Bus cycle tag, see THEAI documentation
input wire [1:0]              TGA_I,   //Input address tag, see THEAI documentation
output wire [1:0]             TGA_O,   //Output address tag, see THEAI documentation
input wire	[1:0]             TGC_I,   //Bus cycle tag, see THEAI documentation
//Control Register
input wire [15:0]		         CREG_I

);

//Alias this signals
wire Clock,Reset;
assign Clock = CLK_I;
assign Reset = RST_I;

wire [`DATA_ROW_WIDTH-1:0]			 wEXE_2__MEM_WriteData;
wire [`DATA_ROW_WIDTH-1:0]			 wUCODE_RAMBus;
wire [`DATA_ADDRESS_WIDTH-1:0]	 wEXE_2__MEM_wDataWriteAddress;
wire                              w2IO__AddrIsImm;
wire [`DATA_ADDRESS_WIDTH-1:0]	 wUCODE_RAMAddress;
wire [`DATA_ADDRESS_WIDTH-1:0]    w2IO__Adr_O_Pointer;
wire [`DATA_ADDRESS_WIDTH-1:0]    wGEO2_IO__Adr_O_Pointer;
wire 										 wEXE_2__DataWriteEnable;
wire 										 wUCODE_RAMWriteEnable;
wire [2:0]								 RamBusOwner;
//Unit intercoanection wires

wire 										wCU2__MicrocodeExecutionDone;
wire [`ROM_ADDRESS_WIDTH-1:0]		InitialCodeAddress; 
wire [`ROM_ADDRESS_WIDTH-1:0]		wInstructionPointer1,wInstructionPointer2;
wire [`INSTRUCTION_WIDTH-1:0] 	wEncodedInstruction1,wEncodedInstruction2,wIO2_MEM__ExternalInstruction;
wire			 							wCU2__ExecuteMicroCode;
wire  [`ROM_ADDRESS_WIDTH-1:0]   wIO2_MEM__InstructionWriteAddr;
wire [95:0] 							wMEM_2__EXE_DataRead0, wMEM_2__EXE_DataRead1,wMEM_2__IO_DataRead0, wMEM_2__IO_DataRead1; 				
wire [`DATA_ADDRESS_WIDTH-1:0]	wEXE_2__MEM_DataReadAddress0,wEXE_2__MEM_DataReadAddress1; 			
wire [`DATA_ADDRESS_WIDTH-1:0]	wUCODE_RAMReadAddress0,wUCODE_RAMReadAddress1;


wire [`WIDTH-1:0] 					w2IO__AddressOffset;
wire [`DATA_ADDRESS_WIDTH-1:0] 	w2IO__DataWriteAddress;
wire 										w2IO__Store;
wire 										w2IO__EnableWBMaster;

wire [`DATA_ADDRESS_WIDTH-1:0] 	wIO2_MEM__DataWriteAddress;
wire [`DATA_ADDRESS_WIDTH-1:0] 	wIO_2_MEM__DataReadAddress0;
wire [`DATA_ROW_WIDTH-1:0] 		wIO2_MEM__Bus;
wire [`WIDTH-1:0] 					wIO2_MEM__Data;
wire [`WIDTH-1:0] 					wIO2_WBM__Address;
wire 										wIO2_MEM__DataWriteEnable;
wire 										wIO2__Done;
wire 										wCU2_GEO__GeometryFetchEnable;
wire 										wIFU2__MicroCodeReturnValue;
wire 										wCU2_BCU__ACK;
wire 										wGEO2_CU__RequestAABBIU;
wire 										wGEO2_CU__RequestBIU;
wire                             wGEO2_CU__RequestTCC;
wire										wGEO2_CU__GeometryUnitDone;
wire										wGEO2_CU__Sync;
wire 										wEXE2__uCodeDone;
wire										wEXE2_IFU__EXEBusy;
wire [`DATA_ADDRESS_WIDTH-1:0]	wEXE2_IDU_DataFordward_LastDestination;
wire 										wALU2_EXE__BranchTaken;
wire 										wALU2_IFU_BranchNotTaken;
wire										w2IO__SetAddress;
wire										wIDU2_IFU__IDUBusy;
//Control Registe wires
wire[15:0]								wCR2_ControlRegister;
wire										wCR2_TextureMappingEnabled;
wire                             wGEO2_CU__TFFDone;
wire                             wCU2_GEO__TriggerTFF;
wire                             wIO2_MEM_InstructionWriteEnable;
wire                             wCU2_IO__WritePixel;
wire                             wGEO2_IO__AddrIsImm;
wire[31:0]                       wGEO2_IO__AddressOffset;
wire                             wGEO2_IO__EnableWBMaster;
wire                             wGEO2_IO__SetAddress;
wire[`WIDTH-1:0]                 wGEO2__CurrentPitch,wCU2_GEO_Pitch; 
wire                             wCU2_GEO__SetPitch,wCU2_GEO__IncPicth;
wire wCU2_FlipMemEnabled;
wire w2MEM_FlipMemory;

`ifdef DEBUG
	wire [`ROM_ADDRESS_WIDTH-1:0] wDEBUG_IDU2_EXE_InstructionPointer;
`endif
//--------------------------------------------------------


/*	
	///////////////// TODO CHANGE FOR MUXES ////////////////////////////////
	assign wEXE_2__MEM_WriteData = ( RamBusOwner == `REG_BUS_OWNED_BY_UCODE ) ?
		wUCODE_RAMBus : `DATA_ROW_WIDTH'bz;
		
	assign wEXE_2__MEM_WriteData = ( RamBusOwner == `REG_BUS_OWNED_BY_GFU || MST_I == 1'b1) ?
		wIO2_MEM__Bus : `DATA_ROW_WIDTH'bz;
			
	assign wEXE_2__MEM_wDataWriteAddress = ( RamBusOwner == `REG_BUS_OWNED_BY_UCODE ) ?
		wUCODE_RAMAddress : `DATA_ADDRESS_WIDTH'bz;		
		
	assign wEXE_2__MEM_wDataWriteAddress = ( RamBusOwner == `REG_BUS_OWNED_BY_GFU || MST_I == 1'b1) ?
	wIO2_MEM__DataWriteAddress : `DATA_ADDRESS_WIDTH'bz;
	
	
	 MUXFULLPARALELL_2SEL_GENERIC # ( `DATA_ADDRESS_WIDTH ) MUX_RA0
	(
 .Sel(RamBusOwner[1:0]),
 .I1(`DATA_ADDRESS_WIDTH'b0),
 .I2(wIO_2_MEM__DataReadAddress0),
 .I3(wUCODE_RAMReadAddress0),
 .O1(wEXE_2__MEM_DataReadAddress0)
 );

		
		
		

  
assign wEXE_2__DataWriteEnable  = ( RamBusOwner == `REG_BUS_OWNED_BY_UCODE && MST_I == 1'b0) ?
		wUCODE_RAMWriteEnable : 1'bz;	 
  
assign wEXE_2__DataWriteEnable  = ( RamBusOwner == `REG_BUS_OWNED_BY_GFU || MST_I == 1'b1) ?
		wIO2_MEM__DataWriteEnable : 1'bz;
*/
assign wCR2_TextureMappingEnabled = wCR2_ControlRegister[ `CR_EN_TEXTURE ];
wire wCU2_FlipMem;
//--------------------------------------------------------
//Control Unit Instance
	ControlUnit CU
	(
	   .Clock(Clock), 
		.Reset(Reset), 
		.oFlipMemEnabled(                   wCU2_FlipMemEnabled            ),
		.oFlipMem(                          wCU2_FlipMem                   ),
		.iControlRegister(                  wCR2_ControlRegister           ),
		.oRamBusOwner(                      RamBusOwner                    ),
		.oGFUEnable(                        wCU2_GEO__GeometryFetchEnable  ),
		.iTriggerAABBIURequest(             wGEO2_CU__RequestAABBIU        ),
		.iTriggerBIURequest(                wGEO2_CU__RequestBIU           ),
		.iTriggertTCCRequest(               wGEO2_CU__RequestTCC           ),
		.oUCodeEnable(                      wCU2__ExecuteMicroCode         ),
		.oCodeInstructioPointer(           InitialCodeAddress             ),
		.iUCodeDone(                        wCU2__MicrocodeExecutionDone   ),
		.iIODone(                           wIO2__Done                     ),
		.oIOWritePixel(                     wCU2_IO__WritePixel            ),
		.iUCodeReturnValue(                 wIFU2__MicroCodeReturnValue    ),
		.iGEOSync(                          wGEO2_CU__Sync                 ),
		.iTFFDone(                          wGEO2_CU__TFFDone              ),
		.oTriggerTFF(                       wCU2_GEO__TriggerTFF           ),
		.MST_I(                             MST_I                          ),
		.oSetCurrentPitch(                  wCU2_GEO__SetPitch             ),
		.iGFUDone(                          wGEO2_CU__GeometryUnitDone     )
		
	);
	
	

	
//--------------------------------------------------------	

//assign w2MEM_FlipMemory =  (wCU2__ExecuteMicroCode | wCU2_FlipMem ) & wCU2_FlipMemEnabled;
assign w2MEM_FlipMemory =  wCU2_FlipMem  & wCU2_FlipMemEnabled;
MemoryUnit MEM
(
.Clock(Clock), 
.Reset(Reset),

.iFlipMemory( w2MEM_FlipMemory ),

//Data Bus to/from EXE
.iDataReadAddress1_EXE(       wEXE_2__MEM_DataReadAddress0        ),
.iDataReadAddress2_EXE(       wEXE_2__MEM_DataReadAddress1        ),
.oData1_EXE(                  wMEM_2__EXE_DataRead0               ),
.oData2_EXE(                  wMEM_2__EXE_DataRead1               ),
.iDataWriteEnable_EXE(        wEXE_2__DataWriteEnable          ),
.iDataWriteAddress_EXE(       wEXE_2__MEM_wDataWriteAddress        ),
.iData_EXE(                   wEXE_2__MEM_WriteData          ),

//Data Bus to/from IO

.iDataReadAddress1_IO(       wIO_2_MEM__DataReadAddress0        ),
.iDataReadAddress2_IO(       wIO_2_MEM__DataReadAddress1        ),
.oData1_IO(                  wMEM_2__IO_DataRead0               ),
.oData2_IO(                  wMEM_2__IO_DataRead1               ),
.iDataWriteEnable_IO(        wIO2_MEM__DataWriteEnable          ),
.iDataWriteAddress_IO(       wIO2_MEM__DataWriteAddress        ),
.iData_IO(                   wIO2_MEM__Bus          ),


//Instruction Bus
.iInstructionReadAddress1(  wInstructionPointer1             ),
.iInstructionReadAddress2(  wInstructionPointer2             ),
.oInstruction1(             wEncodedInstruction1             ),
.oInstruction2(             wEncodedInstruction2             ),
.iInstructionWriteEnable(  wIO2_MEM_InstructionWriteEnable ), 
.iInstructionWriteAddress( wIO2_MEM__InstructionWriteAddr  ),
.iInstruction(             wIO2_MEM__ExternalInstruction   ),
.iControlRegister(         CREG_I                          ),
.oControlRegister(         wCR2_ControlRegister            )

);

////--------------------------------------------------------
  

ExecutionUnit EXE
(

.Clock( Clock),
.Reset( Reset ),
.iInitialCodeAddress(    InitialCodeAddress     ), 
.iInstruction1(          wEncodedInstruction1      ),
.iInstruction2(          wEncodedInstruction2      ),
.oInstructionPointer1(   wInstructionPointer1    ),
.oInstructionPointer2(   wInstructionPointer2    ),
.iDataRead0(             wMEM_2__EXE_DataRead0             ), 
.iDataRead1(             wMEM_2__EXE_DataRead1             ), 				
.iTrigger(               wCU2__ExecuteMicroCode ),
.oDataReadAddress0( wEXE_2__MEM_DataReadAddress0 ),
.oDataReadAddress1( wEXE_2__MEM_DataReadAddress1 ),
.oDataWriteEnable(  wEXE_2__DataWriteEnable  ),
.oDataWriteAddress( wEXE_2__MEM_wDataWriteAddress      ),
.oDataBus(          wEXE_2__MEM_WriteData          ), 
.oReturnCode(       wIFU2__MicroCodeReturnValue ),
.oDone(             wCU2__MicrocodeExecutionDone )

);

////--------------------------------------------------------
wire wGEO2__RequestingTextures;
wire w2IO_WriteBack_Set;

GeometryUnit GEO
(
		.Clock( Clock ),
		.Reset( Reset ),
		.iEnable(                     wCU2_GEO__GeometryFetchEnable       ),
		.iTexturingEnable(            wCR2_TextureMappingEnabled          ),
		//Wires from IO
		.iData_WBM( 						wIO2_MEM__Data ),		
		.iDataReady_WBM( 					wIO2__Done ),
		//Wires to WBM
		.oAddressWBM_Imm( 				wGEO2_IO__AddressOffset					),
		.oAddressWBM_fromMEM(         wGEO2_IO__Adr_O_Pointer             ),
		.oAddressWBM_IsImm(           wGEO2_IO__AddrIsImm                 ),
		.oEnable_WBM( 						wGEO2_IO__EnableWBMaster				),
		.oSetAddressWBM(					wGEO2_IO__SetAddress						),
		.oSetIOWriteBackAddr(         w2IO_WriteBack_Set                  ),
		//Wires to CU
		.oRequest_AABBIU(             wGEO2_CU__RequestAABBIU                ),
		.oRequest_BIU(                wGEO2_CU__RequestBIU                   ),
		.oRequest_TCC(                wGEO2_CU__RequestTCC                   ),
		.oTFFDone(                    wGEO2_CU__TFFDone                      ),
		//Wires to RAM-Bus MUX	
		.oRAMWriteAddress( 				w2IO__DataWriteAddress 					),
		.oRAMWriteEnable( 				w2IO__Store ),
		//Wires from Execution Unit
		.iMicrocodeExecutionDone( 		wCU2__MicrocodeExecutionDone 				),
		.iMicroCodeReturnValue( 		wIFU2__MicroCodeReturnValue 				),
		.oSync(								wGEO2_CU__Sync									),
		.iTrigger_TFF(                wCU2_GEO__TriggerTFF                   ),
		.iBIUHit(                     wIFU2__MicroCodeReturnValue            ),
		.oRequestingTextures( wGEO2__RequestingTextures ),
		.oDone(								wGEO2_CU__GeometryUnitDone					)
);


assign TGA_O = (wGEO2__RequestingTextures) ? 2'b1: 2'b0;
//---------------------------------------------------------------------------------------------------
wire[`DATA_ADDRESS_WIDTH-1:0] wIO_2_MEM__DataReadAddress1;
assign wEXE_2__MEM_DataReadAddress1 = (wCU2_IO__WritePixel == 0) ?  wUCODE_RAMReadAddress1 : wIO_2_MEM__DataReadAddress1;
assign w2IO__EnableWBMaster = (wCU2_IO__WritePixel == 0 ) ? wGEO2_IO__EnableWBMaster : wCU2_IO__WritePixel;
assign w2IO__AddrIsImm       = (wCU2_IO__WritePixel == 0 ) ? wGEO2_IO__AddrIsImm       : 1'b1;
assign w2IO__AddressOffset   = (wCU2_IO__WritePixel == 0 ) ? wGEO2_IO__AddressOffset   : 32'b0;
assign w2IO__Adr_O_Pointer      = (wCU2_IO__WritePixel == 0 ) ? wGEO2_IO__Adr_O_Pointer : `OREG_PIXEL_PITCH;
wire w2IO_MasterCycleType;
assign w2IO_MasterCycleType = (wCU2_IO__WritePixel) ? `WB_SIMPLE_WRITE_CYCLE : `WB_SIMPLE_READ_CYCLE;



assign w2IO__SetAddress = (wCU2_IO__WritePixel == 0 )? wGEO2_IO__SetAddress : wCU2_GEO__SetPitch;


IO_Unit IO
(
 .Clock(               Clock                            ),
 .Reset(               Reset                            ),
 .iEnable(            w2IO__EnableWBMaster              ),
 .iBusCyc_Type(         w2IO_MasterCycleType            ),      
  
 .iStore(              w2IO__Store                      ),
 .iAdr_DataWriteBack(    w2IO__DataWriteAddress         ),
 .iAdr_O_Set(      w2IO__SetAddress                     ),
 .iAdr_O_Imm(       w2IO__AddressOffset                 ),
 .iAdr_O_Type(      w2IO__AddrIsImm                     ),
 .iAdr_O_Pointer(  w2IO__Adr_O_Pointer                  ),
 .iReadDataBus(        wMEM_2__IO_DataRead0                       ), 
 .iReadDataBus2(        wMEM_2__IO_DataRead1                       ), 
 .iDat_O_Pointer(     `OREG_PIXEL_COLOR                 ),
 
 
 .oDataReadAddress(    wIO_2_MEM__DataReadAddress0      ),
 .oDataReadAddress2(   wIO_2_MEM__DataReadAddress1       ),
 .oDataWriteAddress(   wIO2_MEM__DataWriteAddress    ),
 .oDataBus(       	  wIO2_MEM__Bus                 ),
 .oInstructionBus(     wIO2_MEM__ExternalInstruction    ),
 
 .oDataWriteEnable(         wIO2_MEM__DataWriteEnable    ),
 .oData(                    wIO2_MEM__Data                       ),
 .oInstructionWriteEnable(  wIO2_MEM_InstructionWriteEnable ),
 .oInstructionWriteAddress( wIO2_MEM__InstructionWriteAddr ),
 .iWriteBack_Set( w2IO_WriteBack_Set ),
 
 .oDone(               wIO2__Done                       ),
 .MST_I( MST_I ),
  //Wish Bone Interface
.DAT_I( DAT_I ),
.DAT_O( DAT_O ),
.ACK_I( ACK_I ),
.ACK_O( ACK_O ),
.ADR_O( ADR_O ),
.ADR_I( ADR_I ),
.WE_O(  WE_O  ),
.WE_I(  WE_I  ),
.STB_O( STB_O ),
.STB_I( STB_I ),
.CYC_O( CYC_O ),
.TGA_I( TGA_I ),
.CYC_I( CYC_I ),
.TGC_O( TGC_O )


);
//---------------------------------------------------------------------------------------------------
endmodule
