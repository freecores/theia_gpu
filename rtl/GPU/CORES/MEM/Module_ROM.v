

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
`define TAG_PSU_UCODE_ADRESS2 16'd232
`define TAG_PSU_UCODE_ADRESS 16'd216
`define LABEL_TCC_EXIT 16'd215
`define TAG_TCC_UCODE_ADDRESS 16'd174
`define LABEL_BIU4 16'd173
`define LABEL_BIU3 16'd163
`define LABEL_BIU2 16'd160
`define LABEL_BIU1 16'd158
`define TAG_BIU_UCODE_ADDRESS 16'd141
`define LABEL_HIT 16'd139
`define LABEL15 16'd137
`define LABEL14 16'd135
`define LABEL13 16'd133
`define LABEL_TEST_XY_PLANE 16'd128
`define LABEL12 16'd126
`define LABEL11 16'd124
`define LABEL10 16'd122
`define LABEL_TEST_XZ_PLANE 16'd116
`define LABEL9 16'd114
`define LABEL8 16'd112
`define LABEL7 16'd110
`define LABEL_TEST_YZ_PLANE 16'd104
`define LABEL_RAY_INSIDE_BOX 16'd101
`define LABEL_ELSEZ 16'd100
`define LABEL6 16'd97
`define LABEL_ELESE_IFZ 16'd93
`define LABEL5 16'd90
`define LABEL_TEST_RAY_Z_ORIGEN 16'd86
`define LABEL_ELSEY 16'd85
`define LABEL4 16'd82
`define LABEL_ELESE_IFY 16'd78
`define LABEL3 16'd75
`define LABEL_TEST_RAY_Y_ORIGEN 16'd71
`define LABEL_ELSEX 16'd70
`define LABEL2 16'd67
`define LABEL_ELSE_IFX 16'd63
`define LABEL1 16'd60
`define LABEL_TEST_RAY_X_ORIGEN 16'd56
`define TAG_AABBIU_UCODE_ADDRESS 16'd53
`define LABEL_ALLDONE 16'd51
`define LABEL_NPG_NEXT_ROW 16'd47
`define TAG_NPG_UCODE_ADDRESS 16'd39
`define TAG_RGU_UCODE_ADDRESS 16'd32
`define TAG_CPPU_UCODE_ADDRESS 16'd29


//-------------------------------------------------------------------------
//Default values for some registers after reset
//-------------------------------------------------------------------------
//This is the first code that gets executed after the machine is
//externally configured, ie after the MST_I goes from 1 to zero.
//It sets initial values for some of the internal registers

0: I = { `ZERO ,`CREG_LAST_t ,`VOID ,`VOID }; 
//Set the last 't' to very positive value(500) 
1: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
2: I = { `ZERO ,`OREG_PIXEL_COLOR ,`VOID ,`VOID }; 
3: I = { `COPY ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_INITIAL_POSITION ,`VOID }; 


//Calculate the initial linear address for ADR_O
//this is: (X_initial + RESOLUTION_Y*Y_intial) * 3.
//Notice, that we need to use 'unscaled' ie. integer
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
//(X_initial + RESOLUTION_Y*Y_intial) * 3, voila!
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


22: I = { `ZERO ,`R1 ,`VOID ,`VOID }; 
23: I = { `ZERO ,`R2 ,`VOID ,`VOID }; 
24: I = { `ZERO ,`R3 ,`VOID ,`VOID }; 
25: I = { `ZERO ,`R4 ,`VOID ,`VOID }; 
26: I = { `ZERO ,`R5 ,`VOID ,`VOID }; 
27: I = { `NOP ,`RT_FALSE   }; 
28: I = { `RETURN ,`RT_TRUE   }; 



//----------------------------------------------------------------------	  
//Micro code for CPPU
//TAG_CPPU_UCODE_ADDRESS:


29: I = { `SUB ,`R1 ,`CREG_PROJECTION_WINDOW_MAX ,`CREG_PROJECTION_WINDOW_MIN }; 
30: I = { `DIV ,`CREG_PROJECTION_WINDOW_SCALE ,`R1 ,`CREG_RESOLUTION }; 
31: I = { `RETURN ,`RT_FALSE   }; 

//----------------------------------------------------------------------	  
//Micro code for RGU
//TAG_RGU_UCODE_ADDRESS:


32: I = { `MUL ,`R1 ,`CREG_PIXEL_2D_POSITION ,`CREG_PROJECTION_WINDOW_SCALE }; 
33: I = { `ADD ,`R1 ,`R1 ,`CREG_PROJECTION_WINDOW_MIN }; 
34: I = { `SUB ,`CREG_UNORMALIZED_DIRECTION ,`R1 ,`CREG_CAMERA_POSITION }; 
35: I = { `MAG ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`VOID }; 
36: I = { `DIV ,`CREG_RAY_DIRECTION ,`CREG_UNORMALIZED_DIRECTION ,`R2 }; 
37: I = { `DEC,`CREG_LAST_COL,`CREG_PIXEL_2D_FINAL_POSITION ,`VOID   }; 
//   NOP RT_FALSE   
38: I = { `RETURN ,`RT_FALSE   }; 
//----------------------------------------------------------------------
//Next Pixel generation Code (NPG)
//TAG_NPG_UCODE_ADDRESS:

   
39: I = { `SETX ,`R1 ,32'h00003  }; 
40: I = { `SETY ,`R1 ,32'h00003  }; 
41: I = { `SETZ ,`R1 ,32'h00003  }; 

42: I = { `ADD ,`CREG_PIXEL_PITCH ,`CREG_PIXEL_PITCH ,`R1 }; 
43: I = { `COPY ,`OREG_ADDR_O ,`CREG_PIXEL_PITCH ,`VOID }; 
44: I = { `JGEX ,`LABEL_NPG_NEXT_ROW ,`CREG_PIXEL_2D_POSITION ,`CREG_LAST_COL }; 
45: I = { `INCX ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION ,`VOID }; 
46: I = { `RETURN ,`RT_TRUE   }; 

//LABEL_NPG_NEXT_ROW:
47: I = { `SETX ,`CREG_PIXEL_2D_POSITION ,32'h0  }; 
48: I = { `INCY ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION ,`VOID }; 
49: I = { `JGEY ,`LABEL_ALLDONE ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_FINAL_POSITION }; 
50: I = { `RETURN ,`RT_TRUE   }; 

//LABEL_ALLDONE:
51: I = { `NOP ,`VOID ,`VOID  }; 
52: I = { `RETURN ,`RT_FALSE   }; 

//----------------------------------------------------------------------
//Micro code for AABBIU
//TAG_AABBIU_UCODE_ADDRESS:
	  
53: I = { `ZERO ,`R3 ,`VOID ,`VOID }; 
54: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
55: I = { `RETURN ,`RT_TRUE   }; 

//LABEL_TEST_RAY_X_ORIGEN:
56: I = { `JGEX ,`LABEL_ELSE_IFX ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
57: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
58: I = { `JLEX ,`LABEL1 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
59: I = { `RETURN ,`RT_FALSE   }; 

//LABEL1:
60: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
61: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
62: I = { `JMP ,`LABEL_TEST_RAY_Y_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELSE_IFX:
63: I = { `JLEX ,`LABEL_ELSEX ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
64: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
65: I = { `JGEX ,`LABEL2 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
66: I = { `RETURN ,`RT_FALSE   }; 
 
//LABEL2:
67: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
68: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
69: I = { `JMP ,`LABEL_TEST_RAY_Y_ORIGEN ,`VOID ,`VOID }; 
//LABEL_ELSEX:
70: I = { `SETX ,`R5 ,32'b1  }; 

//LABEL_TEST_RAY_Y_ORIGEN:
71: I = { `JGEY ,`LABEL_ELESE_IFY ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
72: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
73: I = { `JLEY ,`LABEL3 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
74: I = { `RETURN ,`RT_FALSE   }; 

//LABEL3:
75: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
76: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
77: I = { `JMP ,`LABEL_TEST_RAY_Z_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELESE_IFY:
78: I = { `JLEY ,`LABEL_ELSEY ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
79: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
80: I = { `JGEY ,`LABEL4 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
81: I = { `RETURN ,`RT_FALSE   }; 

//LABEL4:
82: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
83: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
84: I = { `JMP ,`LABEL_TEST_RAY_Z_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELSEY:
85: I = { `SETY ,`R5 ,32'b1  }; 

//LABEL_TEST_RAY_Z_ORIGEN:
86: I = { `JGEZ ,`LABEL_ELESE_IFZ ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
87: I = { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
88: I = { `JLEZ ,`LABEL5 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
89: I = { `RETURN ,`RT_FALSE   }; 

//LABEL5:
90: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
91: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
92: I = { `JMP ,`LABEL_RAY_INSIDE_BOX ,`VOID ,`VOID }; 

//LABEL_ELESE_IFZ:
93: I = { `JLEZ ,`LABEL_ELSEZ ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
94: I = { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
95: I = { `JGEZ ,`LABEL6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
96: I = { `RETURN ,`RT_FALSE   }; 

//LABEL6:
97: I = { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
98: I = { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
99: I = { `JMP ,`LABEL_RAY_INSIDE_BOX ,`VOID ,`VOID }; 

//LABEL_ELSEZ:
100: I = { `SETZ ,`R5 ,32'b1  }; 

//LABEL_RAY_INSIDE_BOX:
101: I = { `ZERO ,`R1 ,`VOID ,`VOID }; 
102: I = { `JEQX ,`LABEL_TEST_YZ_PLANE ,`R1 ,`RAY_INSIDE_BOX }; 
//BUG need a NOP here else pipeline gets confused
103: I = { `RETURN ,`RT_TRUE   }; 

//LABEL_TEST_YZ_PLANE:
104: I = { `JNEX ,`LABEL_TEST_XZ_PLANE ,`R5 ,`R1 }; 
105: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_XXX  }; 
106: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
107: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
108: I = { `JGEY ,`LABEL7 ,`R2 ,`CREG_AABBMIN }; 
109: I = { `RETURN ,`RT_FALSE   }; 

//LABEL7:
110: I = { `JLEY ,`LABEL8 ,`R2 ,`CREG_AABBMAX }; 
111: I = { `RETURN ,`RT_FALSE   }; 

//LABEL8:
112: I = { `JGEZ ,`LABEL9 ,`R2 ,`CREG_AABBMIN }; 
113: I = { `RETURN ,`RT_FALSE   }; 

//LABEL9:
114: I = { `JLEZ ,`LABEL_TEST_XZ_PLANE ,`R2 ,`CREG_AABBMAX }; 
115: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_TEST_XZ_PLANE:
116: I = { `JNEY ,`LABEL_TEST_XY_PLANE ,`R5 ,`R1 }; 
117: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_YYY  }; 
118: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
119: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
120: I = { `JGEX ,`LABEL10 ,`R2 ,`CREG_AABBMIN }; 
121: I = { `RETURN ,`RT_FALSE   }; 

//LABEL10:
122: I = { `JLEX ,`LABEL11 ,`R2 ,`CREG_AABBMAX }; 
123: I = { `RETURN ,`RT_FALSE   }; 

//LABEL11:
124: I = { `JGEZ ,`LABEL12 ,`R2 ,`CREG_AABBMIN }; 
125: I = { `RETURN ,`RT_FALSE   }; 

//LABEL12:
126: I = { `JLEZ ,`LABEL_TEST_XY_PLANE ,`R2 ,`CREG_AABBMAX }; 
127: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_TEST_XY_PLANE:
128: I = { `SWIZZLE3D ,`R6 ,`SWIZZLE_ZZZ  }; 
129: I = { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
130: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
131: I = { `JGEX ,`LABEL13 ,`R2 ,`CREG_AABBMIN }; 
132: I = { `RETURN ,`RT_FALSE   }; 

//LABEL13:
133: I = { `JLEX ,`LABEL14 ,`R2 ,`CREG_AABBMAX }; 
134: I = { `RETURN ,`RT_FALSE   }; 

//LABEL14:
135: I = { `JGEY ,`LABEL15 ,`R2 ,`CREG_AABBMIN }; 
136: I = { `RETURN ,`RT_FALSE   }; 

//LABEL15:
137: I = { `JLEY ,`LABEL_HIT ,`R2 ,`CREG_AABBMAX }; 
138: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_HIT:
139: I = { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
140: I = { `RETURN ,`RT_TRUE   }; 

 //------------------------------------------------------------------------
 //BIU Micro code
//TAG_BIU_UCODE_ADDRESS:
			  
141: I = { `ZERO ,`OREG_PIXEL_COLOR ,`VOID ,`VOID }; 
142: I = { `SETX ,`R3 ,`ONE  }; 
143: I = { `SETX ,`R1 ,32'h00000  }; 
144: I = { `SUB ,`CREG_E1 ,`CREG_V1 ,`CREG_V0 }; 
145: I = { `SUB ,`CREG_E2 ,`CREG_V2 ,`CREG_V0 }; 
146: I = { `SUB ,`CREG_T ,`CREG_CAMERA_POSITION ,`CREG_V0 }; 
147: I = { `CROSS ,`CREG_P ,`CREG_RAY_DIRECTION ,`CREG_E2 }; 
148: I = { `CROSS ,`CREG_Q ,`CREG_T ,`CREG_E1 }; 
149: I = { `DOT ,`CREG_H1 ,`CREG_Q ,`CREG_E2 }; 
150: I = { `DOT ,`CREG_H2 ,`CREG_P ,`CREG_T }; 
151: I = { `DOT ,`CREG_H3 ,`CREG_Q ,`CREG_RAY_DIRECTION }; 
152: I = { `DOT ,`CREG_DELTA ,`CREG_P ,`CREG_E1 }; 
153: I = { `DIV ,`CREG_t ,`CREG_H1 ,`CREG_DELTA }; 
154: I = { `DIV ,`CREG_u ,`CREG_H2 ,`CREG_DELTA }; 
155: I = { `DIV ,`CREG_v ,`CREG_H3 ,`CREG_DELTA }; 
156: I = { `JGEX ,`LABEL_BIU1 ,`CREG_u ,`R1 }; 
157: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_BIU1:
158: I = { `JGEX ,`LABEL_BIU2 ,`CREG_v ,`R1 }; 
159: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_BIU2:
160: I = { `ADD ,`R2 ,`CREG_u ,`CREG_v }; 
161: I = { `JLEX ,`LABEL_BIU3 ,`R2 ,`R3 }; 
162: I = { `RETURN ,`RT_FALSE   }; 

//LABEL_BIU3:
163: I = { `JGEX ,`LABEL_BIU4 ,`CREG_t ,`CREG_LAST_t }; 
164: I = { `COPY ,`CREG_LAST_t ,`CREG_t ,`VOID }; 
165: I = { `COPY ,`CREG_LAST_u ,`CREG_u ,`VOID }; 
166: I = { `COPY ,`CREG_LAST_v ,`CREG_v ,`VOID }; 
167: I = { `COPY ,`CREG_E1_LAST ,`CREG_E1 ,`VOID }; 
168: I = { `COPY ,`CREG_E2_LAST ,`CREG_E2 ,`VOID }; 
169: I = { `COPY ,`CREG_UV0_LAST ,`CREG_UV0 ,`VOID }; 
170: I = { `COPY ,`CREG_UV1_LAST ,`CREG_UV1 ,`VOID }; 
171: I = { `COPY ,`CREG_UV2_LAST ,`CREG_UV2 ,`VOID }; 
172: I = { `COPY ,`CREG_TRI_DIFFUSE_LAST ,`CREG_TRI_DIFFUSE ,`VOID }; 
//LABEL_BIU4:
173: I = { `RETURN ,`RT_TRUE   }; 


//-------------------------------------------------------------------------
//Calculate the adress of the texure coordiantes.

//TAG_TCC_UCODE_ADDRESS:
//Do this calculation only if this triangle is the one closest to the camera
174: I = { `JGX ,`LABEL_TCC_EXIT ,`CREG_t ,`CREG_LAST_t }; 

//First get the UV coodrinates and store in R1
//R1x: u_coordinate = U0 + last_u * (U1 - U0) + last_v * (U2 - U0)
//R1y: v_coordinate = V0 + last_u * (V1 - V0) + last_v * (V2 - V0)
//R1z: 0

175: I = { `SUB ,`R1 ,`CREG_UV1_LAST ,`CREG_UV0_LAST }; 
176: I = { `SUB ,`R2 ,`CREG_UV2_LAST ,`CREG_UV0_LAST }; 
177: I = { `MUL ,`R1 ,`CREG_LAST_u ,`R1 }; 
178: I = { `MUL ,`R2 ,`CREG_LAST_v ,`R2 }; 
179: I = { `ADD ,`R1 ,`R1 ,`R2 }; 
180: I = { `ADD ,`R1 ,`R1 ,`CREG_UV0_LAST }; 

//R7x : fu = (u_coordinate) * gTexture.mWidth
//R7y : fv = (v_coordinate) * gTexture.mWidth
//R7z : 0
181: I = { `MUL ,`R7 ,`R1 ,`CREG_TEXTURE_SIZE }; 

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

182: I = { `MOD ,`R1 ,`R7 ,`CREG_TEXTURE_SIZE }; 
183: I = { `INC ,`R2 ,`R1 ,`VOID }; 
184: I = { `MOD ,`R2 ,`R2 ,`CREG_TEXTURE_SIZE }; 

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
185: I = { `SWIZZLE3D ,`R2 ,`SWIZZLE_YXZ  }; 

//R3 = [v2 v1 0]
186: I = { `XCHANGEX ,`R3 ,`R1 ,`R2 }; 


//R4 = [u1 u2 0]
187: I = { `XCHANGEX ,`R4 ,`R2 ,`R1 }; 

//R2 = [v2*H v1*H 0]
188: I = { `UNSCALE ,`R9 ,`R3 ,`VOID }; 
189: I = { `UNSCALE ,`R8 ,`CREG_TEXTURE_SIZE ,`VOID }; 
190: I = { `IMUL ,`R2 ,`R9 ,`R8 }; 

//OREG_TEX_COORD1 = [u1 + v2*H u2 + v1*H 0]
//R4 = FixedToIinteger(R4)
191: I = { `UNSCALE ,`R4 ,`R4 ,`VOID }; 
192: I = { `ADD ,`R12 ,`R2 ,`R4 }; 
193: I = { `SETX ,`R5 ,32'h3  }; 
194: I = { `SETY ,`R5 ,32'h3  }; 
195: I = { `SETZ ,`R5 ,32'h3  }; 
//Multiply by 3 (the pitch)
196: I = { `IMUL ,`OREG_TEX_COORD1 ,`R12 ,`R5 }; 

//R4 = [u2 u1 0]
197: I = { `SWIZZLE3D ,`R4 ,`SWIZZLE_YXZ  }; 


//OREG_TEX_COORD2 [u2 + v2*H u1 + v1*H 0]
198: I = { `ADD ,`R12 ,`R2 ,`R4 }; 
//Multiply by 3 (the pitch)
199: I = { `IMUL ,`OREG_TEX_COORD2 ,`R12 ,`R5 }; 


//Cool now get the weights

//w1 = (1 - fracu) * (1 - fracv)
//w2 = fracu * (1 - fracv)
//w3 = (1 - fracu) * fracv
//w4 = fracu *  fracv

//R4x: fracu 
//R4y: fracv 
//R4z: 0
200: I = { `FRAC ,`R4 ,`R7 ,`VOID }; 

//R5x: fracv 
//R5y: fracu 
//R5z: 0 
201: I = { `COPY ,`R5 ,`R4 ,`VOID }; 
202: I = { `SWIZZLE3D ,`R5 ,`SWIZZLE_YXZ  }; 


//R5x: 1 - fracv 
//R5y: 1 - fracu 
//R5y: 1
203: I = { `NEG ,`R5 ,`R5 ,`VOID }; 
204: I = { `INC ,`R5 ,`R5 ,`VOID }; 

//R5x: 1 - fracv 
//R5y: 1 - fracu 
//R5y: (1 - fracv)(1 - fracu) 
205: I = { `MULP ,`CREG_TEXWEIGHT1 ,`R5 ,`VOID }; 

//CREG_TEXWEIGHT1.x = (1 - fracv)(1 - fracu) 
//CREG_TEXWEIGHT1.y = (1 - fracv)(1 - fracu) 
//CREG_TEXWEIGHT1.z = (1 - fracv)(1 - fracu) 
206: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT1 ,`SWIZZLE_ZZZ  }; 


//R6x: w2: fracu * (1 - fracv )
//R6y: w3: fracv * (1 - fracu )
//R6z: 0
207: I = { `MUL ,`R6 ,`R4 ,`R5 }; 

//CREG_TEXWEIGHT2.x = fracu * (1 - fracv )
//CREG_TEXWEIGHT2.y = fracu * (1 - fracv )
//CREG_TEXWEIGHT2.z = fracu * (1 - fracv )
208: I = { `COPY ,`CREG_TEXWEIGHT2 ,`R6 ,`VOID }; 
209: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT2 ,`SWIZZLE_XXX  }; 

//CREG_TEXWEIGHT3.x = fracv * (1 - fracu )
//CREG_TEXWEIGHT3.y = fracv * (1 - fracu )
//CREG_TEXWEIGHT3.z = fracv * (1 - fracu )
210: I = { `COPY ,`CREG_TEXWEIGHT3 ,`R6 ,`VOID }; 
211: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT3 ,`SWIZZLE_YYY  }; 


//R4x: fracu
//R4y: fracv
//R4z: fracu * fracv
212: I = { `MULP ,`R4 ,`R4 ,`VOID }; 

//CREG_TEXWEIGHT4.x = fracv * fracu 
//CREG_TEXWEIGHT4.y = fracv * fracu 
//CREG_TEXWEIGHT4.z = fracv * fracu 
213: I = { `COPY ,`CREG_TEXWEIGHT4 ,`R4 ,`VOID }; 
214: I = { `SWIZZLE3D ,`CREG_TEXWEIGHT4 ,`SWIZZLE_ZZZ  }; 


//LABEL_TCC_EXIT:
215: I = { `RETURN ,`RT_TRUE   }; 


//-------------------------------------------------------------------------
//TAG_PSU_UCODE_ADRESS:
//Pixel Shader #1
//This pixel shader has diffuse light but no textures

	 
216: I = { `CROSS ,`R1 ,`CREG_E1_LAST ,`CREG_E2_LAST }; 
217: I = { `MAG ,`R2 ,`R1 ,`VOID }; 
218: I = { `DIV ,`R1 ,`R1 ,`R2 }; 
219: I = { `MUL ,`R2 ,`CREG_RAY_DIRECTION ,`CREG_LAST_t }; 
220: I = { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
221: I = { `SUB ,`R2 ,`CURRENT_LIGHT_POS ,`R2 }; 
222: I = { `MAG ,`R3 ,`R2 ,`VOID }; 
223: I = { `DIV ,`R2 ,`R2 ,`R3 }; 
224: I = { `DOT ,`R3 ,`R2 ,`R1 }; 
225: I = { `MUL ,`CREG_COLOR_ACC ,`CREG_TRI_DIFFUSE_LAST ,`CURRENT_LIGHT_DIFFUSE }; 
226: I = { `MUL ,`CREG_COLOR_ACC ,`CREG_COLOR_ACC ,`R3 }; 
227: I = { `COPY ,`CREG_TEXTURE_COLOR ,`CREG_COLOR_ACC ,`VOID }; 
228: I = { `NOP ,`RT_FALSE   }; //I = { `JLEX ,`LABEL_DEBUG_PRINT_REGS ,`CREG_COLOR_ACC ,`R3 }; 
229: I = { `NOP ,`RT_FALSE   }; //I = { `JMP ,`LABEL_DEBUG_PRINT_REGS ,`VOID ,`VOID }; 
230: I = { `NOP ,`RT_FALSE   }; 
231: I = { `RETURN ,`RT_TRUE   }; 

//-------------------------------------------------------------------------
//Pixel Shader #2
//TAG_PSU_UCODE_ADRESS2:


//This Pixel Shader has no light but it does texturinng 
//with bi-linear interpolation

//CColor TextureColor
//TextureColor.R = c1.R * w1 + c2.R * w2 + c3.R * w3 + c4.R * w4
//TextureColor.G = c1.G * w1 + c2.G * w2 + c3.G * w3 + c4.G * w4
//TextureColor.B = c1.B * w1 + c2.B * w2 + c3.B * w3 + c4.B * w4

232: I = { `MUL ,`R1 ,`CREG_TEX_COLOR5 ,`CREG_TEXWEIGHT1 }; 
233: I = { `MUL ,`R2 ,`CREG_TEX_COLOR2 ,`CREG_TEXWEIGHT2 }; 
234: I = { `MUL ,`R3 ,`CREG_TEX_COLOR1 ,`CREG_TEXWEIGHT3 }; 
235: I = { `MUL ,`R4 ,`CREG_TEX_COLOR4 ,`CREG_TEXWEIGHT4 }; 
236: I = { `ADD ,`CREG_TEXTURE_COLOR ,`R1 ,`R2 }; 
237: I = { `ADD ,`CREG_TEXTURE_COLOR ,`CREG_TEXTURE_COLOR ,`R3 }; 
238: I = { `ADD ,`CREG_TEXTURE_COLOR ,`CREG_TEXTURE_COLOR ,`R4 }; 
239: I = { `RETURN ,`RT_TRUE   }; 


240: I = { `RETURN ,`RT_TRUE   }; 

//-------------------------------------------------------------------------
//Default User constants
//TAG_USERCONSTANTS:

241: I = { `NOP ,`RT_FALSE   }; 
242: I = { `RETURN ,`RT_TRUE   }; 

//TAG_PIXELSHADER:
//Default Pixel Shader (just outputs texture)
243: I = { `COPY ,`OREG_PIXEL_COLOR,`CREG_TEXTURE_COLOR,`VOID   }; 
244: I = { `RETURN ,`RT_TRUE   }; 

//-------------------------------------------------------------------------		
		

			default: 
			begin
			
			`ifdef DEBUG
			$display("Error: Reached undefined address in instruction Memory: %d!!!!",Address);
		//	$stop();
			`endif
			I =  {`INSTRUCTION_OP_LENGTH'hFF,16'hFFFF,32'hFFFFFFFF};
			end
			endcase
	end
endmodule
//--------------------------------------------------------