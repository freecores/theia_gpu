
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


/*******************************************************************************
Module Description:

This is the Main test bench of the GPU. It simulates the behavior of
an external control unit or CPU that sends configuration information into DUT.
It also implements a second processs that simulates a Wishbone slave that sends 
data from an external memory. These blocks are just behavioral CTE and therefore
are not meant to be synthethized.

*******************************************************************************/


`timescale 1ns / 1ps
`include "aDefinitions.v"
`define CONFIGURATION_PHASE 						0
`define CTE_INITIAL_STATE 							0
`define CTE_IDLE 										1
`define CTE_START_EU_CONFIGURATION_SEQUENCE 	2
`define CTE_SEND_CONFIGURATION_PACKET			3
`define CTE_ACK_CONFIGURATION_PACKET  			8
`define CTE_SEND_LIGHT_PACKET						13
`define CTE_ACK_LIGTH_PACKET						14
`define CTE_SEND_RAY_I_TASK						15
`define CTE_WAIT_FOR_TASK_ACK						16
`define WAIT_FOR_TASK_COMPLETE					17
`define CTE_PREPARE_NEW_TASK						18
`define CTE_RENDER_DONE								19
`define CTE_READ_COLOR_DATA						20
`define CTE_GRANT_BUS_WRITE_PERMISION			21
`define CTE_ACK_GRANT_BUS_PERMISION				22
`define CTE_ACK_READ_COLOR_DATA					23
`define CTE_SEND_TEXTURE_DIMENSIONS				24
`define CTE_ACK_TEXTURE_DIMENSIONS				25




`define RESOLUTION_WIDTH			 				(rSceneParameters[12] >> `SCALE)
`define RESOLUTION_HEIGHT 							(rSceneParameters[13] >> `SCALE)
`define RAYI_TASK										1
`define DELTA_ROW 									(32'h1 << `SCALE)
`define DELTA_COL 									(32'h1 << `SCALE)

`define SELECT_ALL_CORES `MAX_CORES'b1111; 
module TestBench_Theia;


	//------------------------------------------------------------------------
	//**WARNING: Declare all of your varaibles at the begining
	//of the file. I hve noticed that sometimes the verilog
	//simulator allows you to use some regs even if they have not been 
	//previously declared, leadeing to crahses or unexpected behavior
	// Inputs
	reg Clock;
	reg Reset;
	reg ExternalBus_DataReady;

	// Outputs
	wire ExternalBus_Acknowledge;
	wire TaskCompleted;

	//CTE state machin logic
	
	reg[31:0] CurrentState,NextState;
	reg[3:0]	 LightCount;
	reg[31:0] rLaneA,rLaneB,rLaneC,rLaneD;
	reg[16:0] CurrentTaskId;
	reg[31:0] CurrentPixelRow, CurrentPixelCol,CurrentRayType;
	
	reg CTE_WriteEnable;
	wire [`WB_WIDTH-1:0] DAT_O;
	
	reg		  				ACK_O;
	wire						ACK_I;
	wire [`WB_WIDTH-1:0] ADR_I,ADR_O;
	wire 						WE_I,STB_I;
	reg CYC_O,WE_O,TGC_O,STB_O;
	wire [1:0] TGC_I;
	reg [1:0] TGA_O;
	wire [1:0] TGA_I;
	wire [31:0] DAT_I;
	integer ucode_file;
	
	
	reg [31:0] rInitialCol,rInitialRow; 
	reg [31:0] 	rControlRegister[2:0]; 
	

	integer file, log, r, a, b;
	
	
	reg [31:0]  rSceneParameters[64:0];
	reg [31:0] 	rVertexBuffer[6000:0];
	reg [31:0] 	rInstructionBuffer[512:0];
	`define TEXTURE_BUFFER_SIZE (256*256*3)
	reg [31:0]  rTextures[`TEXTURE_BUFFER_SIZE:0];		//Lets asume we use 256*256 textures
	
	integer i,j;
	`define MAX_WIDTH 200
	`define MAX_SCREENBUFFER (`MAX_WIDTH*`MAX_WIDTH*3)
	reg [7:0] rScreen[`MAX_SCREENBUFFER-1:0];
	
	//------------------------------------------------------------------------
	//Debug registers
	`define TASK_TIMEOUTMAX 150000//50000
	

	
	//------------------------------------------------------------------------

	
	
		reg MST_O;
//---------------------------------------------------------------	
reg rIncCoreSelect;
wire [`MAX_CORES-1:0] wCoreSelect;
CIRCULAR_SHIFTLEFT_POSEDGE_EX # (`MAX_CORES ) SHF1
( 
	.Clock( Clock ), 
	.Reset( Reset ),
	.Initial(`MAX_CORES'b1), 
	.Enable(rIncCoreSelect),
	.O(wCoreSelect)
);


wire [3:0] CYC_I,GNT_O;
wire wDone;
reg [`MAX_CORES-1:0] rCoreSelectMask,rRenderEnable;

THEIA GPU 
		(
		.CLK_I( Clock ), 
		.RST_I( Reset ), 
		.RENDREN_I( rRenderEnable ),
		.DAT_I( DAT_O ),
		.ADR_O( ADR_I ),
		.ACK_I( ACK_O ),
		.WE_O ( WE_I ),
		.STB_O( STB_I ),
		
		.CYC_I( CYC_O ),
		.TGC_O( TGC_I ),
		.MST_I( MST_O ),
		.TGA_I( TGA_O ),
		.ACK_O( ACK_I ),
		.ADR_I( ADR_O ),
		.DAT_O( DAT_I ),
		.WE_I(  WE_O  ),
		.SEL_I( wCoreSelect | rCoreSelectMask),//4'b0001 ),
		.STB_I( STB_O ),
		.TGA_O(TGA_I),

		//Control register
		.CREG_I( rControlRegister[0][15:0] ),
		//Other stuff
		.DONE_O( wDone )

	);




	//---------------------------------------------
	//generate the clock signal here
	always begin
		#`CLOCK_CYCLE  Clock =  ! Clock;
	
	end
	//---------------------------------------------

reg [15:0] rTimeOut;
		
		`define MAX_INSTRUCTIONS 2
		
	initial begin
		// Initialize Inputs
		
				
		Clock 					= 0;
		Reset 					= 0;
		CTE_WriteEnable 		= 0;
		rLaneA					= 32'b0;
		rLaneB					= 32'b0;
		rLaneC					= 32'b0;
		rLaneD					= 32'b0;
		ExternalBus_DataReady = 0;
		rTimeOut              = 0;
		
		
				
	`ifdef DUMP_CODE
		$write("Opening TestBench.log.... ");
		ucode_file = $fopen("TestBench.log","w");
		$display("Done");
	`endif
	
		//Read Config register values
		$write("Loading control register.... ");
		$readmemh("Creg.mem",rControlRegister);
		$display("Done");
		
		
			
		//Read configuration Data
		$write("Loading scene parameters.... ");
		$readmemh("Params.mem",	rSceneParameters	);
		$display("Done");
		
		rInitialRow = rSceneParameters[18];
		rInitialCol = rSceneParameters[19];
		
		//Read Scene Data
		$write("Loading scene geometry.... ");
		$readmemh("Vertex.mem",rVertexBuffer);
		$display("Done");
		
		//Read Texture Data
		$write("Loading scene texture.... ");
		$readmemh("Textures.mem",rTextures);
		$display("Done");
		

		//Read instruction data
		$write("Loading code allocation table and user shaders.... ");
		$readmemh("Instructions.mem",rInstructionBuffer);
		$display("Done");
		
		$display("Control Register : %b",rControlRegister[0]);
		$display("Initial Row      : %h",rInitialRow);
		$display("Initial Column   : %h",rInitialCol);
		$display("Resolution       : %d X %d",`RESOLUTION_WIDTH, `RESOLUTION_HEIGHT );
	
		//Open output file
		file = $fopen("Output.ppm");
		log  = $fopen("Simulation.log");
		$fwrite(log, "Simulation start time : %dns\n",$time);
		$fwrite(log, "Width : %d\n",`RESOLUTION_WIDTH);
		$fwrite(log, "Height : %d\n",`RESOLUTION_HEIGHT);
				
		$fwrite(file,"P3\n");
		$fwrite(file,"#This file was generated by Theia's RTL simulation\n");
		$fwrite(file,"%d %d\n",`RESOLUTION_WIDTH, `RESOLUTION_HEIGHT );
		$fwrite(file,"255\n");
		
		CurrentPixelRow = 0;
		CurrentPixelCol = 0;
		#10
		Reset = 1;
		ExternalBus_DataReady = 0;

		// Wait 100 ns for global reset to finish
		#100  Reset = 0;  
	
	end
	
	reg [5:0] DataIndex;
	reg [31:0] ConfigurationPacketSize;
	
	reg [7:0] R,G,B;
	

//---------------------------------------------

always @ (posedge Clock)
begin
	rTimeOut = rTimeOut+1'b1;
	if (rTimeOut > `TASK_TIMEOUTMAX)
	begin
		 $display("%dns ERROR: THEIA Timed out after %d of inactivity\n",
		 $time(),rTimeOut);
		 $stop();
	end
end

reg [31:0] rSlaveData_O;
//reg [31:0] rOutputFrameBuffer[39000:0];
reg [31:0] rColor;

reg [7:0] Thingy;
//Wish-Bone Slave logic.
//
//This logic represents a WBS FSM. It will provide
//the memory for Vertex and Texture data.
//Vertex/Tetxure data is stored in a 4GB RAM.
//Vertex data starts at address 0 and ends at address 0x80_000_000.
//Texture data starts at address 0x80_000_000 and ends at address
//0xFFFFFFFF.
//The Bit 31, indcates wheather we look for vertex (b=0)
//or texture (b=1)
	
`define WBS_AFTER_RESET					0
`define WBS_MOINTOR_STB_I				1
`define WBS_ACK_O							2
`define WBS_MOINTOR_STB_I_NEG			3	
`define WBS_DONE                    4

	reg [7:0] 			WBSCurrentState,WBSNextState;
	reg [31:0]			rAddress;
	
	always @(negedge Clock)
	begin
        if( Reset!=1 )
           WBSCurrentState = WBSNextState;
		  else
			  WBSCurrentState = `WBS_AFTER_RESET;		
	end
      
	

	reg [31:0] rConvertedTextureAddress;
	//----------------------------------------------------------	
	always @(posedge Clock)
	begin
		case (WBSCurrentState)
		//----------------------------------------
		`WBS_AFTER_RESET:
		begin
			ACK_O = 0;
			rSlaveData_O = 32'b0;
			
			WBSNextState = `WBS_MOINTOR_STB_I;
		end
		//----------------------------------------
		`WBS_MOINTOR_STB_I:
		begin
				if ( STB_I == 1 && wDone == 0)
				WBSNextState = `WBS_ACK_O;
			else if (STB_I == 0 && wDone == 0)	
				WBSNextState = `WBS_MOINTOR_STB_I;
			else
				WBSNextState = `WBS_DONE;
		end
		//----------------------------------------
		`WBS_ACK_O:
		begin
			if (WE_I == 0)
			begin
				
				rAddress = ADR_I;
				if (TGA_I == 2'b01) //replace this by TGA_I
				begin
				 //Multiply pithc (3), Add 2 because the first 2 bytes are text Width, Height
				rConvertedTextureAddress = {1'b0,rAddress[30:0]} + 2;
				if (rConvertedTextureAddress >= `TEXTURE_BUFFER_SIZE)
					rConvertedTextureAddress = `TEXTURE_BUFFER_SIZE-1;
					
				
					rSlaveData_O = rTextures[  rConvertedTextureAddress ];
					`ifdef DEBUG_WBM
					
					`LOGME"WB SLAVE: MASTER Requested read from texture address: %h (%d)Data = %h \n",rAddress, rConvertedTextureAddress,DAT_O );
					`endif
				end	
				else
				begin
			//		Thingy = 0;  //THIS IS NOT RE-ENTRANT!!!
					rSlaveData_O = rVertexBuffer[ rAddress ];
					`ifdef DEBUG_WBM
					`LOGME"WB SLAVE: MASTER Requested read from vertex address: %h Data = %h\n",rAddress,DAT_O);
					`endif
				end	
				
			end
			else
			begin
			//	$display("%d Theia Writes value: %h @ %d (Time to process pixel %d Clock cycle)",$time, DAT_I,ADR_I,rTimeOut);
			
			
		//	if (Thingy == 0)
		//	begin
				
		//	end	
			
		//	Thingy = Thingy + 1;
			if (CurrentPixelCol >= 	(`RESOLUTION_WIDTH*3))
			begin
				CurrentPixelCol = 0;
				CurrentPixelRow = CurrentPixelRow + 1;
				$display("]- %d (%d)",CurrentPixelRow,ADR_I);
				$write("[");
			end
			
		//	if (Thingy == 3)
		//	begin
				CurrentPixelCol = CurrentPixelCol + 1;
				if ( CurrentPixelCol % 3  == 0)
				begin
			//	$fwrite(file,"\n# %d %d\n",CurrentPixelRow,CurrentPixelCol);
				$write(".");
				end
				//Thingy = 0;
		//	end	
				rTimeOut = 0;
				R = ((DAT_I >> (`SCALE-8)) > 255) ? 255 : (DAT_I >>  (`SCALE-8));
				rScreen[ ADR_I ] = R;
			//	$fwrite(file,"%d " , R );
		
			end
			
			
			ACK_O = 1;

		//	if (CurrentPixelRow >= `RESOLUTION_HEIGHT)
		if (wDone)
				WBSNextState = `WBS_DONE;
			else
				WBSNextState = `WBS_MOINTOR_STB_I_NEG;
		end
		//----------------------------------------
		`WBS_MOINTOR_STB_I_NEG:
		begin
			if ( STB_I == 0 )
			begin
				ACK_O = 0;
				WBSNextState = `WBS_MOINTOR_STB_I;
			end	
			else
				WBSNextState = `WBS_MOINTOR_STB_I_NEG;
		end
		//----------------------------------------
		`WBS_DONE:
		begin
		for (j = 0; j < `RESOLUTION_WIDTH; j = j+1)
		begin
			
			for (i = 0; i < `RESOLUTION_HEIGHT*3; i = i +1)
			begin
		   
			$fwrite(file,"%d " , rScreen[i+j*`RESOLUTION_WIDTH*3] );
				if ((i %3) == 0)
						$fwrite(file,"\n# %d %d\n",i,j);
				
			end
		end	
		$display("RESOLUTION_WIDTH = %d,RESOLUTION_HEIGHT= %d",
		`RESOLUTION_WIDTH,`RESOLUTION_HEIGHT);
		$display("ADR_I = %d\n",ADR_I);
			`LOGME"RENDER COMPLETE");
			`LOGME"Closing File");
			$fclose(file);
			$fwrite(log, "Simulation end time : %dns\n",$time);
			$fclose(log);
			`LOGME"File Closed");
			$stop();
			$fclose(ucode_file);
		end
		//----------------------------------------
		default:
		begin
		$display("WBS Undefined state");
		end
		endcase
	end	//end always
	//----------------------------------------------------------	




`define TAG_BLOCK_WRITE_CYCLE    2'b01
`define TAG_INSTRUCTION_ADDRESS_TYPE 2'b01
`define TAG_DATA_ADDRESS_TYPE        2'b10
		
`define WBM_AFTER_RESET							0
`define WBM_WRITE_INSTRUCTION_PHASE1		1
`define WBM_ACK_INSTRUCTION_PHASE1			2
`define WBM_WRITE_INSTRUCTION_PHASE2		3	
`define WBM_ACK_INSTRUCTION_PHASE2			4
`define WBM_END_INSTRUCTION_WRITE_CYCLE   5
`define WBM_SEND_DATA_PHASE1			      6
`define WBM_ACK_DATA_PHASE1			      7
`define WBM_SEND_DATA_PHASE2			      8	
`define WBM_ACK_DATA_PHASE2			      9
`define WBM_SEND_DATA_PHASE3			      10	
`define WBM_ACK_DATA_PHASE3			      11
`define WBM_END_DATA_WRITE_CYCLE          12
`define WBM_DONE                          13
`define WBM_CONFIGURE_CORE0_PHASE1        14
`define WBM_ACK_CONFIGURE_CORE0_PHASE1    15
`define WBM_CONFIGURE_CORE0_PHASE2        16
`define WBM_ACK_CONFIGURE_CORE0_PHASE2    17
`define WBM_CONFIGURE_CORE0_PHASE3        18
`define WBM_ACK_CONFIGURE_CORE0_PHASE3    19
`define WBM_CONFIGURE_CORE1_PHASE1        20
`define WBM_ACK_CONFIGURE_CORE1_PHASE1    21
`define WBM_CONFIGURE_CORE1_PHASE2        22
`define WBM_ACK_CONFIGURE_CORE1_PHASE2    23
`define WBM_CONFIGURE_CORE1_PHASE3        24
`define WBM_ACK_CONFIGURE_CORE1_PHASE3    25
`define WBM_END_CORE0_WRITE_CYCLE         26
`define WBM_END_CORE1_WRITE_CYCLE         27

`define WBM_CONFIGURE_CORE2_PHASE1        28
`define WBM_ACK_CONFIGURE_CORE2_PHASE1    29
`define WBM_CONFIGURE_CORE2_PHASE2        30
`define WBM_ACK_CONFIGURE_CORE2_PHASE2    31
`define WBM_CONFIGURE_CORE2_PHASE3        32
`define WBM_ACK_CONFIGURE_CORE2_PHASE3    33
`define WBM_CONFIGURE_CORE3_PHASE1        34
`define WBM_ACK_CONFIGURE_CORE3_PHASE1    35
`define WBM_CONFIGURE_CORE3_PHASE2        36
`define WBM_ACK_CONFIGURE_CORE3_PHASE2    37
`define WBM_CONFIGURE_CORE3_PHASE3        38
`define WBM_ACK_CONFIGURE_CORE3_PHASE3    39
`define WBM_END_CORE2_WRITE_CYCLE         40
`define WBM_END_CORE3_WRITE_CYCLE         41
`define WBM_CONFIGURE_NEXT_CORE           42


reg[31:0] rInstructionPointer;
reg[31:0] rAddressToSend;
reg[31:0] rDataAddress;
reg[31:0] rDataPointer;

reg IncIP,IncIA,IncDP;
reg rPrepateWriteAddressForNextCore;
reg rClearOutAddress;
//-----------------------------------------------------
always @ (posedge Clock or posedge rClearOutAddress)
begin

	if ( IncIA && ~rClearOutAddress)
		rAddressToSend = rAddressToSend + 1;
	else if (rClearOutAddress)
	begin
		if (TGA_O == `TAG_INSTRUCTION_ADDRESS_TYPE)
			rAddressToSend =  {16'd1,16'd0};
		else if (rPrepateWriteAddressForNextCore)
			rAddressToSend = `CREG_PIXEL_2D_INITIAL_POSITION;
		else
			rAddressToSend = 0;
	end	
		
	
end
//-----------------------------------------------------
always @ (posedge ACK_I or posedge Reset )
begin

	if ( ACK_I && ~Reset)
		rInstructionPointer = rInstructionPointer + 1;
	else if (Reset)
		rInstructionPointer = 0;
		
	
	
end
//-----------------------------------------------------
reg rResetDp;

always @ (posedge Clock or posedge rResetDp )
begin

	if ( ACK_I && ~rResetDp)//IncDP && ~Reset)
		rDataPointer = rDataPointer + 1;
	else if (rResetDp)
		rDataPointer =  32'b0;
		
	
end

reg rIncPacketCount;
reg [`WIDTH-1:0] rPacketCount;

always @ (posedge Clock)
begin
	if (Reset)
		rPacketCount = 0;
	else	
	begin
		if ( rIncPacketCount )
			rPacketCount = rPacketCount + 1;
	end		
end
//-----------------------------------------------------




assign DAT_O = ( MST_O == 1'b1 ) ? wMasteData_O : rSlaveData_O;

wire[31:0] wMasteData_O;



assign wMasteData_O = (TGA_O == `TAG_INSTRUCTION_ADDRESS_TYPE) ? rInstructionBuffer[rInstructionPointer+1] : rSceneParameters[ rDataPointer  ];


always @ (posedge STB_O)
begin
	if (TGA_O == `TAG_INSTRUCTION_ADDRESS_TYPE)
	begin
		//$display("-- %x\n",wMasteData_O);
	end
end
assign ADR_O = rAddressToSend;

	reg [7:0] 			WBMCurrentState,WBMNextState;
	reg [31:0]			rWriteAddress;
	
	always @(posedge Clock or posedge Reset)
	begin
        if( Reset!=1 )
           WBMCurrentState = WBMNextState;
		  else
			  WBMCurrentState = `WBM_AFTER_RESET;		
	end
      
		wire[31:0] wConfigurationPacketSize; 
		assign wConfigurationPacketSize = rSceneParameters[2];
	
   reg [31:0]  InstructionIndex;
	reg [31:0]  InstructionWriteAddress;
	//Send the instructions now...
	//----------------------------------------------------------	
	always @(posedge Clock)
	begin
		case (WBMCurrentState)
		//----------------------------------------
		
		//Wait until the reset secuence is complete to
		//begin sending stuff.
		
		`WBM_AFTER_RESET:
		begin
			WE_O <=  0;													
			CYC_O <= 0;													
			TGC_O <= 0;						
			TGA_O <= `TAG_INSTRUCTION_ADDRESS_TYPE;   		
			STB_O <= 0;													
		//	IncIP <= 0;
			IncIA <= 0;
			MST_O	<= 0;
			IncDP <= 0;	
			rResetDp <= 1;
			rClearOutAddress <= 1;
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;
			rIncPacketCount <= 0;
			
			if (Reset == 0)
				WBMNextState <= `WBM_WRITE_INSTRUCTION_PHASE1;
			else
				WBMNextState <= `WBM_AFTER_RESET;
		end
		//----------------------------------------
		
		//CLOCK EDGE 0: MASTER presents a valid address on [ADR_O()]
		//MASTER presents valid data on [DAT_O()]
		//MASTER asserts [WE_O] to indicate a WRITE cycle.
		//MASTER asserts [CYC_O] and [TGC_O()] to indicate the start of the cycle.
		//MASTER asserts [STB_O] to indicate the start of the phase.
		
		`WBM_WRITE_INSTRUCTION_PHASE1:
		begin
			WE_O <=  1;													//Indicate write cycle
			CYC_O <= 1;													//Start of the cycle
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						//TAG CYCLE: 10 indicated multiple write Cycle
			TGA_O <= `TAG_INSTRUCTION_ADDRESS_TYPE;   		//TAG Address: 01 means instruction address type.
			STB_O <= ~ACK_I;											//Start of phase (you put this in zero to introduce wait cycles)
		//	IncIP <= 0;
			IncIA <= 0;	
			MST_O	<= 1;	
			IncDP <= 0;		
			rResetDp <= 1;
			rClearOutAddress <= 0;
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;			
						rIncPacketCount <= 0;
			
			if ( ACK_I )
				WBMNextState <= `WBM_ACK_INSTRUCTION_PHASE1;
			else
				WBMNextState <= `WBM_WRITE_INSTRUCTION_PHASE1;
			
		end
		//----------------------------------------
		`WBM_ACK_INSTRUCTION_PHASE1:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_INSTRUCTION_ADDRESS_TYPE;   		
			STB_O <= 0;	//*											//Negate STB_O in response to ACK_I
		//	IncIP <= 1;	//*											//Increment local inst pointer to send the next 32 bits					
			IncIA <= 0;													//leave the instruction write address the same
			MST_O	<= 1;
			IncDP <= 0;	
			rResetDp <= 1;
			rClearOutAddress <= 0;
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
						
			if (ACK_I == 0)
				WBMNextState <= `WBM_WRITE_INSTRUCTION_PHASE2;
			else
				WBMNextState <= `WBM_ACK_INSTRUCTION_PHASE1;
		end
		//----------------------------------------
		`WBM_WRITE_INSTRUCTION_PHASE2:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_INSTRUCTION_ADDRESS_TYPE;   		
			STB_O <= ~ACK_I;	
		//	IncIP <= 0;
			IncIA <= 0;	
			MST_O	<= 1;
			IncDP <= 0;	
			rResetDp <= 1;		
			rClearOutAddress <= 0;			
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;	
			rPrepateWriteAddressForNextCore <= 0;
			rIncPacketCount <= 0;
			
			if ( ACK_I )
				WBMNextState <= `WBM_ACK_INSTRUCTION_PHASE2;
			else
				WBMNextState <= `WBM_WRITE_INSTRUCTION_PHASE2;
			
		end
		//----------------------------------------
		`WBM_ACK_INSTRUCTION_PHASE2:
		begin
			WE_O <=  1;													
			CYC_O <= 0;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_INSTRUCTION_ADDRESS_TYPE;   		
			STB_O <= 0;	//*
			
			MST_O	<= 1;		
			IncDP <= 0;	
			rResetDp <= 1;	
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;	
			rPrepateWriteAddressForNextCore <= 0;		
			rIncPacketCount <= 0;
			
			
		if (rInstructionPointer >= rInstructionBuffer[0])
		begin
				IncIA <= 0;//*	
				rClearOutAddress <= 1;
				WBMNextState	<= `WBM_SEND_DATA_PHASE1;		
		end		
		else
		begin	
				IncIA <= 1;//*	
				rClearOutAddress <= 0;
				WBMNextState <= `WBM_WRITE_INSTRUCTION_PHASE1;
		end		

		end
	//****************************************
	`WBM_SEND_DATA_PHASE1:
		begin
			WE_O <=  1;													//Indicate write cycle
			CYC_O <= 1;													//Start of the cycle
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						//TAG CYCLE: 10 indicated multiple write Cycle
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		//TAG Address: 01 means instruction address type.
			STB_O <= ~ACK_I;											//Start of phase (you put this in zero to introduce wait cycles)
			IncIA <= 0;	
			MST_O	<= 1;		
			IncDP <= 0;	
			rResetDp <= 0;		
			rClearOutAddress <= 0;			
			rCoreSelectMask <= `SELECT_ALL_CORES;	
			rRenderEnable <= 0;	
			rPrepateWriteAddressForNextCore <= 0;	
			rIncPacketCount <= 0;
			
			
			if ( ACK_I )
				WBMNextState <= `WBM_ACK_DATA_PHASE1;
			else
				WBMNextState <= `WBM_SEND_DATA_PHASE1;
			
		end
		//----------------------------------------
		`WBM_ACK_DATA_PHASE1:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		
			STB_O <= 0;	//*											//Negate STB_O in response to ACK_I
		//	IncIP <= 1;	//*											//Increment local inst pointer to send the next 32 bits					
			IncIA <= 0;													//leave the instruction write address the same
			MST_O	<= 1;
			IncDP <= 0;	
			rResetDp <= 0;
			rClearOutAddress <= 0;
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
			
			
			
			if (ACK_I == 0)
				WBMNextState <= `WBM_SEND_DATA_PHASE2;
			else
				WBMNextState <= `WBM_ACK_DATA_PHASE1;
		end
		//----------------------------------------
		`WBM_SEND_DATA_PHASE2:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		
			STB_O <= ~ACK_I;	
		//	IncIP <= 0;
			IncIA <= 0;	
			MST_O	<= 1;	
			IncDP <= 0;	
			rResetDp <= 0;		
			rClearOutAddress <= 0;			
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;			
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
			
			
			if ( ACK_I )
				WBMNextState <= `WBM_ACK_DATA_PHASE2;
			else
				WBMNextState <= `WBM_SEND_DATA_PHASE2;
			
		end
		//----------------------------------------
		`WBM_ACK_DATA_PHASE2:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		
			STB_O <= 0;	//*
			IncIA <= 0;	
			MST_O	<= 1;	
			IncDP <= 0;//*		
			rResetDp <= 0;
			rClearOutAddress <= 0;
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
			
			
			
			if (ACK_I == 0)
				WBMNextState <= `WBM_SEND_DATA_PHASE3;
			else
				WBMNextState <= `WBM_ACK_DATA_PHASE2;
			
		end
		//----------------------------------------
		`WBM_SEND_DATA_PHASE3:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		
			STB_O <= ~ACK_I;	
		//	IncIP <= 0;
			IncIA <= 0;	
			MST_O	<= 1;	
			IncDP <= 0;		
			rResetDp <= 0;
			rClearOutAddress <= 0;
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;			
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
			
			
			
			if ( ACK_I )
				WBMNextState <= `WBM_ACK_DATA_PHASE3;
			else
				WBMNextState <= `WBM_SEND_DATA_PHASE3;
			
		end
		//----------------------------------------
		`WBM_ACK_DATA_PHASE3:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		
			STB_O <= 0;	//*
			IncIA <= 0;	
			MST_O	<= 1;	
			IncDP <= 1;//*		
			rResetDp <= 0;
			rClearOutAddress <= 0;
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
			
			
			
			WBMNextState <= `WBM_END_DATA_WRITE_CYCLE;
			
		end
		//----------------------------------------
		`WBM_END_DATA_WRITE_CYCLE:
		begin
			WE_O <=  0;													
			CYC_O <= 0;	//*												
			TGC_O <= 0;						
			TGA_O <= 0;   		
			STB_O <= 0;	
			IncIA <= 1;//*		
			MST_O	<= 1;		
			IncDP <= 0;		
			rResetDp <= 0;
			rClearOutAddress <= 0;
			rCoreSelectMask <= `SELECT_ALL_CORES;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
			
			
			
			if (rDataPointer > 3*5)//wConfigurationPacketSize*3)
				WBMNextState	<= `WBM_CONFIGURE_CORE0_PHASE1;		
			else
				WBMNextState <= `WBM_SEND_DATA_PHASE1;
			
		end
		//----------------------------------------
		`WBM_CONFIGURE_CORE0_PHASE1:
		begin
		
			WE_O <=  1;													//Indicate write cycle
			CYC_O <= 1;													//Start of the cycle
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						//TAG CYCLE: 10 indicated multiple write Cycle
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   					//TAG Address: 01 means instruction address type.
			STB_O <= ~ACK_I;											//Start of phase (you put this in zero to introduce wait cycles)
			IncIA <= 0;	
			MST_O	<= 1;		
			IncDP <= 0;	
			rResetDp <= 0;		
			rClearOutAddress <= 0;	

			rIncCoreSelect <= 0;		
			rCoreSelectMask <= 0;
			rRenderEnable <= 0;			
			rPrepateWriteAddressForNextCore <= 0;		
			rIncPacketCount <= 0;
			
			
			if ( ACK_I )
				WBMNextState <= `WBM_ACK_CONFIGURE_CORE0_PHASE1;
			else
				WBMNextState <= `WBM_CONFIGURE_CORE0_PHASE1;
		end
		//----------------------------------------
		`WBM_ACK_CONFIGURE_CORE0_PHASE1:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		
			STB_O <= 0;	//*											//Negate STB_O in response to ACK_I
			IncIA <= 0;													//leave the instruction write address the same
			MST_O	<= 1;
			IncDP <= 0;	
			rResetDp <= 0;
			rClearOutAddress <= 0;
			rIncCoreSelect <= 0;	
			rCoreSelectMask <= 0;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
			
			
			if (ACK_I == 0)
				WBMNextState <= `WBM_CONFIGURE_CORE0_PHASE2;
			else
				WBMNextState <= `WBM_ACK_CONFIGURE_CORE0_PHASE1;
		end
	//----------------------------------------
		`WBM_CONFIGURE_CORE0_PHASE2:
		begin
			WE_O <=  1;													//Indicate write cycle
			CYC_O <= 1;													//Start of the cycle
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						//TAG CYCLE: 10 indicated multiple write Cycle
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   					//TAG Address: 01 means instruction address type.
			STB_O <= ~ACK_I;											//Start of phase (you put this in zero to introduce wait cycles)
			IncIA <= 0;	
			MST_O	<= 1;		
			IncDP <= 0;	
			rResetDp <= 0;		
			rClearOutAddress <= 0;	

			rIncCoreSelect <= 0;	
			rCoreSelectMask <= 0;
			rRenderEnable <= 0;	
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
			
			if ( ACK_I )
				WBMNextState <= `WBM_ACK_CONFIGURE_CORE0_PHASE2;
			else
				WBMNextState <= `WBM_CONFIGURE_CORE0_PHASE2;
		end
		//----------------------------------------
		`WBM_ACK_CONFIGURE_CORE0_PHASE2:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		
			STB_O <= 0;	//*											//Negate STB_O in response to ACK_I
			IncIA <= 0;													//leave the instruction write address the same
			MST_O	<= 1;
			IncDP <= 0;	
			rResetDp <= 0;
			rClearOutAddress <= 0;
			
			rIncCoreSelect <= 0;
			rCoreSelectMask <= 0;
			rRenderEnable <= 0;
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 0;
				
			if (ACK_I == 0)
				WBMNextState <= `WBM_CONFIGURE_CORE0_PHASE3;
			else
				WBMNextState <= `WBM_ACK_CONFIGURE_CORE0_PHASE2;
		end		
//----------------------------------------
		`WBM_CONFIGURE_CORE0_PHASE3:
		begin
			WE_O <=  1;													//Indicate write cycle
			CYC_O <= 1;													//Start of the cycle
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						//TAG CYCLE: 10 indicated multiple write Cycle
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   					//TAG Address: 01 means instruction address type.
			STB_O <= ~ACK_I;											//Start of phase (you put this in zero to introduce wait cycles)
			IncIA <= 0;	
			MST_O	<= 1;		
			IncDP <= 0;	
			rResetDp <= 0;		
			rClearOutAddress <= 0;	
						rIncPacketCount <= 0;


			rIncCoreSelect <= 0;			
			rCoreSelectMask <= 0;
			rRenderEnable <= 0;	
			rPrepateWriteAddressForNextCore <= 0;
			
			if ( ACK_I )
				WBMNextState <= `WBM_ACK_CONFIGURE_CORE0_PHASE3;
			else
				WBMNextState <= `WBM_CONFIGURE_CORE0_PHASE3;
		end
		//----------------------------------------
		`WBM_ACK_CONFIGURE_CORE0_PHASE3:
		begin
			WE_O <=  1;													
			CYC_O <= 1;													
			TGC_O <= `TAG_BLOCK_WRITE_CYCLE;						
			TGA_O <= `TAG_DATA_ADDRESS_TYPE;   		
			STB_O <= 0;	//*											//Negate STB_O in response to ACK_I
			IncIA <= 0;													//leave the instruction write address the same
			MST_O	<= 1;
			IncDP <= 0;	
			rResetDp <= 0;
			rClearOutAddress <= 0;
			
			rIncCoreSelect <= 0;
			rCoreSelectMask <= 0;
			rRenderEnable <= 0;	
			rPrepateWriteAddressForNextCore <= 0;
						rIncPacketCount <= 1;
			
			if (ACK_I == 0)
				WBMNextState <= `WBM_END_CORE0_WRITE_CYCLE;
			else
				WBMNextState <= `WBM_ACK_CONFIGURE_CORE0_PHASE3;
		end				
//----------------------------------------
		`WBM_END_CORE0_WRITE_CYCLE:
		begin
			WE_O <=  0;													
			CYC_O <= 0;	//*												
			TGC_O <= 0;						
			TGA_O <= 0;   		
			STB_O <= 0;	
			IncIA <= 1;//*		
			MST_O	<= 1;		
			IncDP <= 0;		
			rResetDp <= 0;
			rIncCoreSelect <= 0;
			rCoreSelectMask <= 0;
			rRenderEnable <= 0;
						rIncPacketCount <= 0;

			
			if ((rPacketCount %2) == 0) //Two packets per Core
			begin
				rClearOutAddress <= 1; 
				rPrepateWriteAddressForNextCore <= 1;
				WBMNextState	<= `WBM_CONFIGURE_NEXT_CORE;		
			end	
			else
			begin
				rClearOutAddress <= 0;
				rPrepateWriteAddressForNextCore <= 0;
				WBMNextState <= `WBM_CONFIGURE_CORE0_PHASE1;
			end	
			
		end

//------------------------------------------

`WBM_CONFIGURE_NEXT_CORE:
begin
			WE_O 	<=  0;													
			CYC_O <= 0;													
			TGC_O <= 0;						
			TGA_O <= 0;   		
			STB_O <= 0;	
			IncIA <= 0;		
			MST_O	<= 1;		
			IncDP <= 0;		
			rResetDp <= 0;
			
			rCoreSelectMask <= 0;
			rIncCoreSelect <= 1;
			rRenderEnable <= 0;
			rIncPacketCount <= 0;

			
			if (wCoreSelect[`MAX_CORES-1] == 1)
				WBMNextState <= `WBM_DONE;
			else
				WBMNextState <= `WBM_CONFIGURE_CORE0_PHASE1;
			
			
end

		
		
		//----------------------------------------
		//Here everything is ready so just start!
		
		`WBM_DONE:
		begin
			WE_O <=  0;													
			CYC_O <= 0;											
			TGC_O <= 0;						
			TGA_O <= 0;   		
			STB_O <= 0;	
			IncIA <= 0;		
			MST_O	<= 0;	
			IncDP <= 0;	
			rResetDp <= 1;		
			rClearOutAddress <= 1;	
			rCoreSelectMask <= 0;
			rRenderEnable <= 4'b1111;	
			rPrepateWriteAddressForNextCore <= 0;
			
			WBMNextState <= `WBM_DONE;
		end
		//----------------------------------------
		
		
		endcase
	end	//end always
	//----------------------------------------------------------	


	


endmodule

