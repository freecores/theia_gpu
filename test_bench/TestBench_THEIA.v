
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
	wire 						WE_I,STB_I,CYC_I;
	reg CYC_O,WE_O,TGC_O,STB_O;
	wire [1:0] TGC_I;
	reg [1:0] TGA_O;
	wire [1:0] TGA_I;
	wire [31:0] DAT_I;
	integer ucode_file;
	
	
	reg [31:0] rInitialCol,rInitialRow; 
	reg [31:0] 	rControlRegister[2:0]; 
	

	integer file, log, r, a, b;
	
	
	reg [31:0]  rSceneParameters[31:0];
	reg [31:0] 	rVertexBuffer[6000:0];
	reg [31:0] 	rInstructionBuffer[25:0];
	`define TEXTURE_BUFFER_SIZE (256*256*3)
	reg [31:0]  rTextures[`TEXTURE_BUFFER_SIZE:0];		//Lets asume we use 256*256 textures
	
	//------------------------------------------------------------------------
	//Debug registers
	`define TASK_TIMEOUTMAX 50000
	

	
	//------------------------------------------------------------------------

	
	
		reg MST_O;
//---------------------------------------------------------------	
	THEIACORE THEIA 
		(
		.CLK_I( Clock ), 
		.RST_I( Reset ), 
		.DAT_I( DAT_O ),
		.ADR_O( ADR_I ),
		.ACK_I( ACK_O ),
		.WE_O ( WE_I ),
		.STB_O( STB_I ),
		.CYC_O( CYC_I ),
		.CYC_I( CYC_O ),
		.TGC_O( TGC_I ),
		.MST_I( MST_O ),
		.TGA_I( TGA_O ),
		.ACK_O( ACK_I ),
		.ADR_I( ADR_O ),
		.DAT_O( DAT_I ),
		.WE_I(  WE_O  ),
		
		.STB_I( STB_O ),
		.TGA_O(TGA_I),




		//Control register
		.CREG_I( rControlRegister[0][15:0] )
		//Other stuff
		
	
			
		
		

	);
	//&
//---------------------------------------------------------------		
	
	
	//---------------------------------------------
	//generate the clock signal here
	always begin
		#5  Clock =  ! Clock;
	
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
		$display("Opening dump file....\n");
		ucode_file = $fopen("TestBench.log","w");
	`endif
	
		//Read Config register values
		$readmemh("Creg.mem",rControlRegister);
		
		rInitialRow = rControlRegister[1];
		rInitialCol = rControlRegister[2];
	//  rControlRegister[0] = 32'b0;
		
		//Read configuration Data
		$readmemh("Params.mem",	rSceneParameters	);
		//Read Scene Data
		$readmemh("Vertex.mem",rVertexBuffer);
		//Read Texture Data
		$readmemh("Textures.mem",rTextures);
		//Read instruction data
		$readmemh("Instructions.mem",rInstructionBuffer);
		
		$display("Control Register: %b",rControlRegister[0]);
		
		
		
		$display("Initial Row: %h",rInitialRow);
		$display("Initial Column: %h",rInitialCol);
		
		`LOGME"AABB min %h %h %h\n",rVertexBuffer[0],rVertexBuffer[1],rVertexBuffer[2]);
		`LOGME"AABB max %h %h %h\n",rVertexBuffer[3],rVertexBuffer[4],rVertexBuffer[5]);
		`LOGME"%h %h %h\n",rVertexBuffer[6],rVertexBuffer[7],rVertexBuffer[8]);
		`LOGME"%h %h %h\n",rVertexBuffer[9],rVertexBuffer[10],rVertexBuffer[11]);
		`LOGME"%h %h %h\n",rVertexBuffer[12],rVertexBuffer[13],rVertexBuffer[14]);
		`LOGME"%h %h %h\n",rVertexBuffer[15],rVertexBuffer[16],rVertexBuffer[17]);
		`LOGME"%h %h %h\n",rVertexBuffer[18],rVertexBuffer[19],rVertexBuffer[20]);
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
		
		`LOGME"Running at %d X %d\n", `RESOLUTION_WIDTH, `RESOLUTION_HEIGHT);
		
		`LOGME"%h\n",rSceneParameters[0]);
		`LOGME"%h\n",rSceneParameters[1]);
		`LOGME"%h\n",rSceneParameters[2]);
		
		`LOGME"%h\n",rSceneParameters[3]);
		`LOGME"%h\n",rSceneParameters[4]);
		`LOGME"%h\n",rSceneParameters[5]);
		
		`LOGME"%h\n",rSceneParameters[6]);
		`LOGME"%h\n",rSceneParameters[7]);
		`LOGME"%h\n",rSceneParameters[8]);
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
			if ( STB_I == 1 )
				WBSNextState = `WBS_ACK_O;
			else
				WBSNextState = `WBS_MOINTOR_STB_I;
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
					`ifdef DEBUG
					
					`LOGME"WB SLAVE: MASTER Requested read from texture address: %h (%d)Data = %h \n",rAddress, rConvertedTextureAddress,DAT_O );
					`endif
				end	
				else
				begin
					Thingy = 0;
					rSlaveData_O = rVertexBuffer[ rAddress ];
					`ifdef DEBUG
					`LOGME"WB SLAVE: MASTER Requested read from vertex address: %h Data = %h\n",rAddress,DAT_O);
					`endif
				end	
				
			end
			else
			begin
			//	$display("Theia Writes value: %h @ %h (Time to process pixel %d Clock cycle)",DAT_I,ADR_I,rTimeOut);
			
			
			if (Thingy == 0)
			begin
				$fwrite(file,"\n# %d %d\n",CurrentPixelRow,CurrentPixelCol);
				$write(".");
			end	
			
			Thingy = Thingy + 1;
			if (CurrentPixelRow >= 	`RESOLUTION_WIDTH)
			begin
				CurrentPixelRow = 0;
				CurrentPixelCol = CurrentPixelCol + 1;
				$display("]- %d (%d)",CurrentPixelCol,ADR_I);
				$write("[");
			end
			
			if (Thingy == 3)
			begin
				CurrentPixelRow = CurrentPixelRow + 1;
				Thingy = 0;
			end	
				rTimeOut = 0;
				R = ((DAT_I >> (`SCALE-8)) > 255) ? 255 : (DAT_I >>  (`SCALE-8));
				$fwrite(file,"%d " , R );
		
			end
			
			
			ACK_O = 1;
			//if (ADR_I >= `RESOLUTION_WIDTH*`RESOLUTION_HEIGHT*3)
			if (CurrentPixelCol >= `RESOLUTION_HEIGHT)
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
		$display("WTF????????????????????????");
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

reg[31:0] rInstructionPointer;
reg[31:0] rAddressToSend;
reg[31:0] rDataAddress;
reg[31:0] rDataPointer;

reg IncIP,IncIA,IncDP;
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
//-----------------------------------------------------




assign DAT_O = ( MST_O == 1'b1 ) ? wMasteData_O : rSlaveData_O;

wire[31:0] wMasteData_O;

assign wMasteData_O = (TGA_O == `TAG_INSTRUCTION_ADDRESS_TYPE) ? rInstructionBuffer[rInstructionPointer] : rSceneParameters[ rDataPointer  ];
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
		/*
		Wait until the reset secuence is complete to
		begin sending stuff.
		*/
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
			
			if (Reset == 0)
				WBMNextState <= `WBM_WRITE_INSTRUCTION_PHASE1;
			else
				WBMNextState <= `WBM_AFTER_RESET;
		end
		//----------------------------------------
		/*
		CLOCK EDGE 0: MASTER presents a valid address on [ADR_O()]
		MASTER presents valid data on [DAT_O()]
		MASTER asserts [WE_O] to indicate a WRITE cycle.
		MASTER asserts [CYC_O] and [TGC_O()] to indicate the start of the cycle.
		MASTER asserts [STB_O] to indicate the start of the phase.
		*/
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
		
			
			
		if (rInstructionPointer >= 4)
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
		//	IncIP <= 0;
			IncIA <= 0;	
			MST_O	<= 1;		
			IncDP <= 0;	
			rResetDp <= 0;		
			rClearOutAddress <= 0;			
			
			
			
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

			$display("rDataPointer = %d\n",rDataPointer);
			if (rDataPointer > wConfigurationPacketSize*3)
				WBMNextState	<= `WBM_DONE;		
			else
				WBMNextState <= `WBM_SEND_DATA_PHASE1;
			
		end
		
		//----------------------------------------
		/*
		Here everything is ready so just start!
		*/
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
			
			WBMNextState <= `WBM_DONE;
		end
		//----------------------------------------
		
		
		endcase
	end	//end always
	//----------------------------------------------------------	


	


endmodule

