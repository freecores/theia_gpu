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

The scene geomtry is assumed to be grouped in a balance tree, specifically a 
OCT tree. 
Geometry unit is responsible for traversing this tree and requesting the geoemtry
primitives accordingly.
The root of the tree has global information on the scene, and each node
can have up to 8 child nodes. Leafs can have geometry on it or not depending on the
tree generation algorith.
In the scenario where AABBIU is not used, the tree has a single node and a single leaf,
which is the the root of the tree.
The geomrty unit groups a series of modules that are in charge of fetching
the various types of geometry. Depending on weather you are using AABBIU or not
and wether you have texturing enabled or not, the way in which the primitives 
and data structures are requested varies.

***********************************************************************************/


`timescale 1ns / 1ps
`include "aDefinitions.v"

`define GFSM_SELECT_TFU 2'b00  //Triangle Fetch
`define GFSM_SELECT_TFF 2'b01  //Texture Fetch
`define GFSM_SELECT_TNF 2'b10  //Tree node fetch
`define GFSM_SELECT_NULL 2'b11

module GeometryUnit
(

	input  wire                           Clock,
	input  wire                           Reset,
	input  wire                           iEnable,
	input wire                            iTexturingEnable,
	input	wire [`WIDTH-1:0]               iData_WBM,		
	input wire                            iDataReady_WBM,
	output wire [`WIDTH-1:0]              oAddressWBM_Imm,
	output wire                           oAddressWBM_IsImm,
	output wire [`DATA_ADDRESS_WIDTH-1:0] oAddressWBM_fromMEM,
	output wire                           oEnable_WBM,
	output wire                           oSetAddressWBM,
	output wire                           oRequest_AABBIU,
	output wire                           oRequest_BIU,
	output wire                           oRequest_TCC,
	output wire[`DATA_ADDRESS_WIDTH-1:0]  oRAMWriteAddress,
	output wire                           oRAMWriteEnable,
	input wire                            iMicrocodeExecutionDone,
	input wire                            iMicroCodeReturnValue,
	output wire                           oRequestingTextures,
	input wire                            iTrigger_TFF,
	input wire                            iBIUHit,
	output wire                           oTFFDone,
	output wire                           oSync,
	output wire                           oSetIOWriteBackAddr,
	output wire                           oDone
);




	//Unit interconnections	
	wire wTrigger_TNF;                                 //Trigger Tree Node Fetch Unit.	GSFM -> TNF
	wire wTrigger_TFU;                                 //Trigger Data Fetch Unit.			GFSM -> TFU	
	//wire wTrigger_TFF;											//Trigger testure Fetch Unit.		GFSM -> TFF	
	wire [`WIDTH-1:0] wNodeAddress;                    //Address of the current Node. 	GFSM -> TNF
	wire [`WIDTH-1:0] wTNF2_TFU__TriangleDataOffset;   //Offset of the vertex Data.		TNF  -> GFSM
	wire [`WIDTH-1:0] wNode_TriangleCount;             //Number of traingles in this node. TNF -> GFSM
	wire [`WIDTH-1:0] wNode_Brother_Address;           //Address of the currents Node Brother. TNF -> GFSM
	wire [`WIDTH-1:0] wParents_Brother_Address;        //Address of the Brother of current node's parent. TNF -> GFSM
	wire [`WIDTH-1:0] wAddress_TFU;
	//wire [`DATA_ADDRESS_WIDTH-1:0] wAddress_TFF;
	wire [`WIDTH-1:0] wAddress_TNF;
	wire [`DATA_ADDRESS_WIDTH-1:0] wRAMWriteAddress_TFU;
	wire [`DATA_ADDRESS_WIDTH-1:0] wRAMWriteAddress_TFF;
	wire [`DATA_ADDRESS_WIDTH-1:0] wRAMWriteAddress_TNF;
	wire [1:0] wWBM_Address_Selector; 
	wire wTFN_Enable_WBM,wNode_IsLeaf;
	wire wTNF2__SetAddressWBM, wTFU2__SetAddressWBM,wTFF2__SetAddressWBM;
	wire wRAMWriteEnable_TFF;
	wire wNodeReadDone,wRAMWriteEnable_TNF,wTriangleReadDone,wTextureFetchDone;
	wire wTFU_Trigger_WBM,wTFF_Trigger_WBM,wRAMWriteEnable_TFU;
	wire wGFSM2_TFU__SetAddressOffset;

assign oEnable_WBM = wTFN_Enable_WBM ^ wTFU_Trigger_WBM ^ wTFF_Trigger_WBM; //XXX TODO: Wath out!


assign oRequestingTextures = (wWBM_Address_Selector == `GFSM_SELECT_TFF ) ? 1 : 0;
assign oAddressWBM_Imm = ( wWBM_Address_Selector == `GFSM_SELECT_TFU ) ? wAddress_TFU : wAddress_TNF;
assign oRAMWriteEnable = ( wWBM_Address_Selector == `GFSM_SELECT_TFU ) ? wRAMWriteEnable_TFU : wRAMWriteEnable_TNF;

assign oAddressWBM_IsImm = 
( !iTexturingEnable || (iTexturingEnable &&
 (wWBM_Address_Selector == `GFSM_SELECT_TFU || wWBM_Address_Selector == `GFSM_SELECT_TNF) )) 
 ? 1'b1 : 1'b0;

//--------------------------------------------------------
//Mux for oRAMWriteAddress
MUXFULLPARALELL_16bits_2SEL_X MUXGE_1B
(
	.I1( wRAMWriteAddress_TFU ),
	.I2( wRAMWriteAddress_TFF ),
	.I3( wRAMWriteAddress_TNF ),
	.O1( oRAMWriteAddress ),
	.Sel( wWBM_Address_Selector ) 
);

//--------------------------------------------------------

assign oSetAddressWBM = wTNF2__SetAddressWBM | wTFU2__SetAddressWBM | wTFF2__SetAddressWBM;


//------------------------------------------------	

/*
	Tree node fetcher: Takes care of resquesting 
	node information. TNF requests Read Bus Cycles 
	from the Wish Bone Master Unit. TNF is controlled
	by the GFSM.
*/
TreeNodeFetcher TNF
(
	.Clock( Clock ),
	.Reset( Reset ),
	.iData(                    iData_WBM                     ),
	.iDataAvailable(           iDataReady_WBM                ),
	.oEnableWBM(         wTFN_Enable_WBM              ),
	.oSetAddressWBM(           wTNF2__SetAddressWBM          ),
	.oAddressWBM(              wAddress_TNF                  ),
	.iInitialAddress(          wNodeAddress                  ),
	.iTrigger(                 wTrigger_TNF                  ),
	.oNode_IsLeaf(             wNode_IsLeaf                  ),
	.oNodeReadDone(            wNodeReadDone                 ),
	.oNode_TriangleCount(      wNode_TriangleCount           ),
	.oNode_Brother_Address(    wNode_Brother_Address         ),
	.oParents_Brother_Address( wParents_Brother_Address      ),
	.oNode_DataOffset(         wTNF2_TFU__TriangleDataOffset ),
	.oRAMWriteEnable(          wRAMWriteEnable_TNF           ),
	.oRAMWriteAddress(         wRAMWriteAddress_TNF          )
	
);
//------------------------------------------------
/*
	Triangle Fetch Unit: Takes care of resquesting 
	triangle information. TFU requests Read Bus Cycles 
	from the Wish Bone Master Unit. TFU is controlled
	by the GFSM.
*/	
TriangleFetchUnit TFU
(
	.Clock( Clock ),
	.Reset( Reset ),
	.iTrigger(                     wTrigger_TFU                  ),
	.iInitialAddress(              wTNF2_TFU__TriangleDataOffset ),
	.iSetAddressOffset(            wGFSM2_TFU__SetAddressOffset  ),
	.iDataAvailable(               iDataReady_WBM                ),
	.oAddressWBM(                  wAddress_TFU                  ),
	.oSetAddressWBM(               wTFU2__SetAddressWBM          ),
	.oTriggerWBM(                  wTFU_Trigger_WBM              ),
	.oRAMWriteEnable(              wRAMWriteEnable_TFU           ),
	.iCR_TextureMappingEnabled(    iTexturingEnable              ),
	.oRAMWriteAddress(             wRAMWriteAddress_TFU          ),
	.oDone(                        wTriangleReadDone             )
);	

//------------------------------------------------	
/*
	Geometry Fetch Finite State Machine: Takes care of resquesting 
	the control of the various geometry fetching routines. It controls
	TFF,TFU and TNF.
*/
GeometryFetchFSM  GFSM //TODO: Add new states to fetch the texures
(
	.Clock( Clock ), 
	.Reset( Reset ), 
	.iBIUHit(                       iBIUHit                      ),
	.iTexturingEnable(              iTexturingEnable             ),
	.iEnable(                       iEnable                      ),
	.iAABBIUHit(                    iMicroCodeReturnValue        ),
	.iUCodeDone(                    iMicrocodeExecutionDone      ),
	.iTriangleReadDone(             wTriangleReadDone            ),
	.iNode_TriangleCount(           wNode_TriangleCount          ),
	.iNode_Brother_Address(         wNode_Brother_Address        ),
	.iNode_Parents_Brother_Address( wParents_Brother_Address     ),
	.iNode_IsLeaf(                  wNode_IsLeaf                 ), 
	.iNodeReadDone(                 wNodeReadDone                ),
	.oTrigger_TNF(                  wTrigger_TNF                 ),
	.oTrigger_TFU(                  wTrigger_TFU                 ),
	.oNodeAddress(                  wNodeAddress                 ),
	.oRequest_AABBIU(               oRequest_AABBIU              ),
	.oRequest_BIU(                  oRequest_BIU                 ),
	.oRequest_TCC(                  oRequest_TCC                 ),
	.oWBM_Addr_Selector(            wWBM_Address_Selector        ), 
	.oSync(                         oSync                        ),
	.oSetTFUAddressOffset(          wGFSM2_TFU__SetAddressOffset ),
	.oDone(                         oDone                        ),
	.iDataAvailable(    				  iDataReady_WBM               ),
	.oEnable_WBM(       			  wTFF_Trigger_WBM             ),
	.oAddressWBM(       				  oAddressWBM_fromMEM          ),
	.oSetAddressWBM(    				  wTFF2__SetAddressWBM         ),
	.iTrigger_TFF(                  iTrigger_TFF                 ),
	.oSetIOWriteBackAddr(           oSetIOWriteBackAddr          ),
	.oRAMTextureStoreLocation(      wRAMWriteAddress_TFF         )

);
assign oTFFDone = oDone;

//-------------------------------------------------	


endmodule
