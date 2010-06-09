`timescale 1ns / 1ps
`include "aDefinitions.v"

`define TFU_AFTER_RESET									0
`define TFU_IDLE											1
`define TFU_REQUEST_VERTEX								2
`define TFU_WAIT_FOR_VERTEX							3
`define TFU_REQUEST_NEXT_VERTEX_DIFFUSE			4
`define TFU_REQUEST_DIFFUSE_COLOR 					5
`define TFU_WAIT_FOR_DIFFUSE_COLOR					6
`define TFU_SET_WBM_INITIAL_ADDRESS 				7
`define TFU_CHECK_FOR_WBM_ADDRESS_SET 				8
`define TFU_SET_DIFFUSE_COLOR_ADDRESS				9
`define TFU_REQUEST_NEXT_VERTEX_UV_DIFFUSE		10
`define TFU_INC_WRITE_ADDRESS_DIFFUSE				11
`define TFU_DONE											12
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
/*


	Warning: setting iTrigger while oBusy = 1 will reset the Up counters!

*/
//-------------------------------------------------------------------------
module TriangleFetchUnit
(
	input wire					Clock,
	input wire					Reset,
	input	wire					iTrigger,
	//output reg					oBusy,							//I am currently busy
	output reg					oDone,							//Done reading trinagle data
	//Wires from GFSM
	input	wire					iDataAvailable,				//Data is ready
	input wire[`WIDTH-1:0]	iInitialAddress,				//The initial address of the data
	input wire 					iSetAddressOffset, 			//Set the iInitialAddress Now
	//Wires from Control Register
	input wire					iCR_TextureMappingEnabled,	//Is the texture map fearure enable?
	
	//Wires to WBM
	output reg 										oTriggerWBM,
	output wire[`WIDTH-1:0]						oAddressWBM,
	output reg										oSetAddressWBM,
	output wire[`DATA_ADDRESS_WIDTH-1:0] 	oRAMWriteAddress,
	`ifdef DEBUG
	input wire[`MAX_CORES-1:0]            iDebug_CoreID,
	`endif
	output reg										oRAMWriteEnable
		
);



assign oAddressWBM = iInitialAddress;///Must change or will always read first triangle in the list....


reg [4:0] 	CurrentState,NextState; 
reg IncWriteAddress,IncVertexCount;
wire [2:0] wVertexCount;
//-----------------------------
UpCounter_3 TNF_VC1
(
.Clock( Clock ), 
.Reset( iTrigger ),
.Initial( 3'b0 ),
.Enable( IncVertexCount ),
.Q( wVertexCount )
);


//-----------------------------
UpCounter_16E TNF_TFU_2
(

.Clock( Clock ), 
.Reset( iTrigger ),
.Initial( `CREG_V0 ),//iRAMWriteOffset ),
.Enable( IncWriteAddress ),
.Q( oRAMWriteAddress )

);

//------------------------------------------------
  always @(posedge Clock or posedge Reset) 
  begin 
  
    if (Reset)  
		CurrentState <= `TFU_AFTER_RESET; 
    else        
		CurrentState <= NextState; 
		
  end

//------------------------------------
always @( * ) 
   begin 
   case (CurrentState) 
	//------------------------------------
	`TFU_AFTER_RESET:
	begin
	
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 0;
		IncVertexCount		<= 0;
	//	oBusy	  				<= 0;
		oDone	  				<= 0;
		oRAMWriteEnable	<= 0;
		
		NextState <= `TFU_IDLE;
   end
	//------------------------------------
	`TFU_IDLE:
	begin
		
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 0;
		IncVertexCount		<= 0;
	//	oBusy	  				<= 0;
		oDone	  				<= 0;
		oRAMWriteEnable	<= 0;
		
		if ( iTrigger )
			NextState <= `TFU_CHECK_FOR_WBM_ADDRESS_SET;
		else
			NextState <= `TFU_IDLE;
		
	end
	//------------------------------------
	`TFU_CHECK_FOR_WBM_ADDRESS_SET:
	begin
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 0;
		IncVertexCount		<= 0;
	//	oBusy	  				<= 0;
		oDone	  				<= 0;
		oRAMWriteEnable	<= 0;
		
		if ( iSetAddressOffset )
			NextState <= `TFU_SET_WBM_INITIAL_ADDRESS;
		else
			NextState <= `TFU_REQUEST_VERTEX;
	
	end
	//------------------------------------
	`TFU_SET_WBM_INITIAL_ADDRESS:
	begin
	
		`ifdef DEBUG
			$display("TFU: TFU_SET_WBM_INITIAL_ADDRESS");
		`endif
	
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 1; //*
		IncWriteAddress 	<= 0;
		IncVertexCount		<= 0; 
	//	oBusy	  				<= 1; //*
		oDone	  				<= 0;
		oRAMWriteEnable	<= 0; 
		
		NextState <= `TFU_REQUEST_VERTEX;
	end
	//------------------------------------
	`TFU_REQUEST_VERTEX:
	begin
		oTriggerWBM			<= 1; //*
		oSetAddressWBM		<= 0; 
		IncWriteAddress 	<= 0;
		IncVertexCount		<= 1; //*
	//	oBusy	  				<= 1; 
		oDone	  				<= 0;
		oRAMWriteEnable	<= 1; //*
		//$display("TFU_REQUEST_VERTEX %d to wirte to %d\n",oAddressWBM,oRAMWriteAddress);
		NextState <= `TFU_WAIT_FOR_VERTEX;
	end
	//------------------------------------
	`TFU_WAIT_FOR_VERTEX:
	begin
		
		oTriggerWBM			<= 1; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 0;
		IncVertexCount		<= 0;
	//	oBusy	  				<= 1; //*
		oDone	  				<= 0;
		oRAMWriteEnable	<= 1;
		
		
		if ( iDataAvailable && iCR_TextureMappingEnabled == 1'b0)
			NextState <= `TFU_REQUEST_NEXT_VERTEX_DIFFUSE;
		else if ( iDataAvailable && 	iCR_TextureMappingEnabled == 1'b1)
			NextState <= `TFU_REQUEST_NEXT_VERTEX_UV_DIFFUSE;
		else	
			NextState <= `TFU_WAIT_FOR_VERTEX;
	end
	//------------------------------------
	`TFU_REQUEST_NEXT_VERTEX_DIFFUSE:
	begin
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 1; //*
		IncVertexCount		<= 0;
	//	oBusy	  				<= 1; 
		oDone	  				<= 0;
		oRAMWriteEnable	<= 0;
		
		
		//if ( wVertexCount == 3)
		//	NextState <= `TFU_REQUEST_DIFFUSE_COLOR;
		//else
			NextState <= `TFU_INC_WRITE_ADDRESS_DIFFUSE;
	end
	//------------------------------------
	`TFU_REQUEST_NEXT_VERTEX_UV_DIFFUSE:
	begin
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 1; //*
		IncVertexCount		<= 0;
	//	oBusy	  				<= 1; 
		oDone	  				<= 0;
		oRAMWriteEnable	<= 0;
		
		//$display("TFU_REQUEST_NEXT_VERTEX_UV_DIFFUSE, count = %d",wVertexCount);
		if ( wVertexCount == 6)
			NextState <= `TFU_REQUEST_DIFFUSE_COLOR;
		else
			NextState <= `TFU_REQUEST_VERTEX;
	end
	//------------------------------------
	`TFU_INC_WRITE_ADDRESS_DIFFUSE:
	begin
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 1; //*
		IncVertexCount		<= 0;
	//	oBusy	  				<= 1; 
		oDone	  				<= 0;
		oRAMWriteEnable	<= 0;
		
	//	$display(":) TFU_REQUEST_NEXT_VERTEX_DIFFUSE, count = %d",wVertexCount);
		if ( wVertexCount == 3)
			NextState <= `TFU_REQUEST_DIFFUSE_COLOR;
		else
			NextState <= `TFU_REQUEST_VERTEX;
	end
	//------------------------------------
	`TFU_REQUEST_DIFFUSE_COLOR:
	begin
	
//		$display("TFU_REQUEST_DIFFUSE_COLOR: Writting to %d",oRAMWriteAddress);
		oTriggerWBM			<= 1; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 0; 
		IncVertexCount		<= 0;
	//	oBusy	  				<= 1; 
		oDone	  				<= 0; 
		oRAMWriteEnable	<= 1;
		
		NextState <= `TFU_WAIT_FOR_DIFFUSE_COLOR;
		
	end
	//------------------------------------
	`TFU_WAIT_FOR_DIFFUSE_COLOR:
	begin
		oTriggerWBM			<= 1; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 0; 
		IncVertexCount		<= 0;
	//	oBusy	  				<= 1; 
		oDone	  				<= 0; //*
		oRAMWriteEnable	<= 1;
		
		if ( iDataAvailable )
			NextState <= `TFU_DONE;
		else
			NextState <= `TFU_WAIT_FOR_DIFFUSE_COLOR;
		
	end

	//------------------------------------
	`TFU_DONE:
	begin
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 0;
		IncVertexCount		<= 0;
	//	oBusy	  				<= 0;	//*
		oDone	  				<= 1; //*
		oRAMWriteEnable	<= 0;
		
		NextState <= `TFU_IDLE;
	end
	//------------------------------------
	default:
	begin
		oTriggerWBM			<= 0; 
		oSetAddressWBM		<= 0;
		IncWriteAddress 	<= 0;
		IncVertexCount		<= 0;
	//	oBusy	  				<= 0;
		oDone	  				<= 0;
		oRAMWriteEnable	<= 0;
		
		NextState <= `TFU_IDLE;
	end
	//------------------------------------
	endcase
	
end //always
endmodule
//-------------------------------------------------------------------------