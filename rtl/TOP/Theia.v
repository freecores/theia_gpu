`timescale 1ns / 1ps
`include "aDefinitions.v"

//---------------------------------------------------------------------------
module THEIA
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
input wire [`MAX_CORES-1:0]  	SEL_I,	//The WishBone Master uses this signal to configure a specific core (TBD, not sure is needed)
input wire [`MAX_CORES-1:0]   RENDREN_I,
//Control Register
input wire [15:0]		         CREG_I,
output wire                   DONE_O

);




wire [`MAX_CORES-1:0] wDone;
wire [`MAX_CORES-1:0] wBusGranted,wBusRequest;
wire [`WB_WIDTH-1:0]  wDAT_O_0,wDAT_O_1,wDAT_O_2,wDAT_O_3;
wire [`WB_WIDTH-1:0]  wADR_O_0,wADR_O_1,wADR_O_2,wADR_O_3;
wire [1:0] wTGA_O_0,wTGA_O_1,wTGA_O_2,wTGA_O_3;
wire [1:0] wBusSelect;

//wire   wSTB_O_0,wSTB_O_1,wSTB_O_2,wSTB_O_3;
//wire   wWE_O_0,wWE_O_1,wWE_O_2,wWE_O_3;

wire [`MAX_CORES-1:0] wSTB_O,wWE_O,wACK_O;


wire [`MAX_CORES-1:0]   wSTB_I;
wire [`MAX_CORES-1:0]   wMST_I;
wire [`MAX_CORES-1:0]   wACK_I;
wire [`MAX_CORES-1:0]   wCYC_I;
wire [1:0]              wTGA_I[`MAX_CORES-1:0];

assign DONE_O = wDone[0] & wDone[1] & wDone[2] & wDone[3];
//assign DONE_O = wDone[0];
//assign DONE_O = wDone[0] & wDone[1];// & wDone[2];

//----------------------------------------------------------------	
//	assign wDone[3:1] = 3'b111;
//	assign wBusRequest[3:2] = 0;
//	assign wSTB_O[3:2] = 0;
//	assign wWE_O[3:2] = 0;
	Module_BusArbitrer ARB1
	(
	.Clock( CLK_I ),
	.Reset( RST_I ),
	.iRequest( wBusRequest ),
	.oGrant(   wBusGranted ),
	.oBusSelect( wBusSelect )
	
	);
//----------------------------------------------------------------
//The Muxes
//DAT_O Mux
MUXFULLPARALELL_2SEL_GENERIC # ( `WB_WIDTH ) MUX_DAT_O
 (
 .Sel(wBusSelect),
  .I1(wDAT_O_0),
  .I2(wDAT_O_1),
  .I3(wDAT_O_2),
  .I4(wDAT_O_3),
  .O1( DAT_O )
  );

MUXFULLPARALELL_2SEL_GENERIC # ( `WB_WIDTH ) MUX_ADR_O
 (
 .Sel(wBusSelect),
  .I1(wADR_O_0),
  .I2(wADR_O_1),
  .I3(wADR_O_2),
  .I4(wADR_O_3),
  .O1( ADR_O )
  );
  
  

MUXFULLPARALELL_2SEL_GENERIC # ( 1 ) MUX_STB_O
 (
 .Sel(wBusSelect),
  .I1(wSTB_O[0]),
  .I2(wSTB_O[1]),
  .I3(wSTB_O[2]),
  .I4(wSTB_O[3]),
  .O1( STB_O )
  );  
  
  
  MUXFULLPARALELL_2SEL_GENERIC # ( 1 ) MUX_WE_O
 (
 .Sel(wBusSelect),
  .I1(wWE_O[0]),
  .I2(wWE_O[1]),
  .I3(wWE_O[2]),
  .I4(wWE_O[3]),
  .O1( WE_O )
  );  
  
   
  MUXFULLPARALELL_2SEL_GENERIC # ( 2 ) MUX_TGA_O
 (
 .Sel(wBusSelect),
  .I1(wTGA_O_0),
  .I2(wTGA_O_1),
  .I3(wTGA_O_2),
  .I4(wTGA_O_3),
  .O1( TGA_O )
  );
  
	
  assign ACK_O = (wACK_O[0] | wACK_O[1] | wACK_O[2] | wACK_O[3]);
  
	assign wMST_I[0] = (SEL_I[0]) ? MST_I : 0;
	assign wMST_I[1] = (SEL_I[1]) ? MST_I : 0;
	assign wMST_I[2] = (SEL_I[2]) ? MST_I : 0;
	assign wMST_I[3] = (SEL_I[3]) ? MST_I : 0;
	
	assign wSTB_I[0] = (SEL_I[0]) ? STB_I : 0;
	assign wSTB_I[1] = (SEL_I[1]) ? STB_I : 0;
	assign wSTB_I[2] = (SEL_I[2]) ? STB_I : 0;
	assign wSTB_I[3] = (SEL_I[3]) ? STB_I : 0;

	assign wCYC_I[0] = (SEL_I[0]) ? CYC_I : 0;
	assign wCYC_I[1] = (SEL_I[1]) ? CYC_I : 0;
	assign wCYC_I[2] = (SEL_I[2]) ? CYC_I : 0;
	assign wCYC_I[3] = (SEL_I[3]) ? CYC_I : 0;
	
	assign wTGA_I[0] = (SEL_I[0]) ? TGA_I : 0;
	assign wTGA_I[1] = (SEL_I[1]) ? TGA_I : 0;
	assign wTGA_I[2] = (SEL_I[2]) ? TGA_I : 0;
	assign wTGA_I[3] = (SEL_I[3]) ? TGA_I : 0;
	
//----------------------------------------------------------------

	THEIACORE THEIA_CORE0 
		(
		.CLK_I( CLK_I ), 
		.RST_I( RST_I ),
		.RENDREN_I( RENDREN_I[0] ),
		
		//Slave signals
		.ADR_I( ADR_I ),		
		.WE_I(  WE_I  ),
		.STB_I(  wSTB_I[0] ),
		//-----------------------------------
		//This signal behaves in a very funny way...
		//
		.ACK_I( ACK_I ),
		//-----------------------------------
		.CYC_I( wCYC_I[0] ),
		.MST_I( wMST_I[0] ),
		.TGA_I( wTGA_I[0] ),
		.CREG_I( CREG_I ),
		
		//Master Signals
		.WE_O ( 	wWE_O[0]  ),
		.STB_O( 	wSTB_O[0] ),
		.ACK_O( 	wACK_O[0] ),
		.DAT_O(  wDAT_O_0 ),
		.ADR_O(  wADR_O_0 ),
		.CYC_O(  wBusRequest[0] ),
		.GNT_I( 	wBusGranted[0] ),
		.TGA_O( 	wTGA_O_0 ),
		`ifdef DEBUG
		.iDebug_CoreID( `MAX_CORES'd0 ),
		`endif
		//Other
		.DAT_I( DAT_I ),
		.DONE_O( wDone[0] )

	);
//----------------------------------------------------------------
THEIACORE THEIA_CORE1 
		(
		.CLK_I( CLK_I ), 
		.RST_I( RST_I ),
		.RENDREN_I( RENDREN_I[1] ),
		
		//Slave signals
		.ADR_I( ADR_I ),		
		.WE_I(  WE_I  ),
		.STB_I(  wSTB_I[1] ),//ok
		.ACK_I(  ACK_I ),
		.CYC_I( wCYC_I[1] ),//ok
		.MST_I( wMST_I[1] ),//ok
		.TGA_I( wTGA_I[1] ),//ok
		.CREG_I( CREG_I ),
		
		//Master Signals
		.WE_O ( 	wWE_O[1]  ),
		.STB_O( 	wSTB_O[1] ),
		.ACK_O( 	wACK_O[1] ),
		.DAT_O(  wDAT_O_1 ),
		.ADR_O(  wADR_O_1 ),
		.CYC_O(  wBusRequest[1] ),
		.GNT_I( 	wBusGranted[1] ),
		.TGA_O( 	wTGA_O_1 ),
		`ifdef DEBUG
		.iDebug_CoreID( `MAX_CORES'd1 ),
		`endif
		//Other
		.DAT_I( DAT_I ),
		.DONE_O( wDone[1] )

	);
//----------------------------------------------------------------
THEIACORE THEIA_CORE2 
		(
		.CLK_I( CLK_I ), 
		.RST_I( RST_I ),
		.RENDREN_I( RENDREN_I[2] ),
		
		//Slave signals
		.ADR_I( ADR_I ),		
		.WE_I(  WE_I  ),
		.STB_I(  wSTB_I[2] ),
		.ACK_I(  ACK_I ),
		.CYC_I( wCYC_I[2] ),
		.MST_I( wMST_I[2] ),
		.TGA_I( wTGA_I[2] ),
		.CREG_I( CREG_I ),
		
		//Master Signals
		.WE_O ( 	wWE_O[2]  ),
		.STB_O( 	wSTB_O[2] ),
		.ACK_O( 	wACK_O[2] ),
		.DAT_O(  wDAT_O_2 ),
		.ADR_O(  wADR_O_2 ),
		.CYC_O(  wBusRequest[2] ),
		.GNT_I( 	wBusGranted[2] ),
		.TGA_O( 	wTGA_O_2 ),
		`ifdef DEBUG
		.iDebug_CoreID( `MAX_CORES'd2 ),
		`endif
		//Other
		.DAT_I( DAT_I ),
		.DONE_O( wDone[2] )

	);
	//----------------------------------------------------------------
THEIACORE THEIA_CORE3 
		(
		.CLK_I( CLK_I ), 
		.RST_I( RST_I ),
		.RENDREN_I( RENDREN_I[3] ),
		
		//Slave signals
		.ADR_I( ADR_I ),		
		.WE_I(  WE_I  ),
		.STB_I(  wSTB_I[3] ),
		.ACK_I(  ACK_I ),
		.CYC_I( wCYC_I[3] ),
		.MST_I( wMST_I[3] ),
		.TGA_I( wTGA_I[3] ),
		.CREG_I( CREG_I ),
		
		//Master Signals
		.WE_O ( 	wWE_O[3]  ),
		.STB_O( 	wSTB_O[3] ),
		.ACK_O( 	wACK_O[3] ),
		.DAT_O(  wDAT_O_3 ),
		.ADR_O(  wADR_O_3 ),
		.CYC_O(  wBusRequest[3] ),
		.GNT_I( 	wBusGranted[3] ),
		.TGA_O( 	wTGA_O_3 ),
		`ifdef DEBUG
		.iDebug_CoreID( `MAX_CORES'd3 ),
		`endif
		//Other
		.DAT_I( DAT_I ),
		.DONE_O( wDone[3] )

	);
//----------------------------------------------------------------
endmodule
//---------------------------------------------------------------------------
