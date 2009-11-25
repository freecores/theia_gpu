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
`define TNF_AFTER_RESET					0
`define TNF_IDLE							1
`define TNF_REQUEST_AABBMIN			2
`define TNF_WAIT_FOR_AABBMIN			3
`define TNF_REQUEST_AABBMAX			4
`define TNF_WAIT_FOR_AABBMAX			5
	
`define TNF_REQUEST_NUMBER_OF_TRIANGLES	10		
`define TNF_WAIT_FOR_NUMBER_OF_TRIANGLES 11	
`define TNF_LATCH_NUMBER_OF_TRIANGLES	 12	
`define TNF_WAIT_NODE_READ_ACK			 13		
`define TNF_REQUEST_DATA_OFFSET			 14
`define TNF_WAIT_FOR_DATA_OFFSET			 15
`define TNF_LATCH_DATA_OFFSET				 16
`define TNF_REQUEST_NODE_BROTHER_ADDRESS	17
`define TNF_WAIT_FOR_NODE_BROTHER_ADDRESS 18
`define TNF_LACTH_NODE_BROTHER_ADDRESS		19
`define TNF_REQUEST_NODE_PARENT_BROTHER_ADDRESS	20
`define TNF_WAIT_NODE_PARENT_BROTHER_ADDRESS		21
`define TNF_LATCH_NODE_PARENT_BROTHER_ADDRESS	22	
`define TNF_RAM_WRITE_DELAY1							23
`define TNF_INC1	24
`define TNF_INC2	25
`define TNF_INC3	26

/*

	To fetch node, we need to ask WBM to perform several read cycles.
	Each read cycle reads 32 bits. The first 6 read cycles requests
	consecutive addresses that represent AABBMAX and AABBMIN corners.
	These 6 values must be stored into RAM for the ucode to use.
	Next value represents the number of vertices this AABB has, or
	zero is is not a LEAF.
	Next value is the offset where of the vertex data.
*/

module TreeNodeFetcher
(
	input wire					Clock,
	input wire					Reset,
	input	wire[`WIDTH-1:0]	iData,
	input	wire					iDataAvailable,
	input	wire					iTrigger,
	input wire[`WIDTH-1:0]	iInitialAddress,
		
	//wires that go into WBM
	output reg						oSetAddressWBM,
	output reg 						oEnableWBM,
	output wire[`WIDTH-1:0]		oAddressWBM,
	//The parsed node info
	output wire						oNode_IsLeaf,
	output wire[`WIDTH-1:0]		oNode_DataOffset,
	output wire	[`WIDTH-1:0]	oNode_TriangleCount,	//Change to 16 bits
	//output wire [`WIDTH-1:0]	oNode_ChildCount,		//Change to 16 bits
	
	output wire [`WIDTH-1:0]	oNode_Brother_Address,			//*
	output wire [`WIDTH-1:0]	oParents_Brother_Address,		//*
	//output reg [`WIDTH-1:0]		oNode_FirstChild_Address,

	output reg						oNodeReadDone,
	output reg						oRAMWriteEnable,
		
	output  reg [`DATA_ADDRESS_WIDTH-1:0] oRAMWriteAddress
);

reg [4:0] 			CurrentState; 
reg [4:0] 			NextState; 


assign oAddressWBM = iInitialAddress;

reg rFFEnNumVertices;

//Flip Flop D
//FFD_SYNCH_RST_GENERIC FFD32_TNF
FFD_POSEDGE_SYNCRONOUS_RESET # (`WIDTH) FFD32_TNF 
(
	.Clock( 	Clock ),
	.Reset( 	Reset ),
	.Enable( rFFEnNumVertices ),
	.D( iData ),
	.Q( oNode_TriangleCount )
	
);


reg rFFEnBrotherAddress;
//Flip Flop D
FFD_POSEDGE_SYNCRONOUS_RESET # (`WIDTH) FFD32_TNF_NC 
//FFD_SYNCH_RST_GENERIC FFD32_TNF_NC
(
	.Clock( 	Clock ),
	.Reset( 	Reset ),
	.Enable( rFFEnBrotherAddress ),
	.D( iData ),
	.Q( oNode_Brother_Address )
	
);

reg rFFEnParentsBroAddr;
//Flip Flop D
FFD_POSEDGE_SYNCRONOUS_RESET  # (`WIDTH) FFD32_TNF_NC2 
//FFD_SYNCH_RST_GENERIC FFD32_TNF_NC2
(
	.Clock( 	Clock ),
	.Reset( 	Reset ),
	.Enable( rFFEnParentsBroAddr ),
	.D( iData ),
	.Q( oParents_Brother_Address )
	
);


reg rFFEnDataOffset;
//Flip Flop D
FFD_POSEDGE_SYNCRONOUS_RESET  # (`WIDTH) FFD32_TNF2
//FFD_SYNCH_RST_GENERIC FFD32_TNF2
(
	.Clock( 	Clock ),
	.Reset( 	Reset ),
	.Enable( rFFEnDataOffset ),
	.D( iData ),
	.Q( oNode_DataOffset )
	
);


assign oNode_IsLeaf = (oNode_TriangleCount != 32'h0);

//------------------------------------------------
  always @(posedge Clock or posedge Reset) 
  begin 
  
    if (Reset)  
		CurrentState <= `TNF_AFTER_RESET; 
    else        
		CurrentState <= NextState; 
		
  end

//------------------------------------
/*
	IDLE State just waiting for something
	to do...
*/

always @( * ) 
   begin 
   case (CurrentState) 
	//------------------------------------
	`TNF_AFTER_RESET:
	begin
	
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 0;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		oRAMWriteEnable	<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
		
		NextState <= `TNF_IDLE;
	end
	//------------------------------------
	`TNF_IDLE:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 0;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		oRAMWriteEnable	<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
		
	   if (iTrigger)
			NextState <= `TNF_REQUEST_AABBMIN; 
		else
			NextState <= `TNF_IDLE;
	
	end
	//------------------------------------
	/*
	Here tell WBM to read from address iInitialAddress by seeting
	oSetAddressWBM = 1.
	By setting oRAMWriteEnable = 1, we are also telling WBM to 
	store the the value in iInitialAddress,	iInitialAddress+1, 
	and iInitialAddress+2 into RAM, so the WBMAddress is going 
	to increment by 3.
	*/
	`TNF_REQUEST_AABBMIN: 
	begin
		oRAMWriteAddress	<= `CREG_AABBMIN;
		oEnableWBM 	<= 1; //*
		oSetAddressWBM		<= 1; //*
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 1; //*
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
	
		NextState <= `TNF_WAIT_FOR_AABBMIN;
		
	end
	//------------------------------------
	`TNF_WAIT_FOR_AABBMIN:
	begin
		oRAMWriteAddress	<= `CREG_AABBMIN;
		oEnableWBM 	<= 1;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 1;//*
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
				
		if ( iDataAvailable )
			NextState <= `TNF_REQUEST_AABBMAX;
		else
			NextState <= `TNF_WAIT_FOR_AABBMIN;
	end
	//------------------------------------
	`TNF_REQUEST_AABBMAX:
	begin
		oRAMWriteAddress	<= `CREG_AABBMAX;
		oEnableWBM 	<= 1;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 1;//*
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
				
		NextState <= `TNF_WAIT_FOR_AABBMAX;
	end
	//------------------------------------
	`TNF_WAIT_FOR_AABBMAX:
	begin
		oRAMWriteAddress	<= `CREG_AABBMAX;
		oEnableWBM 	<= 1;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 1;//*
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
		
		if ( iDataAvailable )
			NextState <= `TNF_REQUEST_NUMBER_OF_TRIANGLES;
		else
			NextState <= `TNF_WAIT_FOR_AABBMAX;
	end
	//------------------------------------
	`TNF_REQUEST_NUMBER_OF_TRIANGLES:
	begin
		oRAMWriteAddress	<= `CREG_AABBMAX;
		oEnableWBM 	<= 1; //*
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0; //* to give more time to write
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
		
		NextState <= `TNF_WAIT_FOR_NUMBER_OF_TRIANGLES;
	end
	//------------------------------------
	`TNF_WAIT_FOR_NUMBER_OF_TRIANGLES:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 1;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
		oRAMWriteEnable	   <= 0;
				
		if ( iDataAvailable )
			NextState <= `TNF_LATCH_NUMBER_OF_TRIANGLES;
		else
			NextState <= `TNF_WAIT_FOR_NUMBER_OF_TRIANGLES;
		
	end
	//------------------------------------
	`TNF_LATCH_NUMBER_OF_TRIANGLES:
	begin
		
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 0;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;	//* 
		rFFEnNumVertices	<= 1;
		rFFEnDataOffset	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
		oRAMWriteEnable	  	<= 0;
				
		NextState <= `TNF_REQUEST_DATA_OFFSET;
	end
	//------------------------------------
	`TNF_REQUEST_DATA_OFFSET:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 1; //*
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
		
		NextState <= `TNF_WAIT_FOR_DATA_OFFSET;
	end
	//------------------------------------
	`TNF_WAIT_FOR_DATA_OFFSET:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 1; //* 
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
		
		if ( iDataAvailable )
			NextState <= `TNF_LATCH_DATA_OFFSET;
		else
			NextState <= `TNF_WAIT_FOR_DATA_OFFSET;
			
	end
	//------------------------------------
	`TNF_LATCH_DATA_OFFSET:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 0;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;	
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 1; //*
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
				
		NextState <= `TNF_REQUEST_NODE_BROTHER_ADDRESS;
	end
	//------------------------------------
	`TNF_REQUEST_NODE_BROTHER_ADDRESS:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 1;	//*
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;	
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 1;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
			
		NextState <= `TNF_WAIT_FOR_NODE_BROTHER_ADDRESS;
	end	
	//------------------------------------
	`TNF_WAIT_FOR_NODE_BROTHER_ADDRESS:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 1;	//*
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;	
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
			
		if ( iDataAvailable )
			NextState <= `TNF_LACTH_NODE_BROTHER_ADDRESS;
		else
			NextState <= `TNF_WAIT_FOR_NODE_BROTHER_ADDRESS;
	end
	//------------------------------------
	`TNF_LACTH_NODE_BROTHER_ADDRESS:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 0;	
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;	
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 1;	//*
		rFFEnParentsBroAddr 	<=	0;
				
		NextState <= `TNF_REQUEST_NODE_PARENT_BROTHER_ADDRESS;
	end
	//------------------------------------
	`TNF_REQUEST_NODE_PARENT_BROTHER_ADDRESS:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 1;	//*
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;	
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;	
		rFFEnParentsBroAddr 	<=	0;
		//rLastAddress						<= 1;
		
		NextState <= `TNF_WAIT_NODE_PARENT_BROTHER_ADDRESS;
	end
	//------------------------------------
	`TNF_WAIT_NODE_PARENT_BROTHER_ADDRESS:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 1;	
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;	
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;	
		rFFEnParentsBroAddr 	<=	0;
				
		if ( iDataAvailable )
			NextState <= `TNF_LATCH_NODE_PARENT_BROTHER_ADDRESS;
		else
			NextState <= `TNF_WAIT_NODE_PARENT_BROTHER_ADDRESS;
	end
	//------------------------------------
	`TNF_LATCH_NODE_PARENT_BROTHER_ADDRESS:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 0;	
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;	
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;	
		rFFEnParentsBroAddr 	<=	1;
				
		NextState <= `TNF_WAIT_NODE_READ_ACK;
		
	end
	//------------------------------------
	`TNF_WAIT_NODE_READ_ACK:
	begin
		
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 0;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 1;	//*
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
			
		if (	iTrigger == 0 )
			NextState <= `TNF_IDLE;
		else
			NextState <= `TNF_WAIT_NODE_READ_ACK;
	end
	//------------------------------------
	default:
	begin
		oRAMWriteAddress	<= 0;
		oEnableWBM 	<= 0;
		oSetAddressWBM		<= 0;
		oNodeReadDone		<= 0;
		rFFEnNumVertices	<= 0;
		rFFEnDataOffset	<= 0;
		oRAMWriteEnable	  	<= 0;
		rFFEnBrotherAddress	<= 0;
		rFFEnParentsBroAddr 	<=	0;
			
		NextState <= `TNF_IDLE;
	end
	//------------------------------------
	endcase
end //always	
endmodule
