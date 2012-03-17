`timescale 1ns / 1ps


module testbench;

	// Inputs
	reg Clock;
	reg Reset;
	reg iEnable;

	// Instantiate the Unit Under Test (UUT)
	Unit_Execution uut (
		.Clock(Clock), 
		.Reset(Reset), 
		.iEnable(iEnable)
	);



Dumper DUMP();
//---------------------------------------------
 //generate the clock signal here
 always begin
  #10  Clock =  ! Clock;
 end
 //---------------------------------------------

reg [31:0] i;

	initial begin
		// Initialize Inputs
		Clock = 0;
		Reset = 0;
		iEnable = 0;
		//Load rams
		$readmemh("Code.mem", uut.IM.Ram);
		//$readmemh("Dummy.mem", uut.RF.Ram);

		for (i = 0; i < 128; i = i + 1)
			uut.II.SB.Ram[i] = 0;
			
		
	/*	for (i = 0; i < 32; i = i + 1)
			uut.RF.RF_X.Ram[i] = 0;	
			
		for (i = 0; i < 32; i = i + 1)
			uut.RF.RF_Y.Ram[i] = 0;	

		for (i = 0; i < 32; i = i + 1)
			uut.RF.RF_Z.Ram[i] = 0;			*/	
			
		#110;
      Reset = 1; 
		#40;
		Reset = 0; 
		iEnable = 1;

	end
      
endmodule

