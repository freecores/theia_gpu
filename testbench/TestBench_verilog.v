

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
`define RESOLUTION_WIDTH        (rSceneParameters[13] >> `SCALE)
`define RESOLUTION_HEIGHT        (rSceneParameters[14] >> `SCALE)
`define DELTA_ROW          (32'h1 << `SCALE)
`define DELTA_COL          (32'h1 << `SCALE)

`define MAX_WIDTH          200 
`define MAX_SCREENBUFFER        (`MAX_WIDTH*`MAX_WIDTH*3) 
module TestBench_Theia;


 //------------------------------------------------------------------------
 //**WARNING: Declare all of your varaibles at the begining
 //of the file. I hve noticed that sometimes the verilog
 //simulator allows you to use some regs even if they have not been 
 //previously declared, leadeing to crahses or unexpected behavior
 // Inputs
 reg Clock;
 reg Reset;
 wire [`WB_WIDTH-1:0]   DAT_O;
 reg          ACK_O;
 wire        ACK_I;
 wire [`WB_WIDTH-1:0]   ADR_I,ADR_O;
 wire         WE_I,STB_I;
 wire         CYC_O,WE_O,TGC_O,STB_O;
 wire [1:0]       TGA_O;
 wire [1:0]       TGA_I;
 reg [`WB_WIDTH-1:0]    TMADR_O,TMDAT_O;
 reg [`MAX_TMEM_BANKS-1:0]  TMSEL_O;
 reg         TMWE_O;
 reg [31:0]       rControlRegister[2:0]; 
 integer          file, log;
 reg [31:0]       rSceneParameters[`PARAMS_ARRAY_SIZE-1:0];
 reg [31:0]       rVertexBuffer[`VERTEX_ARRAY_SIZE-1:0];
 reg [31:0]       rInstructionBuffer[512:0];
 reg [31:0]       rTextures[`TEXTURE_BUFFER_SIZE-1:0];  //Lets asume we use 256*256 textures
 reg [7:0]        rScreen[`MAX_SCREENBUFFER-1:0];
 
 wire         wDone;
 wire [`MAX_CORES-1:0]   RENDREN_O;
 reg [`MAX_CORE_BITS-1:0]   wOMEMBankSelect;
 reg [`WB_WIDTH-1:0]    wOMEMReadAddr;  //Output adress (relative to current bank)
 wire [`WB_WIDTH-1:0]       wOMEMData;   //Output data bus (Wishbone)
 reg        rHostEnable;
 integer       k,out2;
 wire GRDY_I;
 wire GACK_O;
 wire STDONE_O;
 wire wGPUCommitedResults;
 wire wHostDataAvailable;


wire[`WB_WIDTH-1:0]               wHostReadAddress;
wire[`WB_WIDTH-1:0]               wMemorySize;
wire[1:0]                         wMemSelect;

MUXFULLPARALELL_2SEL_GENERIC # ( `WB_WIDTH ) MUX2
 (
.Sel( wMemSelect ),
.I1(  rInstructionBuffer[0] ),
.I2(  rSceneParameters[0]   ),
.I3(  rVertexBuffer[0]      ),
.I4(0),
.O1(wMemorySize)
 );
 
 
 //---------------------------------------------
 top Top
(
.Clock( Clock ),
.Reset( Reset ),
.iHostEnable(      rHostEnable ),
.oHostReadAddress( wHostReadAddress),
.iMemorySize(      wMemorySize     ),
.oMemSelect(       wMemSelect      ),
.iInstruction(     rInstructionBuffer[wHostReadAddress] ),
.iParameter(       rSceneParameters[wHostReadAddress]   ),
.iVertex(          rVertexBuffer[wHostReadAddress]      ),
.iControlRegister( rControlRegister[0]                  ),
.iPrimitiveCount(  (rVertexBuffer[6]+1) *7              ),
.iTMEMAdr( TMADR_O ),
.iTMEMData( TMDAT_O ),
.iTMEM_WE( TMWE_O ),
.iTMEM_Sel( TMSEL_O ),
.iOMEMBankSelect(  wOMEMBankSelect ),
.iOMEMReadAddress( wOMEMReadAddr ),
.oOMEMData( wOMEMData ),   

.iWidth(`RESOLUTION_WIDTH),
.iHeight(`RESOLUTION_HEIGHT),
.oDone( wDone )


);
 //---------------------------------------------
 //generate the clock signal here
 always begin
  #`CLOCK_CYCLE  Clock =  ! Clock;
 
 end
 //---------------------------------------------
 

//-------------------------------------------------------------------------------------
/*
This makes sure the simulation actually writes the results to the PPM image file
once all the cores are done executing
*/
`define PARTITION_SIZE `RESOLUTION_HEIGHT/`MAX_CORES
integer i,j,kk;
reg [31:0] R;
always @ ( * )
begin


if (wDone == 1'b1)
begin
 $fwrite(log, "Simulation end time : %dns\n",$time);

 $display("Partition Size = %d",`PARTITION_SIZE);
 for (kk = 0; kk < `MAX_CORES; kk = kk+1)
   begin
   wOMEMBankSelect = kk; 
    $display("wOMEMBankSelect = %d\n",wOMEMBankSelect);
    for (j=0; j < `PARTITION_SIZE; j=j+1)
    begin
     
     for (i = 0; i < `RESOLUTION_HEIGHT*3; i = i +1)
     begin
     wOMEMReadAddr = i+j*`RESOLUTION_WIDTH*3;
     #`CLOCK_PERIOD;
     #1;
     R = ((wOMEMData >> (`SCALE-8)) > 255) ? 255 : (wOMEMData >>  (`SCALE-8));
     $fwrite(out2,"%d " , R );

      if ((i %3) == 0)
        $fwrite(out2,"\n# %d %d\n",i/3,j);
      
     end
    end
   end 
  

   
   $fclose(out2);
   
   $fclose(log);
   

   $stop();
   
   
end   
end
//-------------------------------------------------------------------------------------

reg [15:0] rTimeOut;
  
 // `define MAX_INSTRUCTIONS 2
  
 initial begin
  // Initialize Inputs
  
    
  Clock      = 0;
  Reset      = 0;
  rTimeOut             = 0;
  rHostEnable    = 0;
  //Read Config register values
  $write("Loading control register.... ");
  $readmemh("Creg.mem",rControlRegister);
  $display("Done");
  
  
   
  //Read configuration Data
  $write("Loading scene parameters.... ");
  $readmemh("Params.mem", rSceneParameters );
  $display("Done");
  
  
  //Read Scene Data
  $write("Loading scene geometry.... ");
  $readmemh("Vertex.mem",rVertexBuffer);
  $display("Done");
  
  $display("Number of primitives(%d): %d",rVertexBuffer[6],(rVertexBuffer[6]+1) *7);
  
  
  //Read Texture Data
  $write("Loading scene texture.... ");
  $readmemh("Textures.mem",rTextures);
  $display("Done");
  

  //Read instruction data
  $write("Loading code allocation table and user shaders.... ");
  $readmemh("Instructions.mem",rInstructionBuffer);
  $display("Done");
  
  $display("Control Register : %b",rControlRegister[0]);
  $display("Resolution       : %d X %d",`RESOLUTION_WIDTH, `RESOLUTION_HEIGHT );
 
  
  //Open output file
  out2 = $fopen("Output.ppm");
  
  $fwrite(out2,"P3\n");
  $fwrite(out2,"#This file was generated by Theia's RTL simulation\n");
  $fwrite(out2,"%d %d\n",`RESOLUTION_WIDTH, `RESOLUTION_HEIGHT );
  $fwrite(out2,"255\n");
  
  #10
  Reset = 1;
  

  // Wait 100 ns for global reset to finish
  TMWE_O = 1;
  #100  Reset = 0;  
  TMWE_O = 1;
  
  $display("Intilializing TMEM @ %dns",$time);
  //starts in 2 to skip Width and Height
  for (k = 0;k < `TEXTURE_BUFFER_SIZE; k = k + 1)
  begin
   
   TMADR_O <= (k >> (`MAX_CORE_BITS));  
   TMSEL_O <= (k & (`MAX_TMEM_BANKS-1));  //X mod 2^n == X & (2^n - 1)
   TMDAT_O <= rTextures[k];
   #10;
   if ((k % (256*3)) == 0)
   begin
    $write("|");
    $fflush;
   end 
  end
 
  $display("\nDone Intilializing TMEM @ %dns",$time);
  TMWE_O = 0;
  rHostEnable = 1;
  
  log  = $fopen("Simulation.log");
  $fwrite(log, "Simulation start time : %dns\n",$time);
  
 
  //Start dumping VCD
  $display("-I- Starting VCD Dump\n");
  $dumpfile("TestBench_Theia.vcd");
  $dumpvars(0,TestBench_Theia);
 
 end
 

endmodule
