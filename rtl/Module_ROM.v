

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
`define TAG_PIXELSHADER 16'd311
`define TAG_USERCONSTANTS 16'd309
`define TAG_PSU_UCODE_ADRESS2 16'd281
`define TAG_PSU_UCODE_ADRESS 16'd265
`define LABEL_TCC_EXIT 16'd264
`define TAG_TCC_UCODE_ADDRESS 16'd223
`define LABEL_BIU4 16'd222
`define LABEL_BIU3 16'd211
`define LABEL_BIU2 16'd207
`define LABEL_BIU1 16'd204
`define TAG_BIU_UCODE_ADDRESS 16'd186
`define LABEL_HIT 16'd184
`define LABEL15 16'd182
`define LABEL14 16'd180
`define LABEL13 16'd178
`define LABEL_TEST_XY_PLANE 16'd173
`define LABEL12 16'd171
`define LABEL11 16'd169
`define LABEL10 16'd167
`define LABEL_TEST_XZ_PLANE 16'd161
`define LABEL9 16'd159
`define LABEL8 16'd157
`define LABEL7 16'd155
`define LABEL_TEST_YZ_PLANE 16'd149
`define LABEL_RAY_INSIDE_BOX 16'd146
`define LABEL_ELSEZ 16'd145
`define LABEL6 16'd142
`define LABEL_ELESE_IFZ 16'd138
`define LABEL5 16'd135
`define LABEL_TEST_RAY_Z_ORIGEN 16'd131
`define LABEL_ELSEY 16'd130
`define LABEL4 16'd127
`define LABEL_ELESE_IFY 16'd123
`define LABEL3 16'd120
`define LABEL_TEST_RAY_Y_ORIGEN 16'd116
`define LABEL_ELSEX 16'd115
`define LABEL2 16'd112
`define LABEL_ELSE_IFX 16'd108
`define LABEL1 16'd105
`define LABEL_TEST_RAY_X_ORIGEN 16'd101
`define TAG_AABBIU_UCODE_ADDRESS 16'd98
`define LABEL_ALLDONE 16'd96
`define LABEL_NPG_NEXT_ROW 16'd91
`define TAG_NPG_UCODE_ADDRESS 16'd82
`define TAG_RGU_UCODE_ADDRESS 16'd74
`define TAG_CPPU_UCODE_ADDRESS 16'd70
`define LABEL_MAIN_RENDER_DONE 16'd69
`define LABEL_MAIN_IS_NO_HIT 16'd62
`define LABEL_MAIN_IS_HIT 16'd51
`define LABEL_MAIN_CHECK_HIT 16'd50
`define LABEL_DEC_PRIM_COUNT 16'd47
`define LABEL_MAIN_TEST_INTERSECTION 16'd42
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
37: I =  { `NOP ,`RT_FALSE   };
	//Generate the ray, but this is wrong, it has to generate only once for all the triangles..
38: I = { `JNEX ,`LABEL_MAIN_TEST_INTERSECTION ,`CREG_PRIMITIVE_COUNT ,`CREG_MAX_PRIMITIVES }; 
39: I = { `CALL ,`ENTRYPOINT_ADRR_RGU ,`VOID ,`VOID }; 
40: I = { `ZERO ,`CREG_HIT ,`VOID ,`VOID }; 
41: I = { `RESCALE ,`CREG_PRIMITIVE_COUNT ,`CREG_MAX_PRIMITIVES ,`VOID }; 
	
//LABEL_MAIN_TEST_INTERSECTION:
	//Check ofr triangle intersection
42: I = { `NOP ,`RT_FALSE   }; 
43: I = { `CALL ,`ENTRYPOINT_ADRR_BIU ,`VOID ,`VOID }; 
44: I = { `NOP ,`RT_FALSE   }; 
	
45: I = { `JEQX ,`LABEL_DEC_PRIM_COUNT ,`R99 ,`CREG_ZERO }; 
46: I = { `COPY ,`CREG_HIT ,`R99 ,`VOID }; 
//LABEL_DEC_PRIM_COUNT:
47: I = { `DEC ,`CREG_PRIMITIVE_COUNT ,`CREG_PRIMITIVE_COUNT ,`VOID }; 
48: I = { `JEQX ,`LABEL_MAIN_CHECK_HIT ,`CREG_PRIMITIVE_COUNT ,`CREG_ZERO }; 
49: I = { `RETURN ,`RT_FALSE   }; 
	
//LABEL_MAIN_CHECK_HIT:
50: I = { `JEQX ,`LABEL_MAIN_IS_NO_HIT ,`CREG_HIT ,`CREG_ZERO }; 
	
	
	
//LABEL_MAIN_IS_HIT:
51: I = { `NOP ,`RT_FALSE   }; 
52: I = { `CALL ,`ENTRYPOINT_ADRR_TCC ,`VOID ,`VOID }; 
53: I = { `NOP ,`RT_FALSE   }; 
54: I = { `CALL ,`ENTRYPOINT_ADRR_PSU2 ,`VOID ,`VOID }; 
55: I = { `NOP ,`RT_FALSE   }; 
56: I = { `CALL ,`ENTRYPOINT_ADRR_PIXELSHADER ,`VOID ,`VOID }; 
57: I = { `NOP ,`RT_FALSE   }; 
58: I = { `CALL ,`ENTRYPOINT_ADRR_NPG ,`VOID ,`VOID }; 
59: I = { `NOP ,`RT_FALSE   }; 
60: I = { `JEQX ,`LABEL_MAIN_RENDER_DONE ,`R99 ,`CREG_ZERO }; 
61: I = { `RETURN ,`RT_TRUE   }; 
	
	

//LABEL_MAIN_IS_NO_HIT:
62: I = { `NOP ,`RT_FALSE   }; 
63: I = { `CALL ,`ENTRYPOINT_ADRR_PIXELSHADER ,`VOID ,`VOID }; 
64: I = { `NOP ,`RT_FALSE   }; 
65: I = { `CALL ,`ENTRYPOINT_ADRR_NPG ,`VOID ,`VOID }; 
66: I = { `NOP ,`RT_FALSE   }; 
67: I = { `JNEX ,`LABEL_MAIN_RENDER_DONE ,`R99 ,`CREG_ZERO }; 
68: I = { `RETURN ,`RT_TRUE   }; 
//LABEL_MAIN_RENDER_DONE:
69: I = { `RETURN ,`RT_TRUE   }; 


//----------------------------------------------------------------------	  
//Micro code for CPPU
//TAG_CPPU_UCODE_ADDRESS:


70: I = { `SUB ,`R1 ,`CREG_PROJECTION_WINDOW_MAX ,`CREG_PROJECTION_WINDOW_MIN }; 
71: I = { `DIV ,`CREG_PROJECTION_WINDOW_SCALE ,`R1 ,`CREG_RESOLUTION }; 
72: I = { `COPY ,`CREG_PRIMITIVE_COUNT ,`CREG_MAX_PRIMITIVES ,`VOID }; 
73: I = { `RETURN ,`RT_FALSE   }; 

//----------------------------------------------------------------------	  
//Micro code for RGU
//TAG_RGU_UCODE_ADDRESS:


74: I = { `MUL ,`R1 ,`CREG_PIXEL_2D_POSITION ,`CREG_PROJECTION_WINDOW_SCALE }; 
75: I = { `ADD ,`R1 ,`R1 ,`CREG_PROJECTION_WINDOW_MIN }; 
76: I = { `SUB ,`CREG_UNORMALIZED_DIRECTION ,`R1 ,`CREG_CAMERA_POSITION }; 
77: I = { `MAG ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`VOID }; 
78: I = { `DIV ,`CREG_RAY_DIRECTION ,`CREG_UNORMALIZED_DIRECTION ,`R2 }; 
79: I = { `DEC ,`CREG_LAST_COL ,`CREG_PIXEL_2D_FINAL_POSITION ,`VOID }; 
80: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
  
81: I = { `RET ,`R99 ,`TRUE  }; 
//----------------------------------------------------------------------
//Next Pixel generation Code (NPG)
//TAG_NPG_UCODE_ADDRESS:

82: I = { `COPY ,`CREG_PRIMITIVE_COUNT ,`CREG_MAX_PRIMITIVES ,`VOID }; 

83: I = { `ZERO ,`CREG_TEXTURE_COLOR ,`VOID ,`VOID }; 
84: I = { `SETX ,`CREG_TEXTURE_COLOR ,32'h60000  }; 
85: I = { `ADD ,`CREG_CURRENT_OUTPUT_PIXEL ,`CREG_CURRENT_OUTPUT_PIXEL ,`CREG_3 }; 

86: I = { `ADD ,`CREG_PIXEL_PITCH ,`CREG_PIXEL_PITCH ,`CREG_3 }; 
87: I = { `COPY ,`OREG_ADDR_O ,`CREG_PIXEL_PITCH ,`VOID }; 
88: I = { `JGEX ,`LABEL_NPG_NEXT_ROW ,`CREG_PIXEL_2D_POSITION ,`CREG_LAST_COL }; 
89: I = { `INCX ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION ,`VOID }; 
90: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_NPG_NEXT_ROW:
91: I = { `SETX ,`CREG_PIXEL_2D_POSITION ,32'h0  }; 
92: I = { `INCY ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION ,`VOID }; 
93: I = { `JGEY ,`LABEL_ALLDONE ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_FINAL_POSITION }; 
94: I = { `NOP ,`RT_FALSE   }; 
95: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_ALLDONE:
96: I = { `NOP ,`RT_FALSE   }; 
97: I = { `RET ,`R99 ,`TRUE  }; 

//----------------------------------------------------------------------
//Micro code for AABBIU
//TAG_AABBIU_UCODE_ADDRESS:
	  
98: I = { `ZERO ,`R3 ,`VOID ,`VOID }; 
99: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
100: I = { `RETURN ,`RT_TRUE   }; 

//LABEL_TEST_RAY_X_ORIGEN:
101: I = { `JGEX ,`LABEL_ELSE_IFX ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
102: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
103: I = { `JLEX ,`LABEL1 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
104: I = { `RETURN ,`RT_FALSE   }; 

//LABEL1:
105: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
106: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
107: I = { `JMP ,`LABEL_TEST_RAY_Y_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELSE_IFX:
108: I = { `JLEX ,`LABEL_ELSEX ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
109: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
110: I = { `JGEX ,`LABEL2 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
111: I = { `RETURN ,`RT_FALSE   }; 
 
//LABEL2:
112: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
113: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
114: I = { `JMP ,`LABEL_TEST_RAY_Y_ORIGEN ,`VOID ,`VOID }; 
//LABEL_ELSEX:
115: I = { `SETX ,`R5 ,32'b1  }; 

//LABEL_TEST_RAY_Y_ORIGEN:
116: I = { `JGEY ,`LABEL_ELESE_IFY ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
117: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
118: I = { `JLEY ,`LABEL3 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
119: I = { `RETURN ,`RT_FALSE   }; 

//LABEL3:
120: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
121: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
122: I = { `JMP ,`LABEL_TEST_RAY_Z_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELESE_IFY:
123: I = { `JLEY ,`LABEL_ELSEY ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
124: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
125: I = { `JGEY ,`LABEL4 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
126: I = { `RETURN ,`RT_FALSE   }; 

//LABEL4:
127: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
128: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
129: I = { `JMP ,`LABEL_TEST_RAY_Z_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELSEY:
130: I = { `SETY ,`R5 ,32'b1  }; 

//LABEL_TEST_RAY_Z_ORIGEN:
131: I = { `JGEZ ,`LABEL_ELESE_IFZ ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
132: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
133: I = { `JLEZ ,`LABEL5 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
134: I = { `RETURN ,`RT_FALSE   }; 

//LABEL5:
135: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
136: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
137: I = { `JMP ,`LABEL_RAY_INSIDE_BOX ,`VOID ,`VOID }; 

//LABEL_ELESE_IFZ:
138: I = { `JLEZ ,`LABEL_ELSEZ ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
139: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
140: I = { `JGEZ ,`LABEL6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
141: I = { `RETURN ,`RT_FALSE   }; 

//LABEL6:
142: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
143: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
144: I = { `JMP ,`LABEL_RAY_INSIDE_BOX ,`VOID ,`VOID }; 

//LABEL_ELSEZ:
145: I = { `SETZ ,`R5 ,32'b1  }; 

//LABEL_RAY_INSIDE_BOX:
146: I = { `ZERO ,`R1 ,`VOID ,`VOID }; 
147: I = { `JEQX ,`LABEL_TEST_YZ_PLANE ,`R1 ,`RAY_INSIDE_BOX }; 
//BUG need a NOP here else pipeline gets confused
148: I = { `RETURN ,`RT_TRUE   }; 

//LABEL_TEST_YZ_PLANE:
149: I = { `JNEX ,`LABEL_TEST_XZ_PLANE ,`R5 ,`R1 }; 
150: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_XXX  }; 
151: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
152: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
153: I = { `JGEY ,`LABEL7 ,`R2 ,`CREG_AABBMIN }; 
154: I = { `RETURN ,`RT_FALSE   }; 

//LABEL7:
155: I = { `JLEY ,`LABEL8 ,`R2 ,`CREG_AABBMAX }; 
156: I = { `RETURN ,`RT_FALSE   }; 

//LABEL8:
157: I = { `JGEZ ,`LABEL9 ,`R2 ,`CREG_AABBMIN }; 
158: I = { `RETURN ,`RT_FALSE   }; 

//LABEL9:
159: I = { `JLEZ ,`LABEL_TEST_XZ_PLANE ,`R2 ,`CREG_AABBMAX }; 
160: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_TEST_XZ_PLANE:
161: I = { `JNEY ,`LABEL_TEST_XY_PLANE ,`R5 ,`R1 }; 
162: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_YYY  }; 
163: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
164: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
165: I = { `JGEX ,`LABEL10 ,`R2 ,`CREG_AABBMIN }; 
166: I = { `RETURN ,`RT_FALSE   }; 

//LABEL10:
167: I = { `JLEX ,`LABEL11 ,`R2 ,`CREG_AABBMAX }; 
168: I = { `RETURN ,`RT_FALSE   }; 

//LABEL11:
169: I = { `JGEZ ,`LABEL12 ,`R2 ,`CREG_AABBMIN }; 
170: I = { `RETURN ,`RT_FALSE   }; 

//LABEL12:
171: I = { `JLEZ ,`LABEL_TEST_XY_PLANE ,`R2 ,`CREG_AABBMAX }; 
172: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_TEST_XY_PLANE:
173: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_ZZZ  }; 
174: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
175: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
176: I = { `JGEX ,`LABEL13 ,`R2 ,`CREG_AABBMIN }; 
177: I = { `RETURN ,`RT_FALSE   }; 

//LABEL13:
178: I = { `JLEX ,`LABEL14 ,`R2 ,`CREG_AABBMAX }; 
179: I = { `RETURN ,`RT_FALSE   }; 

//LABEL14:
180: I = { `JGEY ,`LABEL15 ,`R2 ,`CREG_AABBMIN }; 
181: I = { `RETURN ,`RT_FALSE   }; 

//LABEL15:
182: I = { `JLEY ,`LABEL_HIT ,`R2 ,`CREG_AABBMAX }; 
183: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_HIT:
184: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
185: I = { `RETURN ,`RT_TRUE   }; 

 //------------------------------------------------------------------------
 //BIU Micro code
//TAG_BIU_UCODE_ADDRESS:
			  
186: I = { `ZERO ,`OREG_PIXEL_COLOR ,`VOID ,`VOID }; 
187: I = { `SETX ,`R3 ,`ONE  }; 
188: I = { `SETX ,`R1 ,32'h00000  }; 
189: I = { `SUB ,`CREG_E1 ,`CREG_V1 ,`CREG_V0 }; 
190: I = { `SUB ,`CREG_E2 ,`CREG_V2 ,`CREG_V0 }; 
191: I = { `SUB ,`CREG_T ,`CREG_CAMERA_POSITION ,`CREG_V0 }; 
192: I = { `CROSS ,`CREG_P ,`CREG_RAY_DIRECTION ,`CREG_E2 }; 
193: I = { `CROSS ,`CREG_Q ,`CREG_T ,`CREG_E1 }; 
194: I = { `DOT ,`CREG_H1 ,`CREG_Q ,`CREG_E2 }; 
195: I = { `DOT ,`CREG_H2 ,`CREG_P ,`CREG_T }; 
196: I = { `DOT ,`CREG_H3 ,`CREG_Q ,`CREG_RAY_DIRECTION }; 
197: I = { `DOT ,`CREG_DELTA ,`CREG_P ,`CREG_E1 }; 
198: I = { `DIV ,`CREG_t ,`CREG_H1 ,`CREG_DELTA }; 
199: I = { `DIV ,`CREG_u ,`CREG_H2 ,`CREG_DELTA }; 
200: I = { `DIV ,`CREG_v ,`CREG_H3 ,`CREG_DELTA }; 
201: I = { `JGEX ,`LABEL_BIU1 ,`CREG_u ,`R1 }; 
202: I = { `NOP ,`RT_FALSE   }; 
203: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_BIU1:
204: I = { `JGEX ,`LABEL_BIU2 ,`CREG_v ,`R1 }; 
205: I = { `NOP ,`RT_FALSE   }; 
206: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_BIU2:
207: I = { `ADD ,`R2 ,`CREG_u ,`CREG_v }; 
208: I = { `JLEX ,`LABEL_BIU3 ,`R2 ,`R3 }; 
209: I = { `NOP ,`RT_FALSE   }; 
210: I = { `RET ,`R99 ,`FALSE  }; 

//LABEL_BIU3:
211: I = { `JGEX ,`LABEL_BIU4 ,`CREG_t ,`CREG_LAST_t }; 
212: I = { `COPY ,`CREG_LAST_t ,`CREG_t ,`VOID }; 
213: I = { `COPY ,`CREG_LAST_u ,`CREG_u ,`VOID }; 
214: I = { `COPY ,`CREG_LAST_v ,`CREG_v ,`VOID }; 
215: I = { `COPY ,`CREG_E1_LAST ,`CREG_E1 ,`VOID }; 
216: I = { `COPY ,`CREG_E2_LAST ,`CREG_E2 ,`VOID }; 
217: I = { `COPY ,`CREG_UV0_LAST ,`CREG_UV0 ,`VOID }; 
218: I = { `COPY ,`CREG_UV1_LAST ,`CREG_UV1 ,`VOID }; 
219: I = { `COPY ,`CREG_UV2_LAST ,`CREG_UV2 ,`VOID }; 
220: I = { `COPY ,`CREG_TRI_DIFFUSE_LAST ,`CREG_TRI_DIFFUSE ,`VOID }; 
221: I = { `RET ,`R99 ,`TRUE  }; 
//LABEL_BIU4:
222: I = { `RET ,`R99 ,`FALSE  }; 


//-------------------------------------------------------------------------
//Calculate the adress of the texure coordiantes.

//TAG_TCC_UCODE_ADDRESS:
//Do this calculation only if this triangle is the one closest to the camera
223: I = { `JGX ,`LABEL_TCC_EXIT ,`CREG_t ,`CREG_LAST_t }; 

//First get the UV coodrinates and store in R1
//R1x: u_coordinate = U0 + last_u * (U1 - U0) + last_v * (U2 - U0)
//R1y: v_coordinate = V0 + last_u * (V1 - V0) + last_v * (V2 - V0)
//R1z: 0

224: I = { `SUB ,`R1 ,`CREG_UV1_LAST ,`CREG_UV0_LAST }; 
225: I = { `SUB ,`R2 ,`CREG_UV2_LAST ,`CREG_UV0_LAST }; 
226: I = { `MUL ,`R1 ,`CREG_LAST_u ,`R1 }; 
227: I = { `MUL ,`R2 ,`CREG_LAST_v ,`R2 }; 
228: I = { `ADD ,`R1 ,`R1 ,`R2 }; 
229: I = { `ADD ,`R1 ,`R1 ,`CREG_UV0_LAST }; 

//R7x : fu = (u_coordinate) * gTexture.mWidth
//R7y : fv = (v_coordinate) * gTexture.mWidth
//R7z : 0
230: I = { `MUL ,`R7 ,`R1 ,`CREG_TEXTURE_SIZE }; 

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

231: I = { `MOD ,`R1 ,`R7 ,`CREG_TEXTURE_SIZE }; 
232: I = { `INC ,`R2 ,`R1 ,`VOID }; 
233: I = { `MOD ,`R2 ,`R2 ,`CREG_TEXTURE_SIZE }; 

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
234: I = { `SWIZZLE3D ,`R2 ,`SWIZZLE_YXZ  }; 

//R3 = [v2 v1 0]
235: I = { `XCHANGEX ,`R3 ,`R1 ,`R2 }; 


//R4 = [u1 u2 0]
236: I = { `XCHANGEX ,`R4 ,`R2 ,`R1 }; 

//R2 = [v2*H v1*H 0]
237: I = { `UNSCALE ,`R9 ,`R3 ,`VOID }; 
238: I = { `UNSCALE ,`R8 ,`CREG_TEXTURE_SIZE ,`VOID }; 
239: I = { `IMUL ,`R2 ,`R9 ,`R8 }; 

//OREG_TEX_COORD1 = [u1 + v2*H u2 + v1*H 0]
//R4 = FixedToIinteger(R4)
240: I = { `UNSCALE ,`R4 ,`R4 ,`VOID }; 
241: I = { `ADD ,`R12 ,`R2 ,`R4 }; 
242: I = { `SETX ,`R5 ,32'h3  }; 
243: I = { `SETY ,`R5 ,32'h3  }; 
244: I = { `SETZ ,`R5 ,32'h3  }; 
//Multiply by 3 (the pitch)
//IMUL OREG_TEX_COORD1 R12 R5  
245: I = { `IMUL ,`CREG_TEX_COORD1 ,`R12 ,`R5 }; 

//R4 = [u2 u1 0]
246: I = { `SWIZZLE3D ,`R4 ,`SWIZZLE_YXZ  }; 


//OREG_TEX_COORD2 [u2 + v2*H u1 + v1*H 0]
247: I = { `ADD ,`R12 ,`R2 ,`R4 }; 
//Multiply by 3 (the pitch)
//IMUL OREG_TEX_COORD2 R12 R5  
248: I = { `IMUL ,`CREG_TEX_COORD2 ,`R12 ,`R5 }; 


//Cool now get the weights

//w1 = (1 - fracu) * (1 - fracv)
//w2 = fracu * (1 - fracv)
//w3 = (1 - fracu) * fracv
//w4 = fracu *  fracv

//R4x: fracu 
//R4y: fracv 
//R4z: 0
249: I = { `FRAC ,`R4 ,`R7 ,`VOID }; 

//R5x: fracv 
//R5y: fracu 
//R5z: 0 
250: I = { `COPY ,`R5 ,`R4 ,`VOID }; 
251: I = { `SWIZZLE3D ,`R5 ,`SWIZZLE_YXZ  }; 


//R5x: 1 - fracv 
//R5y: 1 - fracu 
//R5y: 1
252: I = { `NEG ,`R5 ,`R5 ,`VOID }; 
253: I = { `INC ,`R5 ,`R5 ,`VOID }; 

//R5x: 1 - fracv 
//R5y: 1 - fracu 
//R5y: (1 - fracv)(1 - fracu) 
254: I = { `MULP ,`CREG_TEXWEIGHT1 ,`R5 ,`VOID }; 

//CREG_TEXWEIGHT1.x = (1 - fracv)(1 - fracu) 
//CREG_TEXWEIGHT1.y = (1 - fracv)(1 - fracu) 
//CREG_TEXWEIGHT1.z = (1 - fracv)(1 - fracu) 
255: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT1 ,`SWIZZLE_ZZZ  }; 


//R6x: w2: fracu * (1 - fracv )
//R6y: w3: fracv * (1 - fracu )
//R6z: 0
256: I = { `MUL ,`R6 ,`R4 ,`R5 }; 

//CREG_TEXWEIGHT2.x = fracu * (1 - fracv )
//CREG_TEXWEIGHT2.y = fracu * (1 - fracv )
//CREG_TEXWEIGHT2.z = fracu * (1 - fracv )
257: I = { `COPY ,`CREG_TEXWEIGHT2 ,`R6 ,`VOID }; 
258: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT2 ,`SWIZZLE_XXX  }; 

//CREG_TEXWEIGHT3.x = fracv * (1 - fracu )
//CREG_TEXWEIGHT3.y = fracv * (1 - fracu )
//CREG_TEXWEIGHT3.z = fracv * (1 - fracu )
259: I = { `COPY ,`CREG_TEXWEIGHT3 ,`R6 ,`VOID }; 
260: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT3 ,`SWIZZLE_YYY  }; 


//R4x: fracu
//R4y: fracv
//R4z: fracu * fracv
261: I = { `MULP ,`R4 ,`R4 ,`VOID }; 

//CREG_TEXWEIGHT4.x = fracv * fracu 
//CREG_TEXWEIGHT4.y = fracv * fracu 
//CREG_TEXWEIGHT4.z = fracv * fracu 
262: I = { `COPY ,`CREG_TEXWEIGHT4 ,`R4 ,`VOID }; 
263: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT4 ,`SWIZZLE_ZZZ  }; 


//LABEL_TCC_EXIT:
264: I = { `RET ,`R99 ,32'h0  }; 


//-------------------------------------------------------------------------
//TAG_PSU_UCODE_ADRESS:
//Pixel Shader #1
//This pixel shader has diffuse light but no textures

	 
265: I = { `CROSS ,`R1 ,`CREG_E1_LAST ,`CREG_E2_LAST }; 
266: I = { `MAG ,`R2 ,`R1 ,`VOID }; 
267: I = { `DIV ,`R1 ,`R1 ,`R2 }; 
268: I = { `MUL ,`R2 ,`CREG_RAY_DIRECTION ,`CREG_LAST_t }; 
269: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
270: I = { `SUB ,`R2 ,`CURRENT_LIGHT_POS ,`R2 }; 
271: I = { `MAG ,`R3 ,`R2 ,`VOID }; 
272: I = { `DIV ,`R2 ,`R2 ,`R3 }; 
273: I = { `DOT ,`R3 ,`R2 ,`R1 }; 
274: I = { `MUL ,`CREG_COLOR_ACC ,`CREG_TRI_DIFFUSE_LAST ,`CURRENT_LIGHT_DIFFUSE }; 
275: I = { `MUL ,`CREG_COLOR_ACC ,`CREG_COLOR_ACC ,`R3 }; 
276: I = { `COPY ,`CREG_TEXTURE_COLOR ,`CREG_COLOR_ACC ,`VOID }; 
277: I = { `NOP ,`RT_FALSE   }; 
278: I = { `NOP ,`RT_FALSE   }; 
279: I = { `NOP ,`RT_FALSE   }; 
280: I = { `RET ,`R99 ,`TRUE  }; 

//-------------------------------------------------------------------------
//Pixel Shader #2
//TAG_PSU_UCODE_ADRESS2:
//This Pixel Shader has no light but it does texturinng 
//with bi-linear interpolation



281: I = { `COPY ,`R1 ,`CREG_TEX_COORD1 ,`VOID }; 
282: I = { `COPY ,`R2 ,`CREG_TEX_COORD1 ,`VOID }; 
283: I = { `COPY ,`R3 ,`CREG_TEX_COORD2 ,`VOID }; 
284: I = { `COPY ,`R4 ,`CREG_TEX_COORD2 ,`VOID }; 


285: I = { `SWIZZLE3D ,`R1 ,`SWIZZLE_XXX  }; 
286: I = { `SWIZZLE3D ,`R2 ,`SWIZZLE_YYY  }; 
287: I = { `SWIZZLE3D ,`R3 ,`SWIZZLE_XXX  }; 
288: I = { `SWIZZLE3D ,`R4 ,`SWIZZLE_YYY  }; 
289: I = { `ADD ,`R1 ,`R1 ,`CREG_012 }; 
290: I = { `ADD ,`R2 ,`R2 ,`CREG_012 }; 
291: I = { `ADD ,`R3 ,`R3 ,`CREG_012 }; 
292: I = { `ADD ,`R4 ,`R4 ,`CREG_012 }; 


293: I = { `TMREAD ,`CREG_TEX_COLOR1 ,`R1 ,`VOID }; 
294: I = { `NOP ,`RT_FALSE   }; 
295: I = { `TMREAD ,`CREG_TEX_COLOR2 ,`R2 ,`VOID }; 
296: I = { `NOP ,`RT_FALSE   }; 
297: I = { `TMREAD ,`CREG_TEX_COLOR3 ,`R3 ,`VOID }; 
298: I = { `NOP ,`RT_FALSE   }; 
299: I = { `TMREAD ,`CREG_TEX_COLOR4 ,`R4 ,`VOID }; 
300: I = { `NOP ,`RT_FALSE   }; 




//TextureColor.R = c1.R * w1 + c2.R * w2 + c3.R * w3 + c4.R * w4
//TextureColor.G = c1.G * w1 + c2.G * w2 + c3.G * w3 + c4.G * w4
//TextureColor.B = c1.B * w1 + c2.B * w2 + c3.B * w3 + c4.B * w4


//MUL R1 CREG_TEX_COLOR4 CREG_TEXWEIGHT1  
//MUL R2 CREG_TEX_COLOR2 CREG_TEXWEIGHT2  
//MUL R3 CREG_TEX_COLOR1 CREG_TEXWEIGHT3  
//MUL R4 CREG_TEX_COLOR3 CREG_TEXWEIGHT4  

301: I = { `MUL ,`R1 ,`CREG_TEX_COLOR3 ,`CREG_TEXWEIGHT1 }; 
302: I = { `MUL ,`R2 ,`CREG_TEX_COLOR2 ,`CREG_TEXWEIGHT2 }; 
303: I = { `MUL ,`R3 ,`CREG_TEX_COLOR1 ,`CREG_TEXWEIGHT3 }; 
304: I = { `MUL ,`R4 ,`CREG_TEX_COLOR4 ,`CREG_TEXWEIGHT4 }; 

305: I = { `ADD ,`CREG_TEXTURE_COLOR ,`R1 ,`R2 }; 
306: I = { `ADD ,`CREG_TEXTURE_COLOR ,`CREG_TEXTURE_COLOR ,`R3 }; 
307: I = { `ADD ,`CREG_TEXTURE_COLOR ,`CREG_TEXTURE_COLOR ,`R4 }; 
308: I = { `RET ,`R99 ,`TRUE  }; 


//-------------------------------------------------------------------------
//Default User constants
//TAG_USERCONSTANTS:

309: I = { `NOP ,`RT_FALSE   }; 
310: I = { `RETURN ,`RT_FALSE   }; 

//TAG_PIXELSHADER:
//Default Pixel Shader (just outputs texture)
311: I = { `OMWRITE ,`OREG_PIXEL_COLOR ,`CREG_CURRENT_OUTPUT_PIXEL ,`CREG_TEXTURE_COLOR }; 
312: I = { `NOP ,`RT_FALSE   }; 
313: I = { `RET ,`R99 ,`TRUE  }; 
314: I = { `NOP ,`RT_FALSE   }; 



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