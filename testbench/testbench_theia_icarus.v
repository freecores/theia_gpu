`timescale 1ns / 1ps


`define MAIN_MEMORY_DEPTH (255 * 2)						//Each entry is 64 bits = 32 *2 * 255 entries

module testbench_theia_icarus;

	
	reg Clock;
	reg Reset;
	reg iEnable;
	reg [31:0] iMemReadData;
	wire [31:0] oMemReadAddress;
	reg iMemDataAvailable;
	wire oMEM_ReadRequest;

	
	THEIA uut 
	(
		.Clock(                  Clock             ), 
		.Reset(                  Reset             ), 
		.iEnable(                iEnable           ), 
		.iMemReadData(           iMemReadData      ), 
		.iMemDataAvailable(      iMemDataAvailable ),
		.oMEM_ReadRequest(       oMEM_ReadRequest  ),
		.oMemReadAddress(        oMemReadAddress   )
	);
//---------------------------------------------
 //generate the clock signal here
 always begin
  #10  Clock =  ! Clock;
 end
 //---------------------------------------------
 
 //Code dumpers and checker stuff 
 ContolCode_Dumper           CP_Dumper();
 VectorProcessor_Dumper #(0) VP_Dump0();
 VectorProcessor_Dumper #(1) VP_Dump1();
 VectorProcessor_Dumper #(2) VP_Dump2();
 VectorProcessor_Dumper #(3) VP_Dump3();
 
 
 reg [31:0] MainMemory [`MAIN_MEMORY_DEPTH-1:0];
 reg [31:0] TMemory [`MAIN_MEMORY_DEPTH-1:0];
	
	
	always @ (posedge Clock )
	begin
		if (oMEM_ReadRequest)
			iMemDataAvailable <= 1;
		else
			iMemDataAvailable <= 0;
			
		iMemReadData <= 	MainMemory[oMemReadAddress];
		
	end

	initial begin
		Clock = 0;
		Reset = 0;
		iEnable = 0;
		$readmemh("control_code.mem", uut.CP.InstructionRam.Ram);
		$readmemh("code.mem", MainMemory);
		$readmemh("tmem.mem",TMemory);
		uut.BANK[0].TMEM.Ram[0] = TMemory[0];
		uut.BANK[1].TMEM.Ram[0] = TMemory[1];
		uut.BANK[2].TMEM.Ram[0] = TMemory[2];
		#110;
		Reset = 1; 
		#40;
		Reset = 0; 

		$dumpfile("testbench_theia_icarus.vcd");
		$dumpvars(0,testbench_theia_icarus);
	end
	
	
      
endmodule

