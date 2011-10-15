`timescale 1ns / 1ps
`include "aDefinitions.v"


//LUT contains LUT for numbers up to 100 in FIXED point scale 17
module SQUAREROOT_LUT
(
	input  wire[`WIDTH-1:0]  		I,
	output reg [`WIDTH-1:0] 		O
);	


always @( I )
begin
	case (I)
	32'h0: O = 32'h0;
32'h20000: O = 32'h20000;
32'h40000: O = 32'h2d413;
32'h60000: O = 32'h376cf;
32'h80000: O = 32'h40000;
32'ha0000: O = 32'h478dd;
32'hc0000: O = 32'h4e623;
32'he0000: O = 32'h54a9f;
32'h100000: O = 32'h5a827;
32'h120000: O = 32'h60000;
32'h140000: O = 32'h65316;
32'h160000: O = 32'h6a21c;
32'h180000: O = 32'h6ed9e;
32'h1a0000: O = 32'h7360a;
32'h1c0000: O = 32'h77bba;
32'h1e0000: O = 32'h7bef7;
32'h200000: O = 32'h80000;
32'h220000: O = 32'h83f07;
32'h240000: O = 32'h87c3b;
32'h260000: O = 32'h8b7c1;
32'h280000: O = 32'h8f1bb;
32'h2a0000: O = 32'h92a47;
32'h2c0000: O = 32'h9617e;
32'h2e0000: O = 32'h99777;
32'h300000: O = 32'h9cc47;
32'h320000: O = 32'ha0000;
32'h340000: O = 32'ha32b2;
32'h360000: O = 32'ha646e;
32'h380000: O = 32'ha953f;
32'h3a0000: O = 32'hac534;
32'h3c0000: O = 32'haf456;
32'h3e0000: O = 32'hb22b2;
32'h400000: O = 32'hb504f;
32'h420000: O = 32'hb7d37;
32'h440000: O = 32'hba972;
32'h460000: O = 32'hbd508;
32'h480000: O = 32'hc0000;
32'h4a0000: O = 32'hc2a5f;
32'h4c0000: O = 32'hc542e;
32'h4e0000: O = 32'hc7d70;
32'h500000: O = 32'hca62c;
32'h520000: O = 32'hcce66;
32'h540000: O = 32'hcf623;
32'h560000: O = 32'hd1d68;
32'h580000: O = 32'hd4439;
32'h5a0000: O = 32'hd6a99;
32'h5c0000: O = 32'hd908d;
32'h5e0000: O = 32'hdb618;
32'h600000: O = 32'hddb3d;
32'h620000: O = 32'he0000;
32'h640000: O = 32'he2463;
32'h660000: O = 32'he4869;
32'h680000: O = 32'he6c15;
32'h6a0000: O = 32'he8f6a;
32'h6c0000: O = 32'heb26a;
32'h6e0000: O = 32'hed517;
32'h700000: O = 32'hef775;
32'h720000: O = 32'hf1983;
32'h740000: O = 32'hf3b46;
32'h760000: O = 32'hf5cbf;
32'h780000: O = 32'hf7def;
32'h7a0000: O = 32'hf9ed9;
32'h7c0000: O = 32'hfbf7d;
32'h7e0000: O = 32'hfdfdf;
32'h800000: O = 32'h100000;
32'h820000: O = 32'h101fe0;
32'h840000: O = 32'h103f81;
32'h860000: O = 32'h105ee6;
32'h880000: O = 32'h107e0f;
32'h8a0000: O = 32'h109cfd;
32'h8c0000: O = 32'h10bbb3;
32'h8e0000: O = 32'h10da30;
32'h900000: O = 32'h10f876;
32'h920000: O = 32'h111687;
32'h940000: O = 32'h113463;
32'h960000: O = 32'h11520c;
32'h980000: O = 32'h116f83;
32'h9a0000: O = 32'h118cc8;
32'h9c0000: O = 32'h11a9dc;
32'h9e0000: O = 32'h11c6c1;
32'ha00000: O = 32'h11e377;
32'ha20000: O = 32'h120000;
32'ha40000: O = 32'h121c5b;
32'ha60000: O = 32'h12388a;
32'ha80000: O = 32'h12548e;
32'haa0000: O = 32'h127068;
32'hac0000: O = 32'h128c17;
32'hae0000: O = 32'h12a79e;
32'hb00000: O = 32'h12c2fc;
32'hb20000: O = 32'h12de32;
32'hb40000: O = 32'h12f942;
32'hb60000: O = 32'h13142b;
32'hb80000: O = 32'h132eee;
32'hba0000: O = 32'h13498c;
32'hbc0000: O = 32'h136406;
32'hbe0000: O = 32'h137e5b;
32'hc00000: O = 32'h13988e;
32'hc20000: O = 32'h13b29d;
32'hc40000: O = 32'h13cc8a;
32'hc60000: O = 32'h13e655;
32'hc80000: O = 32'h140000;
32'hca0000: O = 32'h141989;
32'hcc0000: O = 32'h1432f2;
32'hce0000: O = 32'h144c3b;
32'hd00000: O = 32'h146565;
32'hd20000: O = 32'h147e70;
32'hd40000: O = 32'h14975c;
32'hd60000: O = 32'h14b02b;
32'hd80000: O = 32'h14c8dc;
32'hda0000: O = 32'h14e16f;
32'hdc0000: O = 32'h14f9e6;
32'hde0000: O = 32'h151241;
32'he00000: O = 32'h152a7f;
32'he20000: O = 32'h1542a2;
32'he40000: O = 32'h155aaa;
32'he60000: O = 32'h157296;
32'he80000: O = 32'h158a68;
32'hea0000: O = 32'h15a220;
32'hec0000: O = 32'h15b9be;
32'hee0000: O = 32'h15d142;
32'hf00000: O = 32'h15e8ad;
32'hf20000: O = 32'h160000;
32'hf40000: O = 32'h161739;
32'hf60000: O = 32'h162e5a;
32'hf80000: O = 32'h164564;
32'hfa0000: O = 32'h165c55;
32'hfc0000: O = 32'h16732f;
32'hfe0000: O = 32'h1689f2; //127 -> 1111111,00000000000000000 

default:
begin
//$display("Shit, got %d\n",I << `SCALE);
 O = 32'h00caca;
end 
	endcase
	
end //always	
endmodule

module FixedPointSquareRoot
(
	input wire							Clock,
	input wire							Reset,
	input wire[`LONG_WIDTH-1:0] 	Operand,			
	input wire							iInputReady,					
	output	wire 						OutputReady,				
	output  wire [`WIDTH-1:0]		Result
);

FFD_POSEDGE_SYNCRONOUS_RESET # (1) FFDelay1
(
	.Clock( Clock ),
	.Reset( Reset ),
	.Enable(1'b1 ),
	.D( iInputReady ),
	.Q( OutputReady )
);	

//LUT only has values from 0 to 127, lets see if the value is bigger than that
wire wNotInLUT;
assign wNotInLUT = Operand[7+`SCALE]; //pero para ese chiste usar 128 en lugar de 4, entonces pueden haber hasta 128*128 = 16384 valores
//If the value is not on the LUT then divide by 4, so SQRT(x) = SQRT(4*x/4)
//=2*SQRT(x/4)

wire[`WIDTH-1:0] wScaledOperand;

assign wScaledOperand = (wNotInLUT == 1'b0 ) ? 
   {Operand[`WIDTH-1:`SCALE],{`SCALE{1'b0}}} :     //Aproximate the Square root to an integer value
	{2'b0,Operand[`WIDTH-1:`SCALE+2],{`SCALE{1'b0}}};  //Shift right two bits (divide by 4)

wire [`WIDTH-1:0] wResult,wScaleResult;
SQUAREROOT_LUT SQRT
(
.I(wScaledOperand),
//.I({Operand[`WIDTH-1:`SCALE],{`SCALE{1'b0}}}), //Aproximate the Square root to an integer value
.O(wScaleResult)
//.O(wResult)
);



assign wResult = (wNotInLUT == 1'b0 ) ? wScaleResult : {wScaleResult[`WIDTH-2:0],1'b0};


FFD_POSEDGE_SYNCRONOUS_RESET # (`WIDTH) FFRESULT
(
	.Clock( Clock ),
	.Reset( Reset ),
	.Enable(1'b1 ),
	.D( wResult ),
	.Q( Result )
);	

//--------------------------------------------------------------------------------
`ifdef BIGGER

FFD_POSEDGE_SYNCRONOUS_RESET # (1) FFDelay1
(
	.Clock( Clock ),
	.Reset( Reset ),
	.Enable(1'b1 ),
	.D( iInputReady ),
	.Q( OutputReady )
);	

//LUT only has values from 0 to 127, lets see if the value is bigger than that
wire wNotInLUT;
assign wNotInLUT = Operand[7+`SCALE]; 
//If the value is not on the LUT then divide by 4, so SQRT(x) = SQRT(64*x/64)
//=16*SQRT(x/64)

wire[`WIDTH-1:0] wScaledOperand;

assign wScaledOperand = (wNotInLUT == 1'b0 ) ? 
   {Operand[`WIDTH-1:`SCALE],{`SCALE{1'b0}}} :     //Aproximate the Square root to an integer value
	{6'b0,Operand[`WIDTH-1:`SCALE+6],{`SCALE{1'b0}}};  //Shift right two bits (divide by 4)

wire [`WIDTH-1:0] wResult,wScaleResult;
SQUAREROOT_LUT SQRT
(
.I(wScaledOperand),
.O(wScaleResult)

);



assign wResult = (wNotInLUT == 1'b0 ) ? wScaleResult : {wScaleResult[`WIDTH-3:0],1'b0};


FFD_POSEDGE_SYNCRONOUS_RESET # (`WIDTH) FFRESULT
(
	.Clock( Clock ),
	.Reset( Reset ),
	.Enable(1'b1 ),
	.D( wResult ),
	.Q( Result )
);	

`endif
//--------------------------------------------------------------------------------
endmodule
