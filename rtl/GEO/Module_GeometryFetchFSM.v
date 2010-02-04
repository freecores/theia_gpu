/**********************************************************************************
Theaia, Ray Cast Programable graphic Processing Unit.
Copyright (C) 2009  Diego Valverde (diego.valverde.g@gmail.com)

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
Module Description:

WIP
**********************************************************************************/


`timescale 1ns / 1ps
`include "aDefinitions.v"

`define GFSM_AFTER_RESET                       0
`define GFSM_INITIAL_STATE                     1
`define GFSM_TRIGGER_AABBIU                    2
`define GFSM_WAIT_FOR_AABBIU                   3
`define GFSM_ACK_AABBIU                       10
`define GFSM_AABBIU_HIT                        4	
`define GFSM_AABBIU_NO_HIT                     5
`define GFSM_TRIGGER_TRIANGLE_FETCH            6
`define GFSM_WAIT_FOR_TRIANGLE_FETCH           7
`define GFSM_TRIGGER_BIU_REQUSET               8
`define GFSM_WAIT_FOR_BIU                      9
`define GFSM_GET_FIRST_CHILD                  11
`define GFSM_CHECK_TRIANGLE_COUNT             12
`define GFSM_CHECK_NEXT_BROTHER               13
`define GFSM_GET_BROTHER                      14
`define GFSM_TRIGGER_NODE_FETCH               15
`define GFSM_FETCH_NEXT_BROTHER               16
`define GFSM_CHECK_PARENTS_BROTHER            18
`define GFSM_GET_PARENTS_BROTHER              19
`define GFSM_WAIT_FOR_NODE_FETCH              20
`define GFSM_POST_BLOCK_READ_DELAY            21
`define GFSM_TRIGGER_ROOT_NODE_FETCH          23
`define GFSM_WAIT_FOR_ROOT_NODE_FETCH         24
`define GFSM_FETCH_DATA                       25
`define GFSM_WAITF_FOR_BIU_AVAILABLE          26
`define GFSM_SWAP_TRIANGLE_POINTER            27
`define GFSM_DONE                             28
`define GFSM_SET_TRIANGLE_LIST_INITIAL_OFFSET 29
`define GFSM_REQUEST_TCC                      30
`define GFSM_WAIT_FOR_TCC                     31
`define GFSM_WAIT_STATE_PRE_TCC               32
`define GFSM_INITIAL_STATE_TEXTURE            33
`define GFSM_SET_WBM_INITIAL_ADDRESS          34
`define GFSM_REQUEST_TEXTURE                  35
`define GFSM_WAIT_FOR_TEXTURE                 36
`define GFSM_REQUEST_NEXT_TEXTURE             37
`define GFSM_WAIT_FOR_NEXT_TEXTURE            38
`define GFSM_INC_TEXTURE_ADDRESS              39
`define GFSM_SET_NEXT_TEXTURE_ADDR            42


module GeometryFetchFSM
(
	input wire                    Clock, 
	input wire                    Reset, 
	//Input control signals
	input wire                    iEnable,
	input	wire                    iAABBIUHit,
	input wire                    iBIUHit,
	input	wire                    iUCodeDone,
	input wire                    iTexturingEnable,
	input	wire                    iTriangleReadDone,
	//input wire                 iTextureReadDone,
	input	wire                    iNodeReadDone,
	
	//Current Node info
	input	wire                    iNode_IsLeaf,
	input wire[`WIDTH-1:0]        iNode_Brother_Address,
	input wire[`WIDTH-1:0]        iNode_TriangleCount,
	input wire[`WIDTH-1:0]        iNode_Parents_Brother_Address,
	//input wire[`WIDTH-1:0]		Node_OffsetData_Address,
	input wire[`WIDTH-1:0]        iNode_FirstChild_Address,
	//input	wire						iBIUAvailable,
	//input	wire						Node_MaxBlocks,
	
	//Control output signals
	output reg 										oEnable_WBM,        //Activate the WBM in I/O
	output wire[`DATA_ADDRESS_WIDTH-1:0]	   oAddressWBM,        //This is the address that we want to read from in I/O
	output reg										oSetAddressWBM,     //This uis to tell I/O to use the adress we just set
	output reg                             oSetIOWriteBackAddr,
	output wire[`DATA_ADDRESS_WIDTH-1:0] 	oRAMTextureStoreLocation,   //This is where we want to store the data comming from I/O
	input	wire					               iDataAvailable,
	
	
	output reg	[`WIDTH-1:0]      oNodeAddress,
	input wire 							iTrigger_TFF,
	
	output reg                    oRequest_AABBIU,
	output reg                    oRequest_BIU,
	output reg                    oRequest_TCC,
	output reg                    oTrigger_TFU,
	output reg                    oTrigger_TNF,
	output reg [1:0]              oWBM_Addr_Selector, //0 = TNF, 1 = TFU, 2 = TCC 
	output reg                    oSync,
	output reg                    oSetTFUAddressOffset,
	output reg                    oDone
	
						
);





reg [6:0] CurrentState; 
reg [6:0] NextState; 
//reg //IncTextureWriteAddress;
reg IncTextureCoordRegrAddr,IncTextureCount;
wire [2:0]  wTextureCount;

reg IncTriangleCount,ClearTriangleCount;
wire [`WIDTH-1:0] wTriangleCount;

//----------------------------------------
UpCounter_32 UP32_Tricount
(

.Clock( Clock ), 
.Reset( ClearTriangleCount ),
.Initial( 0 ),
.Enable( IncTriangleCount ),
.Q( wTriangleCount )

);
//-----------------------------

UpCounter_16E TFF_VC1a
(
.Clock( Clock ), 
.Reset( iTrigger_TFF | Reset ),
.Initial( `OREG_TEX_COORD1 ),
.Enable( IncTextureCoordRegrAddr ),
.Q( oAddressWBM )
);

//assign oAddressWBM = `OREG_TEX_COORD1;

//-----------------------------

UPCOUNTER_POSEDGE # (3) TFF_VC1
(
.Clock( Clock ), 
.Reset( iTrigger_TFF ),
.Initial( 3'b0 ),
.Enable( IncTextureCount ),
.Q(  wTextureCount )
);

//-----------------------------
assign oRAMTextureStoreLocation = `CREG_TEX_COLOR1;
/*
UPCOUNTER_POSEDGE # (16) TNF_TFU_2
(

.Clock( Clock ), 
.Reset( iTrigger_TFF ),
.Initial( `CREG_TEX_COLOR1 ),
.Enable(  //IncTextureWriteAddress ),
.Q( oRAMTextureStoreLocation )

);
*/

//----------------------------------------
`define GFSM_SELECT_TFU 2'b00  //Triangle Fetch
`define GFSM_SELECT_TFF 2'b01  //Texture Fetch     
`define GFSM_SELECT_TNF 2'b10  //Tree node fetch
`define GFSM_SELECT_NULL 2'b11

	//------------------------------------------------
  always @(posedge Clock or posedge Reset) 
  begin 
  
		
			
    if (Reset)  
		CurrentState <= `GFSM_AFTER_RESET; 
    else        
		CurrentState <= NextState; 
		
  end
  //------------------------------------------------

	always @( * ) 
   begin 
        case (CurrentState) 
		  //------------------------------------------
		  `GFSM_AFTER_RESET:
		  begin
				
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0;
				ClearTriangleCount	<= 0;
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				IncTextureCoordRegrAddr       <= 0;
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				NextState 	<= `GFSM_INITIAL_STATE;
		  end
		  //------------------------------------------
		  /*
		  Here two things ca happen: 
		  1) We are onGeometry Fetch Mode (iTrigger_TFF == 0)
		  then get the first node in the Octant Tree, or,
		  2)We are on Texture Fetch Mode (iTrigger_TFF == 1)
		  then do texture fetch stuff...
		  */
		  `GFSM_INITIAL_STATE:
		  begin
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0;
				ClearTriangleCount	<= 1;	//*
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				IncTextureCoordRegrAddr       <= 0;
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				if ( iEnable && !iTrigger_TFF )
					NextState <= `GFSM_TRIGGER_ROOT_NODE_FETCH;
				else if (iEnable && iTrigger_TFF)	
					NextState <= `GFSM_SET_WBM_INITIAL_ADDRESS;
				else
					NextState <= `GFSM_INITIAL_STATE;
		  end
		  //------------------------------------------
		  `GFSM_SET_WBM_INITIAL_ADDRESS:
		  begin
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0;
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_TFF;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				
				oEnable_WBM		         <= 0; 
				oSetAddressWBM		      <= 1; //*
				oSetIOWriteBackAddr     <= 1; //Make sure we set write back address
				IncTextureCount	      <= 0;
				IncTextureCoordRegrAddr <= 0;
				
				
				NextState <= `GFSM_REQUEST_TEXTURE;
	
		end
		//------------------------------------
		`GFSM_REQUEST_TEXTURE:
		begin
			oNodeAddress			<= 0;
			oRequest_AABBIU		<= 0;
			oRequest_BIU			<= 0;
			oTrigger_TFU			<= 0;
			oTrigger_TNF			<= 0;
			ClearTriangleCount	<= 0;	
			IncTriangleCount		<= 0;
			oWBM_Addr_Selector	<= `GFSM_SELECT_TFF;
			oSync						<= 0;
			oDone						<= 0;
			oSetTFUAddressOffset <= 0;
			oRequest_TCC         <= 0;
			
			//$display("GFSM_REQUEST_TEXTURE: Texture Addr in Reg: %d",oAddressWBM);
			oEnable_WBM              <= 1; //*
			oSetAddressWBM		       <= 0;
			IncTextureCount	       <= 0; //*
			IncTextureCoordRegrAddr  <= 0;
			oSetIOWriteBackAddr <= 0;
			
		
			NextState <= `GFSM_WAIT_FOR_TEXTURE;
		end
		//------------------------------------
		`GFSM_WAIT_FOR_TEXTURE:
		begin
         oNodeAddress			<= 0;
			oRequest_AABBIU		<= 0;
			oRequest_BIU			<= 0;
			oTrigger_TFU			<= 0;
			oTrigger_TNF			<= 0;
			ClearTriangleCount	<= 0;	
			IncTriangleCount		<= 0;
			oWBM_Addr_Selector	<= `GFSM_SELECT_TFF;
			oSync						<= 0;
			oDone						<= 0;
			oSetTFUAddressOffset <= 0;
			oRequest_TCC         <= 0;		
		
		
			oEnable_WBM                <= 1; 
			oSetAddressWBM		         <= 0;
			//IncTextureWriteAddress 	   <= 0;
			IncTextureCount	           <= 0; 
			IncTextureCoordRegrAddr      <= 0; 
			oSetIOWriteBackAddr <= 0;
			//oRAMTextureStoreLocation <= `CREG_TEX_COLOR1;
		
		if ( iDataAvailable )
			NextState <= `GFSM_INC_TEXTURE_ADDRESS;
		else
			NextState <= `GFSM_WAIT_FOR_TEXTURE;
		
		end
		//------------------------------------
		`GFSM_INC_TEXTURE_ADDRESS:
		begin
		//$display("***** GFSM_REQUEST_NEXT_TEXTURE: Texture Addr in Reg: %d",oAddressWBM);
		   oNodeAddress			<= 0;
			oRequest_AABBIU		<= 0;
			oRequest_BIU			<= 0;
			oTrigger_TFU			<= 0;
			oTrigger_TNF			<= 0;
			ClearTriangleCount	<= 0;	
			IncTriangleCount		<= 0;
			oWBM_Addr_Selector	<= `GFSM_SELECT_TFF;
			oSync						<= 0;
			oDone						<= 0;
			oSetTFUAddressOffset <= 0;
			oRequest_TCC         <= 0;
		
			oEnable_WBM            <= 0;
			oSetAddressWBM		      <= 0;
			IncTextureCount	      <= 1;
			//IncTextureWriteAddress 	<= 0;//1;
         IncTextureCoordRegrAddr <= 1; //*		
			oSetIOWriteBackAddr <= 0;
			//oRAMTextureStoreLocation <= `CREG_TEX_COLOR4;			

			NextState <= `GFSM_SET_NEXT_TEXTURE_ADDR;
		end
		//------------------------------------
		`GFSM_SET_NEXT_TEXTURE_ADDR:
		begin
		
		//$display("***** GFSM_REQUEST_NEXT_TEXTURE: Texture Addr in Reg: %d",oAddressWBM);
		   oNodeAddress			<= 0;
			oRequest_AABBIU		<= 0;
			oRequest_BIU			<= 0;
			oTrigger_TFU			<= 0;
			oTrigger_TNF			<= 0;
			ClearTriangleCount	<= 0;	
			IncTriangleCount		<= 0;
			oWBM_Addr_Selector	<= `GFSM_SELECT_TFF;
			oSync						<= 0;
			oDone						<= 0;
			oSetTFUAddressOffset <= 0;
			oRequest_TCC         <= 0;
		
			oEnable_WBM            <= 0; //*
			oSetAddressWBM		      <= 1;
			IncTextureCount	      <= 0; //*
         IncTextureCoordRegrAddr <= 0;		
			oSetIOWriteBackAddr <= 0;
			//oRAMTextureStoreLocation <= `CREG_TEX_COLOR4;			

			
			NextState <= `GFSM_REQUEST_NEXT_TEXTURE;
		end	
		//------------------------------------
		/*
		We request 6 textures (ie. six colors from
		the texture coordinates, it should be actually 4
		instead of 6, but the hardwardware works better
		with numbers that are power of 3. But read 3 at
		a time, so when TextureCount Reaches 2 then we
		are done
		*/
		`GFSM_REQUEST_NEXT_TEXTURE:
		begin
		
		//$display("***** GFSM_REQUEST_NEXT_TEXTURE: Texture Addr in Reg: %d",oAddressWBM);
		   oNodeAddress			<= 0;
			oRequest_AABBIU		<= 0;
			oRequest_BIU			<= 0;
			oTrigger_TFU			<= 0;
			oTrigger_TNF			<= 0;
			ClearTriangleCount	<= 0;	
			IncTriangleCount		<= 0;
			oWBM_Addr_Selector	<= `GFSM_SELECT_TFF;
			oSync						<= 0;
			oDone						<= 0;
			oSetTFUAddressOffset <= 0;
			oRequest_TCC         <= 0;
		
			oEnable_WBM            <= 1; //*
			oSetAddressWBM		      <= 0;
			IncTextureCount	      <= 1; //*
         IncTextureCoordRegrAddr <= 0;		
			oSetIOWriteBackAddr <= 0;
			//oRAMTextureStoreLocation <= `CREG_TEX_COLOR4;			

			
			NextState <= `GFSM_WAIT_FOR_NEXT_TEXTURE;
		end
		
		//----------------------------------------
		`GFSM_WAIT_FOR_NEXT_TEXTURE:
		begin
			oNodeAddress			<= 0;
			oRequest_AABBIU		<= 0;
			oRequest_BIU			<= 0;
			oTrigger_TFU			<= 0;
			oTrigger_TNF			<= 0;
			ClearTriangleCount	<= 0;	
			IncTriangleCount		<= 0;
			oWBM_Addr_Selector	<= `GFSM_SELECT_TFF;
			oSync						<= 0;
			oDone						<= 0;
			oSetTFUAddressOffset <= 0;
			oRequest_TCC         <= 0;		
		
		
			oEnable_WBM                 <= 1; 
			oSetAddressWBM		           <= 0;
			IncTextureCount	           <= 0; //*
			IncTextureCoordRegrAddr      <= 0; 
			oSetIOWriteBackAddr <= 0;
			//oRAMTextureStoreLocation <= `CREG_TEX_COLOR4;
		
		if ( iDataAvailable )
			NextState <= `GFSM_DONE;
		else
			NextState <= `GFSM_WAIT_FOR_NEXT_TEXTURE;
				
		end
			/****************************************/
			/*
			Texture Fetch Logic Ends Here.
			Geometry Fetch Logic Starts Here (Duh!)
			*/
			//------------------------------------
		   /*
			Lets request the Root Node read in here.
			The tree node function will fetch info such as
			the type of node, the address of the first
			data block as well as the boundaries of the
			AABB.
		  */
		  `GFSM_TRIGGER_ROOT_NODE_FETCH:
		  begin
			//	$display("GFSM_TRIGGER_ROOT_NODE_FETCH");
				oNodeAddress			<= 0;	 //Address of root node is always zero
				oRequest_AABBIU		<= 0;	
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 1;	//*
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_TNF;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				NextState <= `GFSM_WAIT_FOR_ROOT_NODE_FETCH;
				
		  end
		  //------------------------------------------
		  /*
			OK once we have the data the first ting is
			to test if the ray hits the AABB.
		  */
		  `GFSM_WAIT_FOR_ROOT_NODE_FETCH:
		  begin
		  
				oNodeAddress			<= 0;	
				oRequest_AABBIU		<= 0;	
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0;//*	
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_TNF;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				if (iNodeReadDone)
					NextState <= `GFSM_TRIGGER_AABBIU;
				else
					NextState <= `GFSM_WAIT_FOR_ROOT_NODE_FETCH;
		  end
		  //------------------------------------------
		  /*
		  So, while we request AABBIU, we should be requesting 
		  the info for the Next triangle as well...
		  */
		  `GFSM_TRIGGER_AABBIU:
		  begin
		//	$display("GFSM_TRIGGER_AABBIU");
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 1;	//*
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;   //WIP!!!!!!!!
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 1; //*
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0;
				IncTextureCoordRegrAddr      <= 0; 	
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;				
			
				NextState <= `GFSM_WAIT_FOR_AABBIU;
		  end
		  //------------------------------------------
		  `GFSM_WAIT_FOR_AABBIU:
		  begin
		  
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 1;	
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				if ( iUCodeDone )
					NextState <= `GFSM_ACK_AABBIU;
				else
					NextState <= `GFSM_WAIT_FOR_AABBIU;
		  end
		  //------------------------------------------
		  `GFSM_ACK_AABBIU:
		  begin
				
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;	//*
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
		  
				if ( iAABBIUHit )
					NextState <= `GFSM_AABBIU_HIT;
				else
					NextState <= `GFSM_AABBIU_NO_HIT;
		  end
		  //------------------------------------------
		  `GFSM_AABBIU_NO_HIT:
		  begin
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;	//*
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
		  
		  
				NextState <= `GFSM_DONE;
		  end
		  //------------------------------------------
		  /*
		   Ok there is a hit, two things can happen:
		   if the Node is not a leaf, then the child nodes
		   need to be tested.
		   Else this node's data linked list needs 
		   to be tested for instersections.
			Since we have a new Node, lets start by 
			reading the first 3 blocks of data. The 
			first block is pointed by 
			'Node_OffsetData_Address'.
		  */
		  `GFSM_AABBIU_HIT:
		  begin
		  				
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;	
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
		  
				if ( iNode_IsLeaf )
					NextState  <= `GFSM_SET_TRIANGLE_LIST_INITIAL_OFFSET;
				else
					NextState  <= `GFSM_GET_FIRST_CHILD;	
		  end
		  //------------------------------------------
		  `GFSM_SET_TRIANGLE_LIST_INITIAL_OFFSET:
		  begin
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;	
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 1; //*
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				NextState  <= `GFSM_TRIGGER_TRIANGLE_FETCH;
		  end
		  //------------------------------------------
		  /*
			Since this node is not a leaf, we keep depth
			first deep traversing the hierchy
		  */
		  `GFSM_GET_FIRST_CHILD:
		  begin
		  
				oRequest_AABBIU		<= 0; 
				oNodeAddress			<= iNode_FirstChild_Address; //*
				oRequest_BIU			<= 0;
				oTrigger_TFU         <= 0;
				oTrigger_TNF         <= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				
				NextState	<= `GFSM_TRIGGER_NODE_FETCH;
		  end
		  //------------------------------------------
		  /*
		   
		  */
		  `GFSM_CHECK_TRIANGLE_COUNT:
		  begin
		  
				oNodeAddress			<= 0;	
				oRequest_AABBIU		<= 0;	
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0;
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				`ifdef DEBUG2
					$display("Fetching triangle %d of %d ", wTriangleCount,iNode_TriangleCount);
				`endif	
				
				if ( wTriangleCount == iNode_TriangleCount )
					NextState <= `GFSM_CHECK_NEXT_BROTHER;
				else
					NextState <= 
					//`GFSM_TRIGGER_TRIANGLE_FETCH;
					`GFSM_TRIGGER_BIU_REQUSET;			//NEW NEW PARALLEL IO
		  end
		   //------------------------------------------
		  `GFSM_TRIGGER_TRIANGLE_FETCH:
		  begin
				
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;	
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 1; //*
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_TFU;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
							
				NextState	<= `GFSM_WAIT_FOR_TRIANGLE_FETCH;
		  end
		  //------------------------------------------
		  
		  /*
			iEnable the data fetch and wait for the
			operation to complete.
		  */
		  `GFSM_WAIT_FOR_TRIANGLE_FETCH:
		  begin
		  
				oNodeAddress			<= 0;
				oRequest_AABBIU		<= 0;	
				oRequest_BIU			<= 0;
				oTrigger_TFU			<= 0; //*
				oTrigger_TNF			<= 0; 
				ClearTriangleCount	<= 0;	
				IncTriangleCount		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_TFU;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				if ( iTriangleReadDone )
					NextState	<= `GFSM_TRIGGER_BIU_REQUSET;
				else
					NextState	<= `GFSM_WAIT_FOR_TRIANGLE_FETCH;
		  end

		  //------------------------------------------
		  /*
			Now that we got the traingle vertices in RAM,
			lets iEnable the BIU micro-code sub.
			*/
		  `GFSM_TRIGGER_BIU_REQUSET:
		  begin
		  
			`ifdef DEBUG2
				$display("******* GFSM_TRIGGER_BIU_REQUSET *******");
			`endif
		  
				oRequest_AABBIU		<= 0; 
				oNodeAddress			<= 0;
				oRequest_BIU	      <= 1; //*
				oTrigger_TFU			<= 
				//0;
				1;	///NEW NEW NEW Jan 25 2010, try to put this to 1
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 1;	//*		
				ClearTriangleCount	<= 0;	
				oWBM_Addr_Selector	<= 
				//`GFSM_SELECT_NULL;
				`GFSM_SELECT_TFU; //NEW NEW Paralell IO
				oSync						<= 1;//*
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				NextState	<= `GFSM_WAIT_FOR_BIU;
		  end
		  //------------------------------------------
		  /*
		  Once BIU finishes see have a hit.
		  There are severals paths to go here depnending on
		  wethher there was a Hit or Not, and also depending
		  on whether we the texturing capability enabled.
		  1) If there was a Hit, but the textures are not enabled,
		  then keep interating the triangle list.
		  2) If there was a Hit and the texturing is enabled,
		  then go to the state that request the texture 
		  coordiantes calculation
		  3) If there was not a Hit, then keep traversong the
		  triangle list.
		  4) If there is neither Hit or no-Hit yet, then keep
		  waiting is this state.
		  */
		  `GFSM_WAIT_FOR_BIU:
		  begin
												
				oRequest_AABBIU		<= 0; 
				oNodeAddress			<= 0;
				oRequest_BIU			<= 1; //*
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 0;	//*
				oWBM_Addr_Selector	<= 
				//`GFSM_SELECT_NULL;
				`GFSM_SELECT_TFU; //NEW NEW Paralell IO
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				if (iUCodeDone && iBIUHit && !iTexturingEnable)
					NextState <= `GFSM_CHECK_TRIANGLE_COUNT;
				else if (iUCodeDone && iBIUHit && iTexturingEnable)
				   NextState <= `GFSM_WAIT_STATE_PRE_TCC;
				else if (iUCodeDone && !iBIUHit)
					NextState <= `GFSM_CHECK_TRIANGLE_COUNT;
				else
					NextState <= `GFSM_WAIT_FOR_BIU;
		  end
		  //------------------------------------------
		  /*
		  Need to wait a extra cycle so that control unit will be able 
		  to get into the wait from geo sync state...it sucks I know...
		  */
		  `GFSM_WAIT_STATE_PRE_TCC:
		  begin
		      oRequest_AABBIU		<= 0; 
				oNodeAddress			<= 0;
				oRequest_BIU			<= 1; //*
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 0;	//*
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0;
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
								
				NextState <= `GFSM_REQUEST_TCC;
		  end
		  //------------------------------------------
		  
		  /*
		   This state request CU to trigger TCC, ie the code
			that is responsible of generating the 4
			memory addresses to get the texture coordinates:
			ie: OREG_TEX_COORD1 and OREG_TEX_COORD2, this coordinates are stored, and 
		   they replace the previous coordinates values only
			if the current traingle is closer to the camera.
		  */
		  `GFSM_REQUEST_TCC:
		  begin
		      
			//	$display("%d GFSM_REQUEST_TCC",$time);
			//	$display("GFSM_REQUEST_TCC %d oRequest_TCC = %d",$time,oRequest_TCC);
				
				
			   oRequest_AABBIU		<= 0; 
				oNodeAddress			<= 0;
				oRequest_BIU			<= 0; 
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 0;	
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;
				oSync						<= 1; //*
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 1; //*
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				
				NextState <= `GFSM_WAIT_FOR_TCC;
		  
		  end
		  //------------------------------------------
		  /*
		  If the textures coordinates are calculted then
		  move into the next triangle.
		  */
		  `GFSM_WAIT_FOR_TCC:
		  begin
		  
		//		$display("GFSM_WAIT_FOR_TCC %d oSync = %d",$time,oSync);
		//		$display("GFSM_WAIT_FOR_TCC %d oRequest_TCC = %d",$time,oRequest_TCC);
				
			   oRequest_AABBIU		<= 0; 
				oNodeAddress			<= 0;
				oRequest_BIU			<= 0; 
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 0;	
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 1; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
		  
			  if (iUCodeDone)
					NextState <= `GFSM_CHECK_TRIANGLE_COUNT;
				else
					NextState <= `GFSM_WAIT_FOR_TCC;
		  end
		  //------------------------------------------
/*		  `GFM_TRIGGER_TEXTURE_FETCH:
		  begin
				oRequest_AABBIU		<= 0; 
				oNodeAddress			<= 0;
				oRequest_BIU			<= 0; 
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 0;	
				oWBM_Addr_Selector	<= 0;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oTrigger_TFF			<= 1; 
				
				NextState <= `GFSM_WAIT_FOR_TEXTURE_FETCH;
	 	  end
		 
		  //------------------------------------------
		  `GFSM_WAIT_FOR_TEXTURE_FETCH:
		  begin
		  
		      oRequest_AABBIU		<= 0; 
				oNodeAddress			<= 0;
				oRequest_BIU			<= 0; 
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 0;	
				oWBM_Addr_Selector	<= 0;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oTrigger_TFF			<= 0; 
		  
		     if (iTextureReadDone == 1'b1)
					NextState <= `GFSM_CHECK_TRIANGLE_COUNT;
			  else
					NextState <= `GFSM_WAIT_FOR_TEXTURE_FETCH;
			  
		  end
		  */
		  //------------------------------------------
		  `GFSM_CHECK_NEXT_BROTHER:
		  begin
		  
				oRequest_AABBIU		<= 0; 
				oNodeAddress			<= 0;
				oRequest_BIU			<= 0; 
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 0;	//*
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
		  
				if ( iNode_Brother_Address == 0 )
					NextState <= `GFSM_CHECK_PARENTS_BROTHER;
				else
					NextState <= `GFSM_GET_BROTHER;
		  end
		  //------------------------------------------
		  `GFSM_GET_BROTHER:
		  begin
		  
				oRequest_AABBIU		<= 0; 	
				oNodeAddress			<= iNode_Brother_Address;	//*
				oRequest_BIU			<= 0; 
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				IncTriangleCount		<= 0;	//*
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
			
						
				NextState <= `GFSM_TRIGGER_NODE_FETCH;
		  end
		  //------------------------------------------
		  `GFSM_CHECK_PARENTS_BROTHER:
		  begin
		  
				
				oNodeAddress				<= 0;
				oRequest_AABBIU			<= 0; 
				oRequest_BIU				<= 0; 
				oTrigger_TFU				<= 0;	
				oTrigger_TNF				<= 0;
				IncTriangleCount		<= 0;	//*
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				if ( iNode_Parents_Brother_Address == 0)
					NextState <= `GFSM_DONE;
				else
					NextState <= `GFSM_GET_PARENTS_BROTHER;
		  end
		  //------------------------------------------
		  `GFSM_GET_PARENTS_BROTHER:
		  begin
				oRequest_AABBIU			<= 0; 	
				oNodeAddress 			<= iNode_Parents_Brother_Address;	//*
				oRequest_BIU				<= 0; 
				oTrigger_TFU		<= 0;	
				oTrigger_TNF		<= 0;
				IncTriangleCount		<= 0;	//*
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				
				NextState	<= `GFSM_TRIGGER_NODE_FETCH;
		  end
		  //------------------------------------------
		  `GFSM_TRIGGER_NODE_FETCH:
		  begin
				
				oRequest_AABBIU			<= 0; 
				oNodeAddress				<= iNode_Brother_Address;	
				oRequest_BIU				<= 0; 
				oTrigger_TFU		<= 1;	//*
				oTrigger_TNF		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				IncTriangleCount		<= 0;	//*
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
							
				NextState	<= `GFSM_WAIT_FOR_NODE_FETCH;
		  end
		  //------------------------------------------
		  /*
				Lets read the new node in our linked list.
				Once we got it we need to check AABB intersect,
				fetch traingles, etc, etc.
		  */
		  `GFSM_WAIT_FOR_NODE_FETCH:
		  begin
				
				oRequest_AABBIU			<= 0; 
				oNodeAddress				<= iNode_Brother_Address;	
				oRequest_BIU				<= 0; 
				oTrigger_TFU		<= 1;	
				oTrigger_TNF		<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_TFU;
				IncTriangleCount		<= 0;	//*
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				if (iNodeReadDone)
					NextState <= `GFSM_TRIGGER_AABBIU;
				else
					NextState <= `GFSM_WAIT_FOR_NODE_FETCH;
		  end
		  //------------------------------------------
		  `GFSM_DONE:
		  begin
		  
			`ifdef DEBUG2
				$display(" **** GFSM_DONE ***");
			`endif
				oNodeAddress				<= 0;
				oRequest_AABBIU			<= 0; 
				oRequest_BIU				<= 0; 
				oTrigger_TFU				<= 0;	
				oTrigger_TNF				<= 0;
				IncTriangleCount		<= 0;	//*
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				ClearTriangleCount	<= 0;
				oSync						<= 1; //*
				oDone						<= 1; //*
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
			
				if (iEnable == 0 )
					NextState <= `GFSM_INITIAL_STATE;
				else
					NextState <= `GFSM_DONE;
		  end
		  //------------------------------------------
		  default:
		  begin
		  
	 
				oRequest_AABBIU		<= 0; 	
				oNodeAddress			<= 0;	
				oRequest_BIU			<= 0; 
				oTrigger_TFU			<= 0;	
				oTrigger_TNF			<= 0;
				oWBM_Addr_Selector	<= `GFSM_SELECT_NULL;
				IncTriangleCount		<= 0;	//*
				oWBM_Addr_Selector	<= 0;
				ClearTriangleCount	<= 0;
				oSync						<= 0;
				oDone						<= 0;
				oSetTFUAddressOffset <= 0;
				oRequest_TCC         <= 0; 
				
				oEnable_WBM		      <= 0; 
				oSetAddressWBM		      <= 0;
				//IncTextureWriteAddress 	<= 0;
				IncTextureCount	      <= 0; 
				IncTextureCoordRegrAddr      <= 0; 
				oSetIOWriteBackAddr <= 0;
				//oRAMTextureStoreLocation <= `DATA_ADDRESS_WIDTH'd0;
				
				
				NextState <= `GFSM_AFTER_RESET;
		  end
		  endcase
	end
	//------------------------------------------------
endmodule
