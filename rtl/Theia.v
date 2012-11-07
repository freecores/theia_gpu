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

module THEIA
(
	input wire         Clock,
	input wire         Reset,
	input wire         iEnable,
	input wire [31:0]  iMemReadData,				//Data read from Main memory
	input wire         iMemDataAvailable,
	output wire [31:0] oMemReadAddress,
	output wire        oMEM_ReadRequest,
	
input wire [`WB_WIDTH-1:0]           TMDAT_I,
input wire [`WB_WIDTH-1:0]           TMADR_I,
input wire                           TMWE_I,
input wire [`MAX_TMEM_BANKS-1:0]     TMSEL_I

);


wire [`WB_WIDTH-1:0]              wMCU_2_VP_InstructionWriteAddress;
wire  [`WB_WIDTH-1:0]             wMCU_2_VP_InstructionWriteData;
wire   [`MAX_CORES-1:0]           wMCU_2_VP_InstructionWriteEnable;
wire [`MCU_TAG_SIZE-1:0]          wMCU_2_VP_Tag;
wire                              wMCU_2_VP_STB;
wire                              wMCU_2_VP_Cyc;
wire                              wMCU_2_VP_Mst;
wire  [`MAX_CORES-1:0]            wVP_2_MCU_ACK;
wire                              wVP_Slave_ACK;
wire [`MCU_REQUEST_SIZE-1:0]      wCP_2MCU_BlockCopyCommand;
wire[`CBC_BUS_WIDTH-1:0]          wCP_VP__ControlCommandBus;
wire                              wMCU_2_CP__FIFOEmpty;
wire                              wOMem_WE[`MAX_CORES-1:0];
wire [`WB_WIDTH-1:0]              wOMEM_Address[`MAX_CORES-1:0];
wire [`WB_WIDTH-1:0]              wOMEM_Dat[`MAX_CORES-1:0];




//CROSS-BAR wires


wire [`MAX_TMEM_BANKS-1:0]                                 wTMemWriteEnable;
wire [(`MAX_TMEM_BANKS*`WB_WIDTH)-1:0]                     wCrossBarDataRow;                                     //Horizontal grid Buses comming from each bank 
wire [(`MAX_CORES*`WB_WIDTH)-1:0]                          wCrossBarDataCollumn;                                 //Vertical grid buses comming from each core.
wire [(`MAX_CORES*`WB_WIDTH)-1:0]                          wCrossBarAdressCollumn;                               //Vertical grid buses comming from each core. (physical addr).
wire [`WB_WIDTH-1:0]                                       wTMemReadAdr[`MAX_CORES-1:0];                         //Horizontal grid Buses comming from each core (virtual addr).
wire [`WB_WIDTH-1:0]                                       wCrossBarAddressRow[`MAX_TMEM_BANKS-1:0];             //Horizontal grid Buses comming from each bank.
wire                                                       wCORE_2_TMEM__Req[`MAX_CORES-1:0];
wire [`MAX_TMEM_BANKS -1:0]                                wBankReadRequest[`MAX_CORES-1:0];    
wire [`MAX_CORES-1:0]                                      wBankReadGranted[`MAX_TMEM_BANKS-1:0];    
wire                                                       wTMEM_2_Core__Grant[`MAX_CORES-1:0];
wire[`MAX_CORE_BITS-1:0]                                   wCurrentCoreSelected[`MAX_TMEM_BANKS-1:0];
wire[`WIDTH-1:0]                                           wCoreBankSelect[`MAX_CORES-1:0];






//////////////////////////////////////////////
//
// The control processor
//
//////////////////////////////////////////////
ControlProcessor CP 
(
		.Clock(               Clock                     ), 
		.Reset(               Reset                     ), 
		.oControlBus(         wCP_VP__ControlCommandBus ),
		.iMCUFifoEmpty(       wMCU_2_CP__FIFOEmpty      ),
		.oCopyBlockCommand(   wCP_2MCU_BlockCopyCommand )
);

//////////////////////////////////////////////
//
// The control processor
//
//////////////////////////////////////////////
assign wVP_Slave_ACK = wVP_2_MCU_ACK[0] | wVP_2_MCU_ACK[1] | wVP_2_MCU_ACK[2] | wVP_2_MCU_ACK[3];

MemoryController #(`MAX_CORES) MCU
(
		.Clock(                  Clock                             ), 
		.Reset(                  Reset                             ), 
		.iRequest(               wCP_2MCU_BlockCopyCommand         ),
		.oMEM_ReadAddress(       oMemReadAddress                   ),
		.oMEM_ReadRequest(       oMEM_ReadRequest                  ),
		.oFifoEmpty(             wMCU_2_CP__FIFOEmpty              ),
		.iMEM_ReadData(          iMemReadData                      ),
		.iMEM_DataAvailable(     iMemDataAvailable                 ),
		.DAT_O(                  wMCU_2_VP_InstructionWriteData    ),
		.ADR_O(                  wMCU_2_VP_InstructionWriteAddress ),
		.STB_O(                  wMCU_2_VP_STB                     ),
		.WE_O(                   wMCU_2_VP_InstructionWriteEnable  ),
		.TAG_O(                  wMCU_2_VP_Tag                     ),
		.CYC_O(                  wMCU_2_VP_Cyc                     ),
		.MST_O(                  wMCU_2_VP_Mst                     ),
		.ACK_I(                  wVP_Slave_ACK                     )
);

//////////////////////////////////////////////
//
// The vector processors
//
//////////////////////////////////////////////
genvar i;
  generate
	for (i = 0; i < `MAX_CORES; i = i +1)
	begin : VPX
	
	VectorProcessor VP 
	(
		.Clock(           Clock                                          ), 
		.Reset(           Reset                                          ), 
		.iEnable(         iEnable                                        ),
		.iVPID(           i+1                                            ),
		.iCpCommand(      wCP_VP__ControlCommandBus                      ),
		.MCU_STB_I(       wMCU_2_VP_STB                                  ),
      .MCU_WE_I(        wMCU_2_VP_InstructionWriteEnable[i]            ),
      .MCU_DAT_I(       wMCU_2_VP_InstructionWriteData                 ),
      .MCU_ADR_I(       wMCU_2_VP_InstructionWriteAddress              ),
      .MCU_TAG_I(       wMCU_2_VP_Tag                                  ),
      .MCU_ACK_O(       wVP_2_MCU_ACK[i]                               ),
      .MCU_MST_I(       wMCU_2_VP_Mst                                  ),
      .MCU_CYC_I(       wMCU_2_VP_Cyc                                  ),
		.OMEM_WE(         wOMem_WE[i]                                    ),
		.OMEM_ADDR(       wOMEM_Address[i]                               ),
		.OMEM_DATA(       wOMEM_Dat[i]                                   ),
		.TMEM_DAT_I( wCrossBarDataCollumn[ (i*`WB_WIDTH)+:`WB_WIDTH ]    ), 
      .TMEM_ADR_O( wTMemReadAdr[i]                                     ),
      .TMEM_CYC_O( wCORE_2_TMEM__Req[i]                                ),
      .TMEM_GNT_I( wTMEM_2_Core__Grant[i]                              )

	
	);
	//////////////////////////////////////////////
	//
	// The OMEM
	//
	//////////////////////////////////////////////
	
	RAM_SINGLE_READ_PORT # ( `WB_WIDTH, `WB_WIDTH, `OMEM_SIZE ) OMEM 
	(
	  .Clock(         Clock                ),
	  .iWriteEnable(  wOMem_WE[i]          ),
	  .iWriteAddress( wOMEM_Address[i]     ),
	  .iDataIn(       wOMEM_Dat[i]         ),
	  .iReadAddress0( wOMEM_Address[i]     )
	  
	  
	);
	
	
	MUXFULLPARALELL_GENERIC # (`WB_WIDTH,`MAX_TMEM_BANKS,`MAX_TMEM_BITS) MUXG1
		(
		.in_bus( wCrossBarDataRow ),
		.sel( wCoreBankSelect[ i ][0+:`MAX_TMEM_BITS] ),
		.out( wCrossBarDataCollumn[ (i*`WB_WIDTH)+:`WB_WIDTH ] )
		);

	//If there are "n" banks, memory location "X" would reside in bank number X mod n.
	//X mod 2^n == X & (2^n - 1)
	assign wCoreBankSelect[i] = (wTMemReadAdr[i] & (`MAX_TMEM_BANKS-1));

	//Each core has 1 bank request slot
	//Each slot has MAX_TMEM_BANKS bits. Only 1 bit can
	//be 1 at any given point in time. All bits zero means,
	//we are not requesting to read from any memory bank.
	SELECT_1_TO_N # ( `WIDTH, `MAX_TMEM_BANKS ) READDRQ
			(
			.Sel(wCoreBankSelect[ i]),
			.En(wCORE_2_TMEM__Req[i]),
			.O(wBankReadRequest[i])
			);

	//The address coming from the core is  virtual adress, meaning it assumes linear
	//address space, however, since memory is interleaved in a n-way memory we transform
	//virtual adress into physical adress (relative to the bank) like this
	//fadr = vadr / n = vadr >> log2(n)

	assign wCrossBarAdressCollumn[(i*`WB_WIDTH)+:`WB_WIDTH] = (wTMemReadAdr[i] >> `MAX_CORE_BITS);

	//Connect the granted signal to Arbiter of the Bank we want to read from  
	assign wTMEM_2_Core__Grant[i] = wBankReadGranted[wCoreBankSelect[i]][i];

	end // for
endgenerate








////////////// CROSS-BAR INTERCONECTION//////////////////////////


 SELECT_1_TO_N # ( `MAX_TMEM_BANKS, `MAX_TMEM_BANKS ) TMWE_SEL
 (
      .Sel(TMSEL_I),
      .En(TMWE_I),
      .O(wTMemWriteEnable)
  );

genvar Core,Bank;
generate
for (Bank = 0; Bank < `MAX_TMEM_BANKS; Bank = Bank + 1)
begin : BANK

  //The memory bank itself
  
RAM_SINGLE_READ_PORT   # ( `WB_WIDTH, `WB_WIDTH, 50000 ) TMEM 
  (
  .Clock(         Clock                      ),
  .iWriteEnable(  wTMemWriteEnable[Bank]       ),
  .iWriteAddress( TMADR_I                      ),
  .iDataIn(       TMDAT_I                      ),
  .iReadAddress0( wCrossBarAddressRow[Bank]    ),  //Connect to the Row of the grid
  .oDataOut0(     wCrossBarDataRow[(`WB_WIDTH*Bank)+:`WB_WIDTH]       )  //Connect to the Row of the grid
  
  );
  
  //Arbiter will Round-Robin Cores attempting to read from the same Bank
  //at a given point in time
wire [`MAX_CORES-1:0]         wBankReadGrantedDelay[`MAX_TMEM_BANKS-1:0]; 
  Module_BusArbitrer ARB_TMEM
  (
  .Clock( Clock ),
  .Reset( Reset ), 
  .iRequest( {wBankReadRequest[3][Bank],wBankReadRequest[2][Bank],wBankReadRequest[1][Bank],wBankReadRequest[0][Bank]}),
  .oGrant(   wBankReadGrantedDelay[Bank]  ),     //The bit of the core granted to read from this Bank
  .oBusSelect( wCurrentCoreSelected[Bank] )      //The index of the core granted to read from this Bank
  
  );
  
  FFD_POSEDGE_SYNCRONOUS_RESET # ( `MAX_CORES ) FFD_GNT
(
  .Clock(Clock),
  .Reset(Reset),
  .Enable( 1'b1 ),
  .D(wBankReadGrantedDelay[Bank]),
  .Q(wBankReadGranted[Bank])
);

 MUXFULLPARALELL_GENERIC # (`WB_WIDTH,`MAX_CORES,`MAX_CORE_BITS) MUXG2
	(
	.in_bus( wCrossBarAdressCollumn ),
	.sel( wCurrentCoreSelected[ Bank ] ),
	.out( wCrossBarAddressRow[ Bank ] )
	);
  
  
  
end
endgenerate

////////////// CROSS-BAR INTERCONECTION//////////////////////////

endmodule
