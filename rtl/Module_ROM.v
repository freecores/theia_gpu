

`define ONE (32'h1 << `SCALE)

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

/*
I can't synthesize roms, the rom needs to be adapted depending on the 
final target silicon.
*/


//--------------------------------------------------------
module ROM
(
	input  wire[`ROM_ADDRESS_WIDTH-1:0]  		Address,
	`ifdef DEBUG
	input wire [`MAX_CORES-1:0]            iDebug_CoreID,
	`endif
	output reg [`INSTRUCTION_WIDTH-1:0] 		I
);	


always @( Address )
begin
			case (Address)
			
//Hardcoded stuff :(
`define RAY_INSIDE_BOX				`R3
`define CURRENT_LIGHT_POS `CREG_FIRST_LIGTH  //TODO: CAHNEG T 
`define CURRENT_LIGHT_DIFFUSE 16'h6

//-----------------------------------------------------------------
`define TAG_PIXELSHADER 16'd314
`define TAG_USERCONSTANTS 16'd312
`define TAG_PSU_UCODE_ADRESS2 16'd284
`define TAG_PSU_UCODE_ADRESS 16'd268
`define LABEL_TCC_EXIT 16'd267
`define TAG_TCC_UCODE_ADDRESS 16'd226
`define LABEL_BIU4 16'd225
`define LABEL_BIU3 16'd211
`define LABEL_BIU2 16'd205
`define LABEL_BIU1 16'd202
`define TAG_BIU_UCODE_ADDRESS 16'd185
`define LABEL_HIT 16'd183
`define LABEL15 16'd181
`define LABEL14 16'd179
`define LABEL13 16'd177
`define LABEL_TEST_XY_PLANE 16'd172
`define LABEL12 16'd170
`define LABEL11 16'd168
`define LABEL10 16'd166
`define LABEL_TEST_XZ_PLANE 16'd160
`define LABEL9 16'd158
`define LABEL8 16'd156
`define LABEL7 16'd154
`define LABEL_TEST_YZ_PLANE 16'd148
`define LABEL_RAY_INSIDE_BOX 16'd145
`define LABEL_ELSEZ 16'd144
`define LABEL6 16'd141
`define LABEL_ELESE_IFZ 16'd137
`define LABEL5 16'd134
`define LABEL_TEST_RAY_Z_ORIGEN 16'd130
`define LABEL_ELSEY 16'd129
`define LABEL4 16'd126
`define LABEL_ELESE_IFY 16'd122
`define LABEL3 16'd119
`define LABEL_TEST_RAY_Y_ORIGEN 16'd115
`define LABEL_ELSEX 16'd114
`define LABEL2 16'd111
`define LABEL_ELSE_IFX 16'd107
`define LABEL1 16'd104
`define LABEL_TEST_RAY_X_ORIGEN 16'd100
`define TAG_AABBIU_UCODE_ADDRESS 16'd97
`define LABEL_ALLDONE 16'd95
`define LABEL_NPG_NEXT_ROW 16'd90
`define TAG_NPG_UCODE_ADDRESS 16'd81
`define TAG_RGU_UCODE_ADDRESS 16'd73
`define TAG_CPPU_UCODE_ADDRESS 16'd69
`define LABEL_MAIN_RENDER_DONE 16'd68
`define LABEL_MAIN_IS_NO_HIT 16'd61
`define LABEL_MAIN_IS_HIT 16'd50
`define LABEL_MAIN_CHECK_HIT 16'd49
`define LABEL_DEC_PRIM_COUNT 16'd46
`define LABEL_MAIN_TEST_INTERSECTION 16'd41
`define TAG_ADRR_MAIN 16'd37


//-------------------------------------------------------------------------
//Default values for some registers after reset
//-------------------------------------------------------------------------
//This is the first code that gets executed after the machine is
//externally configured ie after the MST_I goes from 1 to zero.
//It sets initial values for some of the internal registers

0: I = { `ZERO ,`CREG_LAST_t ,`VOID ,`VOID }; 
//Set the last 't' to very positive value(500) 
1: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
2: I = { `ZERO ,`OREG_PIXEL_COLOR ,`VOID ,`VOID }; 
3: I = { `COPY ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_INITIAL_POSITION ,`VOID }; 


//Calculate the initial linear address for ADR_O
//this is: (X_initial + RESOLUTION_Y*Y_intial) * 3.
//Notice that we need to use 'unscaled' ie. integer
//values because the resuts of the multiplication by
//the resoluction is to large to fit a fixed point 
//representation.

4: I = { `COPY ,`R1 ,`CREG_RESOLUTION ,`VOID }; 
5: I = { `UNSCALE ,`R1 ,`R1 ,`VOID }; 
6: I = { `SETX ,`R1 ,32'h1  }; 
7: I = { `SETZ ,`R1 ,32'h0  }; 
8: I = { `COPY ,`R2 ,`CREG_PIXEL_2D_INITIAL_POSITION ,`VOID }; 
9: I = { `UNSCALE ,`R2 ,`R2 ,`VOID }; 

//Ok lets start by calculating RESOLUTION_Y*Y_intial
10: I = { `IMUL ,`R1 ,`R1 ,`R2 }; 
11: I = { `COPY ,`R2 ,`R1 ,`VOID }; 
12: I = { `SWIZZLE3D ,`R2 ,`SWIZZLE_YYY  }; 

//now X_initial + RESOLUTION_Y*Y_intial
13: I = { `ADD ,`R3 ,`R1 ,`R2 }; 
14: I = { `COPY ,`R2 ,`R1 ,`VOID }; 
15: I = { `SWIZZLE3D ,`R2 ,`SWIZZLE_ZZZ  }; 
16: I = { `ADD ,`R3 ,`R3 ,`R2 }; 
17: I = { `SWIZZLE3D ,`R3 ,`SWIZZLE_XXX  }; 

//finally multiply by 3 to get:
//(X_initial + RESOLUTION_Y*Y_intial) * 3 voila!
18: I = { `SETX ,`R2 ,32'h3  }; 
19: I = { `SWIZZLE3D ,`R2 ,`SWIZZLE_XXX  }; 
20: I = { `IMUL ,`CREG_PIXEL_PITCH ,`R3 ,`R2 }; 

//By this point you should be wondering why not
//just do DOT R1 [1 Resolution_Y 0] [X_intial Y_intial 0 ]?
//well because DOT uses fixed point and the result may not
//fit :(

//Transform from fixed point to integer
//UNSCALE CREG_PIXEL_PITCH CREG_PIXEL_PITCH VOID
21: I = { `COPY ,`OREG_ADDR_O ,`CREG_PIXEL_PITCH ,`VOID }; 

22: I = { `SETX ,`CREG_3 ,32'h3  }; 
23: I = { `SWIZZLE3D ,`CREG_3 ,`SWIZZLE_XXX  }; 

24: I = { `SETX ,`CREG_012 ,32'h0  }; 
25: I = { `SETY ,`CREG_012 ,32'h1  }; 
26: I = { `SETZ ,`CREG_012 ,32'h2  }; 
27: I = { `COPY ,`CREG_CURRENT_OUTPUT_PIXEL ,`CREG_012 ,`VOID }; 
28: I = { `ZERO ,`CREG_TEXTURE_COLOR ,`VOID ,`VOID }; 
29: I = { `ZERO ,`CREG_ZERO ,`VOID ,`VOID }; 

30: I = { `ZERO ,`R1 ,`VOID ,`VOID }; 
31: I = { `ZERO ,`R2 ,`VOID ,`VOID }; 
32: I = { `ZERO ,`R3 ,`VOID ,`VOID }; 
33: I = { `ZERO ,`R4 ,`VOID ,`VOID }; 
34: I = { `ZERO ,`R5 ,`VOID ,`VOID }; 
35: I = { `ZERO ,`R99 ,`VOID ,`VOID }; 

36: I = { `RETURN ,`RT_TRUE   }; 

//---------------------------------------------------------------------
//This is the main sub-routine
//TAG_ADRR_MAIN:
	
	//Generate the ray, but this is wrong, it has to generate only once for all the triangles..
37: I = { `JNEX ,`LABEL_MAIN_TEST_INTERSECTION ,`CREG_PRIMITIVE_COUNT ,`CREG_MAX_PRIMITIVES }; 
38: I = { `CALL ,`ENTRYPOINT_ADRR_RGU ,`VOID ,`VOID }; 
39: I = { `ZERO ,`CREG_HIT ,`VOID ,`VOID }; 
40: I = { `RESCALE ,`CREG_PRIMITIVE_COUNT ,`CREG_MAX_PRIMITIVES ,`VOID }; 
	
//LABEL_MAIN_TEST_INTERSECTION:
	//Check ofr triangle intersection
41: I = { `NOP ,`RT_FALSE   }; 
42: I = { `CALL ,`ENTRYPOINT_ADRR_BIU ,`VOID ,`VOID }; 
43: I = { `NOP ,`RT_FALSE   }; 
	
44: I = { `JEQX ,`LABEL_DEC_PRIM_COUNT ,`R99 ,`CREG_ZERO }; 
45: I = { `COPY ,`CREG_HIT ,`R99 ,`VOID }; 
//LABEL_DEC_PRIM_COUNT:
46: I = { `DEC ,`CREG_PRIMITIVE_COUNT ,`CREG_PRIMITIVE_COUNT ,`VOID }; 
47: I = { `JEQX ,`LABEL_MAIN_CHECK_HIT ,`CREG_PRIMITIVE_COUNT ,`CREG_ZERO }; 
48: I = { `RETURN ,`RT_FALSE   }; 
	
//LABEL_MAIN_CHECK_HIT:
49: I = { `JEQX ,`LABEL_MAIN_IS_NO_HIT ,`CREG_HIT ,`CREG_ZERO }; 
	
	
	
//LABEL_MAIN_IS_HIT:
50: I = { `NOP ,`RT_FALSE   }; 
51: I = { `CALL ,`ENTRYPOINT_ADRR_TCC ,`VOID ,`VOID }; 
52: I = { `NOP ,`RT_FALSE   }; 
53: I = { `CALL ,`ENTRYPOINT_ADRR_PSU2 ,`VOID ,`VOID }; 
54: I = { `NOP ,`RT_FALSE   }; 
55: I = { `CALL ,`ENTRYPOINT_ADRR_PIXELSHADER ,`VOID ,`VOID }; 
56: I = { `NOP ,`RT_FALSE   }; 
57: I = { `CALL ,`ENTRYPOINT_ADRR_NPG ,`VOID ,`VOID }; 
58: I = { `NOP ,`RT_FALSE   }; 
59: I = { `JEQX ,`LABEL_MAIN_RENDER_DONE ,`R99 ,`CREG_ZERO }; 
60: I = { `RETURN ,`RT_TRUE   }; 
	
	

//LABEL_MAIN_IS_NO_HIT:
61: I = { `NOP ,`RT_FALSE   }; 
62: I = { `CALL ,`ENTRYPOINT_ADRR_PIXELSHADER ,`VOID ,`VOID }; 
63: I = { `NOP ,`RT_FALSE   }; 
64: I = { `CALL ,`ENTRYPOINT_ADRR_NPG ,`VOID ,`VOID }; 
65: I = { `NOP ,`RT_FALSE   }; 
66: I = { `JNEX ,`LABEL_MAIN_RENDER_DONE ,`R99 ,`CREG_ZERO }; 
67: I = { `RETURN ,`RT_TRUE   }; 
//LABEL_MAIN_RENDER_DONE:
68: I = { `RETURN ,`RT_TRUE   }; 


//----------------------------------------------------------------------	  
//Micro code for CPPU
//TAG_CPPU_UCODE_ADDRESS:


69: I = { `SUB ,`R1 ,`CREG_PROJECTION_WINDOW_MAX ,`CREG_PROJECTION_WINDOW_MIN }; 
70: I = { `DIV ,`CREG_PROJECTION_WINDOW_SCALE ,`R1 ,`CREG_RESOLUTION }; 
71: I = { `COPY ,`CREG_PRIMITIVE_COUNT ,`CREG_MAX_PRIMITIVES ,`VOID }; 
72: I = { `RETURN ,`RT_FALSE   }; 

//----------------------------------------------------------------------	  
//Micro code for RGU
//TAG_RGU_UCODE_ADDRESS:


73: I = { `MUL ,`R1 ,`CREG_PIXEL_2D_POSITION ,`CREG_PROJECTION_WINDOW_SCALE }; 
74: I = { `ADD ,`R1 ,`R1 ,`CREG_PROJECTION_WINDOW_MIN }; 
75: I = { `SUB ,`CREG_UNORMALIZED_DIRECTION ,`R1 ,`CREG_CAMERA_POSITION }; 
76: I = { `MAG ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`VOID }; 
77: I = { `DIV ,`CREG_RAY_DIRECTION ,`CREG_UNORMALIZED_DIRECTION ,`R2 }; 
78: I = { `DEC ,`CREG_LAST_COL ,`CREG_PIXEL_2D_FINAL_POSITION ,`VOID }; 
79: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
  
80: I = { `RET ,`R99 ,`TRUE  }; 
//----------------------------------------------------------------------
//Next Pixel generation Code (NPG)
//TAG_NPG_UCODE_ADDRESS:

81: I = { `COPY ,`CREG_PRIMITIVE_COUNT ,`CREG_MAX_PRIMITIVES ,`VOID }; 

82: I = { `ZERO ,`CREG_TEXTURE_COLOR ,`VOID ,`VOID }; 
83: I = { `SETX ,`CREG_TEXTURE_COLOR ,32'h60000  }; 
84: I = { `ADD ,`CREG_CURRENT_OUTPUT_PIXEL ,`CREG_CURRENT_OUTPUT_PIXEL ,`CREG_3 }; 

85: I = { `ADD ,`CREG_PIXEL_PITCH ,`CREG_PIXEL_PITCH ,`CREG_3 }; 
86: I = { `COPY ,`OREG_ADDR_O ,`CREG_PIXEL_PITCH ,`VOID }; 
87: I = { `JGEX ,`LABEL_NPG_NEXT_ROW ,`CREG_PIXEL_2D_POSITION ,`CREG_LAST_COL }; 
88: I = { `INCX ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION ,`VOID }; 
89: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_NPG_NEXT_ROW:
90: I = { `SETX ,`CREG_PIXEL_2D_POSITION ,32'h0  }; 
91: I = { `INCY ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION ,`VOID }; 
92: I = { `JGEY ,`LABEL_ALLDONE ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_FINAL_POSITION }; 
93: I = { `NOP ,`RT_FALSE   }; 
94: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_ALLDONE:
95: I = { `NOP ,`RT_FALSE   }; 
96: I = { `RET ,`R99 ,`TRUE  }; 

//----------------------------------------------------------------------
//Micro code for AABBIU
//TAG_AABBIU_UCODE_ADDRESS:
	  
97: I = { `ZERO ,`R3 ,`VOID ,`VOID }; 
98: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
99: I = { `RETURN ,`RT_TRUE   }; 

//LABEL_TEST_RAY_X_ORIGEN:
100: I = { `JGEX ,`LABEL_ELSE_IFX ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
101: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
102: I = { `JLEX ,`LABEL1 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
103: I = { `RETURN ,`RT_FALSE   }; 

//LABEL1:
104: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
105: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
106: I = { `JMP ,`LABEL_TEST_RAY_Y_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELSE_IFX:
107: I = { `JLEX ,`LABEL_ELSEX ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
108: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
109: I = { `JGEX ,`LABEL2 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
110: I = { `RETURN ,`RT_FALSE   }; 
 
//LABEL2:
111: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
112: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
113: I = { `JMP ,`LABEL_TEST_RAY_Y_ORIGEN ,`VOID ,`VOID }; 
//LABEL_ELSEX:
114: I = { `SETX ,`R5 ,32'b1  }; 

//LABEL_TEST_RAY_Y_ORIGEN:
115: I = { `JGEY ,`LABEL_ELESE_IFY ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
116: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
117: I = { `JLEY ,`LABEL3 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
118: I = { `RETURN ,`RT_FALSE   }; 

//LABEL3:
119: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
120: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
121: I = { `JMP ,`LABEL_TEST_RAY_Z_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELESE_IFY:
122: I = { `JLEY ,`LABEL_ELSEY ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
123: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
124: I = { `JGEY ,`LABEL4 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
125: I = { `RETURN ,`RT_FALSE   }; 

//LABEL4:
126: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
127: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
128: I = { `JMP ,`LABEL_TEST_RAY_Z_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELSEY:
129: I = { `SETY ,`R5 ,32'b1  }; 

//LABEL_TEST_RAY_Z_ORIGEN:
130: I = { `JGEZ ,`LABEL_ELESE_IFZ ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
131: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
132: I = { `JLEZ ,`LABEL5 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
133: I = { `RETURN ,`RT_FALSE   }; 

//LABEL5:
134: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
135: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
136: I = { `JMP ,`LABEL_RAY_INSIDE_BOX ,`VOID ,`VOID }; 

//LABEL_ELESE_IFZ:
137: I = { `JLEZ ,`LABEL_ELSEZ ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
138: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
139: I = { `JGEZ ,`LABEL6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
140: I = { `RETURN ,`RT_FALSE   }; 

//LABEL6:
141: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
142: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
143: I = { `JMP ,`LABEL_RAY_INSIDE_BOX ,`VOID ,`VOID }; 

//LABEL_ELSEZ:
144: I = { `SETZ ,`R5 ,32'b1  }; 

//LABEL_RAY_INSIDE_BOX:
145: I = { `ZERO ,`R1 ,`VOID ,`VOID }; 
146: I = { `JEQX ,`LABEL_TEST_YZ_PLANE ,`R1 ,`RAY_INSIDE_BOX }; 
//BUG need a NOP here else pipeline gets confused
147: I = { `RETURN ,`RT_TRUE   }; 

//LABEL_TEST_YZ_PLANE:
148: I = { `JNEX ,`LABEL_TEST_XZ_PLANE ,`R5 ,`R1 }; 
149: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_XXX  }; 
150: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
151: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
152: I = { `JGEY ,`LABEL7 ,`R2 ,`CREG_AABBMIN }; 
153: I = { `RETURN ,`RT_FALSE   }; 

//LABEL7:
154: I = { `JLEY ,`LABEL8 ,`R2 ,`CREG_AABBMAX }; 
155: I = { `RETURN ,`RT_FALSE   }; 

//LABEL8:
156: I = { `JGEZ ,`LABEL9 ,`R2 ,`CREG_AABBMIN }; 
157: I = { `RETURN ,`RT_FALSE   }; 

//LABEL9:
158: I = { `JLEZ ,`LABEL_TEST_XZ_PLANE ,`R2 ,`CREG_AABBMAX }; 
159: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_TEST_XZ_PLANE:
160: I = { `JNEY ,`LABEL_TEST_XY_PLANE ,`R5 ,`R1 }; 
161: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_YYY  }; 
162: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
163: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
164: I = { `JGEX ,`LABEL10 ,`R2 ,`CREG_AABBMIN }; 
165: I = { `RETURN ,`RT_FALSE   }; 

//LABEL10:
166: I = { `JLEX ,`LABEL11 ,`R2 ,`CREG_AABBMAX }; 
167: I = { `RETURN ,`RT_FALSE   }; 

//LABEL11:
168: I = { `JGEZ ,`LABEL12 ,`R2 ,`CREG_AABBMIN }; 
169: I = { `RETURN ,`RT_FALSE   }; 

//LABEL12:
170: I = { `JLEZ ,`LABEL_TEST_XY_PLANE ,`R2 ,`CREG_AABBMAX }; 
171: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_TEST_XY_PLANE:
172: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_ZZZ  }; 
173: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
174: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
175: I = { `JGEX ,`LABEL13 ,`R2 ,`CREG_AABBMIN }; 
176: I = { `RETURN ,`RT_FALSE   }; 

//LABEL13:
177: I = { `JLEX ,`LABEL14 ,`R2 ,`CREG_AABBMAX }; 
178: I = { `RETURN ,`RT_FALSE   }; 

//LABEL14:
179: I = { `JGEY ,`LABEL15 ,`R2 ,`CREG_AABBMIN }; 
180: I = { `RETURN ,`RT_FALSE   }; 

//LABEL15:
181: I = { `JLEY ,`LABEL_HIT ,`R2 ,`CREG_AABBMAX }; 
182: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_HIT:
183: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
184: I = { `RETURN ,`RT_TRUE   }; 

 //------------------------------------------------------------------------
 //BIU Micro code
//TAG_BIU_UCODE_ADDRESS:
			  
185: I = { `ZERO ,`OREG_PIXEL_COLOR ,`VOID ,`VOID }; 
186: I = { `SETY ,`R3 ,`ONE  }; 
//SETX R1 32'h00000   
187: I = { `SUB ,`CREG_E1 ,`CREG_V1 ,`CREG_V0 }; 
188: I = { `SUB ,`CREG_E2 ,`CREG_V2 ,`CREG_V0 }; 
189: I = { `SUB ,`CREG_T ,`CREG_CAMERA_POSITION ,`CREG_V0 }; 
190: I = { `CROSS ,`CREG_P ,`CREG_RAY_DIRECTION ,`CREG_E2 }; 
191: I = { `CROSS ,`CREG_Q ,`CREG_T ,`CREG_E1 }; 

192: I = { `DOT ,`CREG_H1 ,`CREG_Q ,`CREG_E2 }; 
193: I = { `DOT ,`R1 ,`CREG_P ,`CREG_T }; 
194: I = { `XCHANGEY ,`CREG_H1 ,`CREG_H1 ,`R1 }; 
195: I = { `DOT ,`R1 ,`CREG_Q ,`CREG_RAY_DIRECTION }; 
196: I = { `XCHANGEZ ,`CREG_H1 ,`CREG_H1 ,`R1 }; 

//DOT CREG_H1 CREG_Q CREG_E2  
//DOT CREG_H2 CREG_P CREG_T  
//DOT CREG_H3 CREG_Q CREG_RAY_DIRECTION  
197: I = { `DOT ,`CREG_DELTA ,`CREG_P ,`CREG_E1 }; 

198: I = { `DIV ,`CREG_t ,`CREG_H1 ,`CREG_DELTA }; 
//DIV CREG_t CREG_H1 CREG_DELTA  
//DIV CREG_u CREG_H2 CREG_DELTA  
//DIV CREG_v CREG_H3 CREG_DELTA  
199: I = { `JGEY ,`LABEL_BIU1 ,`CREG_t ,`CREG_ZERO }; 
200: I = { `NOP ,`RT_FALSE   }; 
201: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_BIU1:
//JGEX LABEL_BIU2 CREG_v R1  
202: I = { `JGEZ ,`LABEL_BIU2 ,`CREG_t ,`CREG_ZERO }; 
203: I = { `NOP ,`RT_FALSE   }; 
204: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_BIU2:
//ADD R2 CREG_u CREG_v  
205: I = { `COPY ,`R1 ,`CREG_t ,`VOID }; 
206: I = { `SWIZZLE3D ,`R1 ,`SWIZZLE_ZZZ  }; 
207: I = { `ADD ,`R2 ,`R1 ,`CREG_t }; 
208: I = { `JLEY ,`LABEL_BIU3 ,`R2 ,`R3 }; 
//JLEX LABEL_BIU3 R2 R3  
209: I = { `NOP ,`RT_FALSE   }; 
210: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_BIU3:
211: I = { `JGEX ,`LABEL_BIU4 ,`CREG_t ,`CREG_LAST_t }; 
212: I = { `COPY ,`CREG_LAST_t ,`CREG_t ,`VOID }; 
213: I = { `SWIZZLE3D ,`CREG_LAST_t ,`SWIZZLE_XXX  }; 
214: I = { `COPY ,`CREG_LAST_u ,`CREG_t ,`VOID }; 
215: I = { `SWIZZLE3D ,`CREG_LAST_u ,`SWIZZLE_YYY  }; 
216: I = { `COPY ,`CREG_LAST_v ,`CREG_t ,`VOID }; 
217: I = { `SWIZZLE3D ,`CREG_LAST_v ,`SWIZZLE_ZZZ  }; 

218: I = { `COPY ,`CREG_E1_LAST ,`CREG_E1 ,`VOID }; 
219: I = { `COPY ,`CREG_E2_LAST ,`CREG_E2 ,`VOID }; 
220: I = { `COPY ,`CREG_UV0_LAST ,`CREG_UV0 ,`VOID }; 
221: I = { `COPY ,`CREG_UV1_LAST ,`CREG_UV1 ,`VOID }; 
222: I = { `COPY ,`CREG_UV2_LAST ,`CREG_UV2 ,`VOID }; 
223: I = { `COPY ,`CREG_TRI_DIFFUSE_LAST ,`CREG_TRI_DIFFUSE ,`VOID }; 
224: I = { `RET ,`R99 ,`TRUE  }; 
//LABEL_BIU4:
225: I = { `RET ,`R99 ,`FALSE  }; 


//-------------------------------------------------------------------------
//Calculate the adress of the texure coordiantes.

//TAG_TCC_UCODE_ADDRESS:
//Do this calculation only if this triangle is the one closest to the camera
226: I = { `JGX ,`LABEL_TCC_EXIT ,`CREG_t ,`CREG_LAST_t }; 

//First get the UV coodrinates and store in R1
//R1x: u_coordinate = U0 + last_u * (U1 - U0) + last_v * (U2 - U0)
//R1y: v_coordinate = V0 + last_u * (V1 - V0) + last_v * (V2 - V0)
//R1z: 0

227: I = { `SUB ,`R1 ,`CREG_UV1_LAST ,`CREG_UV0_LAST }; 
228: I = { `SUB ,`R2 ,`CREG_UV2_LAST ,`CREG_UV0_LAST }; 
229: I = { `MUL ,`R1 ,`CREG_LAST_u ,`R1 }; 
230: I = { `MUL ,`R2 ,`CREG_LAST_v ,`R2 }; 
231: I = { `ADD ,`R1 ,`R1 ,`R2 }; 
232: I = { `ADD ,`R1 ,`R1 ,`CREG_UV0_LAST }; 

//R7x : fu = (u_coordinate) * gTexture.mWidth
//R7y : fv = (v_coordinate) * gTexture.mWidth
//R7z : 0
233: I = { `MUL ,`R7 ,`R1 ,`CREG_TEXTURE_SIZE }; 

//R1x: u1 = ((int)fu) % gTexture.mWidth
//R1y: v1 = ((int)fv) % gTexture.mHeight
//R1z: 0
//R2x: u2 = (u1 + 1 ) % gTexture.mWidth
//R2y: v2 = (v2 + 1 ) % gTexture.mHeight
//R2z: 0
// Notice MOD2 only operates over
// numbers that are power of 2 also notice that the
// textures are assumed to be squares!
//x % 2^n == x & (2^n - 1).

234: I = { `MOD ,`R1 ,`R7 ,`CREG_TEXTURE_SIZE }; 
235: I = { `INC ,`R2 ,`R1 ,`VOID }; 
236: I = { `MOD ,`R2 ,`R2 ,`CREG_TEXTURE_SIZE }; 

//Cool now we should store the values in the appropiate registers
//OREG_TEX_COORD1.x = u1 + v1 * gTexture.mWidth
//OREG_TEX_COORD1.y = u2 + v1 * gTexture.mWidth
//OREG_TEX_COORD1.z = 0
//OREG_TEX_COORD2.x = u1 + v2 * gTexture.mWidth
//OREG_TEX_COORD2.y = u2 + v2 * gTexture.mWidth
//OREG_TEX_COORD1.z = 0

//R1= [u1 v1 0]
//R2= [u2 v2 0]

//R2 = [v2 u2 0]
237: I = { `SWIZZLE3D ,`R2 ,`SWIZZLE_YXZ  }; 

//R3 = [v2 v1 0]
238: I = { `XCHANGEX ,`R3 ,`R1 ,`R2 }; 


//R4 = [u1 u2 0]
239: I = { `XCHANGEX ,`R4 ,`R2 ,`R1 }; 

//R2 = [v2*H v1*H 0]
240: I = { `UNSCALE ,`R9 ,`R3 ,`VOID }; 
241: I = { `UNSCALE ,`R8 ,`CREG_TEXTURE_SIZE ,`VOID }; 
242: I = { `IMUL ,`R2 ,`R9 ,`R8 }; 

//OREG_TEX_COORD1 = [u1 + v2*H u2 + v1*H 0]
//R4 = FixedToIinteger(R4)
243: I = { `UNSCALE ,`R4 ,`R4 ,`VOID }; 
244: I = { `ADD ,`R12 ,`R2 ,`R4 }; 
245: I = { `SETX ,`R5 ,32'h3  }; 
246: I = { `SETY ,`R5 ,32'h3  }; 
247: I = { `SETZ ,`R5 ,32'h3  }; 
//Multiply by 3 (the pitch)
//IMUL OREG_TEX_COORD1 R12 R5  
248: I = { `IMUL ,`CREG_TEX_COORD1 ,`R12 ,`R5 }; 

//R4 = [u2 u1 0]
249: I = { `SWIZZLE3D ,`R4 ,`SWIZZLE_YXZ  }; 


//OREG_TEX_COORD2 [u2 + v2*H u1 + v1*H 0]
250: I = { `ADD ,`R12 ,`R2 ,`R4 }; 
//Multiply by 3 (the pitch)
//IMUL OREG_TEX_COORD2 R12 R5  
251: I = { `IMUL ,`CREG_TEX_COORD2 ,`R12 ,`R5 }; 


//Cool now get the weights

//w1 = (1 - fracu) * (1 - fracv)
//w2 = fracu * (1 - fracv)
//w3 = (1 - fracu) * fracv
//w4 = fracu *  fracv

//R4x: fracu 
//R4y: fracv 
//R4z: 0
252: I = { `FRAC ,`R4 ,`R7 ,`VOID }; 

//R5x: fracv 
//R5y: fracu 
//R5z: 0 
253: I = { `COPY ,`R5 ,`R4 ,`VOID }; 
254: I = { `SWIZZLE3D ,`R5 ,`SWIZZLE_YXZ  }; 


//R5x: 1 - fracv 
//R5y: 1 - fracu 
//R5y: 1
255: I = { `NEG ,`R5 ,`R5 ,`VOID }; 
256: I = { `INC ,`R5 ,`R5 ,`VOID }; 

//R5x: 1 - fracv 
//R5y: 1 - fracu 
//R5y: (1 - fracv)(1 - fracu) 
257: I = { `MULP ,`CREG_TEXWEIGHT1 ,`R5 ,`VOID }; 

//CREG_TEXWEIGHT1.x = (1 - fracv)(1 - fracu) 
//CREG_TEXWEIGHT1.y = (1 - fracv)(1 - fracu) 
//CREG_TEXWEIGHT1.z = (1 - fracv)(1 - fracu) 
258: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT1 ,`SWIZZLE_ZZZ  }; 


//R6x: w2: fracu * (1 - fracv )
//R6y: w3: fracv * (1 - fracu )
//R6z: 0
259: I = { `MUL ,`R6 ,`R4 ,`R5 }; 

//CREG_TEXWEIGHT2.x = fracu * (1 - fracv )
//CREG_TEXWEIGHT2.y = fracu * (1 - fracv )
//CREG_TEXWEIGHT2.z = fracu * (1 - fracv )
260: I = { `COPY ,`CREG_TEXWEIGHT2 ,`R6 ,`VOID }; 
261: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT2 ,`SWIZZLE_XXX  }; 

//CREG_TEXWEIGHT3.x = fracv * (1 - fracu )
//CREG_TEXWEIGHT3.y = fracv * (1 - fracu )
//CREG_TEXWEIGHT3.z = fracv * (1 - fracu )
262: I = { `COPY ,`CREG_TEXWEIGHT3 ,`R6 ,`VOID }; 
263: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT3 ,`SWIZZLE_YYY  }; 


//R4x: fracu
//R4y: fracv
//R4z: fracu * fracv
264: I = { `MULP ,`R4 ,`R4 ,`VOID }; 

//CREG_TEXWEIGHT4.x = fracv * fracu 
//CREG_TEXWEIGHT4.y = fracv * fracu 
//CREG_TEXWEIGHT4.z = fracv * fracu 
265: I = { `COPY ,`CREG_TEXWEIGHT4 ,`R4 ,`VOID }; 
266: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT4 ,`SWIZZLE_ZZZ  }; 


//LABEL_TCC_EXIT:
267: I = { `RET ,`R99 ,32'h0  }; 


//-------------------------------------------------------------------------
//TAG_PSU_UCODE_ADRESS:
//Pixel Shader #1
//This pixel shader has diffuse light but no textures

	 
268: I = { `CROSS ,`R1 ,`CREG_E1_LAST ,`CREG_E2_LAST }; 
269: I = { `MAG ,`R2 ,`R1 ,`VOID }; 
270: I = { `DIV ,`R1 ,`R1 ,`R2 }; 
271: I = { `MUL ,`R2 ,`CREG_RAY_DIRECTION ,`CREG_LAST_t }; 
272: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
273: I = { `SUB ,`R2 ,`CURRENT_LIGHT_POS ,`R2 }; 
274: I = { `MAG ,`R3 ,`R2 ,`VOID }; 
275: I = { `DIV ,`R2 ,`R2 ,`R3 }; 
276: I = { `DOT ,`R3 ,`R2 ,`R1 }; 
277: I = { `MUL ,`CREG_COLOR_ACC ,`CREG_TRI_DIFFUSE_LAST ,`CURRENT_LIGHT_DIFFUSE }; 
278: I = { `MUL ,`CREG_COLOR_ACC ,`CREG_COLOR_ACC ,`R3 }; 
279: I = { `COPY ,`CREG_TEXTURE_COLOR ,`CREG_COLOR_ACC ,`VOID }; 
280: I = { `NOP ,`RT_FALSE   }; 
281: I = { `NOP ,`RT_FALSE   }; 
282: I = { `NOP ,`RT_FALSE   }; 
283: I = { `RET ,`R99 ,`TRUE  }; 

//-------------------------------------------------------------------------
//Pixel Shader #2
//TAG_PSU_UCODE_ADRESS2:
//This Pixel Shader has no light but it does texturinng 
//with bi-linear interpolation



284: I = { `COPY ,`R1 ,`CREG_TEX_COORD1 ,`VOID }; 
285: I = { `COPY ,`R2 ,`CREG_TEX_COORD1 ,`VOID }; 
286: I = { `COPY ,`R3 ,`CREG_TEX_COORD2 ,`VOID }; 
287: I = { `COPY ,`R4 ,`CREG_TEX_COORD2 ,`VOID }; 


288: I = { `SWIZZLE3D ,`R1 ,`SWIZZLE_XXX  }; 
289: I = { `SWIZZLE3D ,`R2 ,`SWIZZLE_YYY  }; 
290: I = { `SWIZZLE3D ,`R3 ,`SWIZZLE_XXX  }; 
291: I = { `SWIZZLE3D ,`R4 ,`SWIZZLE_YYY  }; 
292: I = { `ADD ,`R1 ,`R1 ,`CREG_012 }; 
293: I = { `ADD ,`R2 ,`R2 ,`CREG_012 }; 
294: I = { `ADD ,`R3 ,`R3 ,`CREG_012 }; 
295: I = { `ADD ,`R4 ,`R4 ,`CREG_012 }; 


296: I = { `TMREAD ,`CREG_TEX_COLOR1 ,`R1 ,`VOID }; 
297: I = { `NOP ,`RT_FALSE   }; 
298: I = { `TMREAD ,`CREG_TEX_COLOR2 ,`R2 ,`VOID }; 
299: I = { `NOP ,`RT_FALSE   }; 
300: I = { `TMREAD ,`CREG_TEX_COLOR3 ,`R3 ,`VOID }; 
301: I = { `NOP ,`RT_FALSE   }; 
302: I = { `TMREAD ,`CREG_TEX_COLOR4 ,`R4 ,`VOID }; 
303: I = { `NOP ,`RT_FALSE   }; 




//TextureColor.R = c1.R * w1 + c2.R * w2 + c3.R * w3 + c4.R * w4
//TextureColor.G = c1.G * w1 + c2.G * w2 + c3.G * w3 + c4.G * w4
//TextureColor.B = c1.B * w1 + c2.B * w2 + c3.B * w3 + c4.B * w4


//MUL R1 CREG_TEX_COLOR4 CREG_TEXWEIGHT1  
//MUL R2 CREG_TEX_COLOR2 CREG_TEXWEIGHT2  
//MUL R3 CREG_TEX_COLOR1 CREG_TEXWEIGHT3  
//MUL R4 CREG_TEX_COLOR3 CREG_TEXWEIGHT4  

304: I = { `MUL ,`R1 ,`CREG_TEX_COLOR3 ,`CREG_TEXWEIGHT1 }; 
305: I = { `MUL ,`R2 ,`CREG_TEX_COLOR2 ,`CREG_TEXWEIGHT2 }; 
306: I = { `MUL ,`R3 ,`CREG_TEX_COLOR1 ,`CREG_TEXWEIGHT3 }; 
307: I = { `MUL ,`R4 ,`CREG_TEX_COLOR4 ,`CREG_TEXWEIGHT4 }; 

308: I = { `ADD ,`CREG_TEXTURE_COLOR ,`R1 ,`R2 }; 
309: I = { `ADD ,`CREG_TEXTURE_COLOR ,`CREG_TEXTURE_COLOR ,`R3 }; 
310: I = { `ADD ,`CREG_TEXTURE_COLOR ,`CREG_TEXTURE_COLOR ,`R4 }; 
311: I = { `RET ,`R99 ,`TRUE  }; 


//-------------------------------------------------------------------------
//Default User constants
//TAG_USERCONSTANTS:

312: I = { `NOP ,`RT_FALSE   }; 
313: I = { `RETURN ,`RT_FALSE   }; 

//TAG_PIXELSHADER:
//Default Pixel Shader (just outputs texture)
314: I = { `OMWRITE ,`OREG_PIXEL_COLOR ,`CREG_CURRENT_OUTPUT_PIXEL ,`CREG_TEXTURE_COLOR }; 
315: I = { `NOP ,`RT_FALSE   }; 
316: I = { `RET ,`R99 ,`TRUE  }; 
317: I = { `NOP ,`RT_FALSE   }; 


//-------------------------------------------------------------------------		
		

			default: 
			begin
			
			`ifdef DEBUG
			$display("%dns CORE %d Error: Reached undefined address in instruction Memory: %d!!!!",$time,iDebug_CoreID,Address);
		//	$stop();
			`endif
			I =  {`INSTRUCTION_OP_LENGTH'hFF,16'hFFFF,32'hFFFFFFFF};
			end
			endcase
	end
endmodule
//--------------------------------------------------------