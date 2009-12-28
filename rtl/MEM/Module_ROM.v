

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
`define LABEL_DEBUG_PRINT_REGS 16'd221
`define TAG_DEBUG_LOG_REGISTERS 16'd221
`define TAG_PSU_UCODE_ADRESS2 16'd212
`define TAG_PSU_UCODE_ADRESS 16'd196
`define LABEL_TCC_EXIT 16'd195
`define TAG_TCC_UCODE_ADDRESS 16'd154
`define LABEL_BIU4 16'd153
`define LABEL_BIU3 16'd143
`define LABEL_BIU2 16'd140
`define LABEL_BIU1 16'd138
`define TAG_BIU_UCODE_ADDRESS 16'd121
`define LABEL_HIT 16'd119
`define LABEL15 16'd117
`define LABEL14 16'd115
`define LABEL13 16'd113
`define LABEL_TEST_XY_PLANE 16'd108
`define LABEL12 16'd106
`define LABEL11 16'd104
`define LABEL10 16'd102
`define LABEL_TEST_XZ_PLANE 16'd96
`define LABEL9 16'd94
`define LABEL8 16'd92
`define LABEL7 16'd90
`define LABEL_TEST_YZ_PLANE 16'd84
`define LABEL_RAY_INSIDE_BOX 16'd81
`define LABEL_ELSEZ 16'd80
`define LABEL6 16'd77
`define LABEL_ELESE_IFZ 16'd73
`define LABEL5 16'd70
`define LABEL_TEST_RAY_Z_ORIGEN 16'd66
`define LABEL_ELSEY 16'd65
`define LABEL4 16'd62
`define LABEL_ELESE_IFY 16'd58
`define LABEL3 16'd55
`define LABEL_TEST_RAY_Y_ORIGEN 16'd51
`define LABEL_ELSEX 16'd50
`define LABEL2 16'd47
`define LABEL_ELSE_IFX 16'd43
`define LABEL1 16'd40
`define LABEL_TEST_RAY_X_ORIGEN 16'd36
`define TAG_AABBIU_UCODE_ADDRESS 16'd33
`define LABEL_NPG_NEXT_ROW 16'd30
`define TAG_NPG_UCODE_ADDRESS 16'd24
`define TAG_RGU_UCODE_ADDRESS 16'd17
`define TAG_CPPU_UCODE_ADDRESS 16'd14
//This is the Code that loads in THEIAs ROM

//-------------------------------------------------------------------------
//Default values for some registers after reset



 0: I =  { `ZERO ,`CREG_LAST_t ,`VOID ,`VOID }; 
 //Set the last 't' to very positive value(500) 
 1: I =  { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
2: I =  { `ZERO ,`OREG_PIXEL_COLOR ,`VOID ,`VOID }; 
3: I =  { `NOP ,`RT_FALSE   }; //{ `ZERO ,`CREG_PIXEL_2D_POSITION ,`VOID ,`VOID }; 
4: I =  { `ZERO ,`OREG_PIXEL_PITCH ,`VOID,`VOID}; 
5: I =  { `ZERO ,`R1 ,`VOID ,`VOID }; 
6: I =  { `ZERO ,`R2 ,`VOID ,`VOID }; 
7: I =  { `ZERO ,`R3 ,`VOID ,`VOID }; 
8: I =  { `ZERO ,`R4 ,`VOID ,`VOID }; 
9: I =  { `ZERO ,`R5 ,`VOID ,`VOID }; 
 //Harode texture size for now ...
10: I =  { `NOP ,`RT_FALSE   };//{ `SETX ,`CREG_TEXTURE_SIZE ,32'h1FE0000  }; 
11: I =  { `NOP ,`RT_FALSE   };//{ `SETY ,`CREG_TEXTURE_SIZE ,32'h1FE0000  }; 
12: I =  { `NOP ,`RT_FALSE   };//{ `SETZ ,`CREG_TEXTURE_SIZE ,32'h1FE0000  }; 
13: I =  { `RETURN ,`RT_TRUE   }; 


//----------------------------------------------------------------------	  
//Micro code for CPPU
//TAG_CPPU_UCODE_ADDRESS:


14: I =  { `SUB ,`R1 ,`CREG_PROJECTION_WINDOW_MAX ,`CREG_PROJECTION_WINDOW_MIN }; 
15: I =  { `DIV ,`CREG_PROJECTION_WINDOW_SCALE ,`R1 ,`CREG_RESOLUTION }; 
16: I =  { `RETURN ,`RT_FALSE   }; 

//----------------------------------------------------------------------	  
//Micro code for RGU
//TAG_RGU_UCODE_ADDRESS:


17: I =  { `MUL ,`R1 ,`CREG_PIXEL_2D_POSITION ,`CREG_PROJECTION_WINDOW_SCALE }; 
18: I =  { `ADD ,`R1 ,`R1 ,`CREG_PROJECTION_WINDOW_MIN }; 
19: I =  { `SUB ,`CREG_UNORMALIZED_DIRECTION ,`R1 ,`CREG_CAMERA_POSITION }; 
20: I =  { `MAG ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`VOID }; 
21: I =  { `DIV ,`CREG_RAY_DIRECTION ,`CREG_UNORMALIZED_DIRECTION ,`R2 }; 
22: I =  { `DEC,`CREG_LAST_COL,`CREG_RESOLUTION,`VOID};//{ `ZERO ,`R3 ,`VOID ,`VOID }; 
23: I =  { `RETURN ,`RT_FALSE   }; 
//----------------------------------------------------------------------
//Next Pixel generation Code (NPG)
//TAG_NPG_UCODE_ADDRESS:

24: I =  { `ZERO ,`R1 ,`VOID ,`VOID }; 
25: I =  { `SETX ,`R1 ,32'h00003  }; 
26: I =  { `ADD ,`OREG_PIXEL_PITCH ,`OREG_PIXEL_PITCH ,`R1 }; 

27: I =  { `JEQX ,`LABEL_NPG_NEXT_ROW ,`CREG_PIXEL_2D_POSITION ,`CREG_LAST_COL }; //HERE WE ARE CALCULATING ELEMENT 200 :(
28: I =  { `INCX ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION ,`VOID }; 
29: I =  { `RETURN ,`RT_TRUE   }; 
//LABEL_NPG_NEXT_ROW:
30: I =  { `SETX ,`CREG_PIXEL_2D_POSITION ,32'h0  }; 
31: I =  { `INCY ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION,`VOID  }; 
32: I =  { `RETURN ,`RT_TRUE   }; 

//----------------------------------------------------------------------
//Micro code for AABBIU
//TAG_AABBIU_UCODE_ADDRESS:
	  
33: I =  { `ZERO ,`R3 ,`VOID ,`VOID }; 
34: I =  { `ZERO ,`R5 ,`VOID ,`VOID }; 
35: I =  { `NOP ,`RT_FALSE   }; 

//LABEL_TEST_RAY_X_ORIGEN:
36: I =  { `JGEX ,`LABEL_ELSE_IFX ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
37: I =  { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
38: I =  { `JLEX ,`LABEL1 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
39: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL1:
40: I =  { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
41: I =  { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
42: I =  { `JMP ,`LABEL_TEST_RAY_Y_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELSE_IFX:
43: I =  { `JLEX ,`LABEL_ELSEX ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
44: I =  { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
45: I =  { `JGEX ,`LABEL2 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
46: I =  { `RETURN ,`RT_FALSE   }; 
 
//LABEL2:
47: I =  { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
48: I =  { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
49: I =  { `JMP ,`LABEL_TEST_RAY_Y_ORIGEN ,`VOID ,`VOID }; 
//LABEL_ELSEX:
50: I =  { `SETX ,`R5 ,32'b1  }; 

//LABEL_TEST_RAY_Y_ORIGEN:
51: I =  { `JGEY ,`LABEL_ELESE_IFY ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
52: I =  { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
53: I =  { `JLEY ,`LABEL3 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
54: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL3:
55: I =  { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
56: I =  { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
57: I =  { `JMP ,`LABEL_TEST_RAY_Z_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELESE_IFY:
58: I =  { `JLEY ,`LABEL_ELSEY ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
59: I =  { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
60: I =  { `JGEY ,`LABEL4 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
61: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL4:
62: I =  { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
63: I =  { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
64: I =  { `JMP ,`LABEL_TEST_RAY_Z_ORIGEN ,`VOID ,`VOID }; 

//LABEL_ELSEY:
65: I =  { `SETY ,`R5 ,32'b1  }; 

//LABEL_TEST_RAY_Z_ORIGEN:
66: I =  { `JGEZ ,`LABEL_ELESE_IFZ ,`CREG_CAMERA_POSITION ,`CREG_AABBMIN }; 
67: I =  { `SUB ,`R1 ,`CREG_AABBMIN ,`CREG_CAMERA_POSITION }; 
68: I =  { `JLEZ ,`LABEL5 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
69: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL5:
70: I =  { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
71: I =  { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
72: I =  { `JMP ,`LABEL_RAY_INSIDE_BOX ,`VOID ,`VOID }; 

//LABEL_ELESE_IFZ:
73: I =  { `JLEZ ,`LABEL_ELSEZ ,`CREG_CAMERA_POSITION ,`CREG_AABBMAX }; 
74: I =  { `SUB ,`R1 ,`CREG_AABBMAX ,`CREG_CAMERA_POSITION }; 
75: I =  { `JGEZ ,`LABEL6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
76: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL6:
77: I =  { `SETX ,`RAY_INSIDE_BOX ,32'd0  }; 
78: I =  { `DIV ,`R6 ,`R1 ,`CREG_UNORMALIZED_DIRECTION }; 
79: I =  { `JMP ,`LABEL_RAY_INSIDE_BOX ,`VOID ,`VOID }; 

//LABEL_ELSEZ:
80: I =  { `SETZ ,`R5 ,32'b1  }; 

//LABEL_RAY_INSIDE_BOX:
81: I =  { `ZERO ,`R1 ,`VOID ,`VOID }; 
82: I =  { `JEQX ,`LABEL_TEST_YZ_PLANE ,`R1 ,`RAY_INSIDE_BOX }; 
83: I =  { `RETURN ,`RT_TRUE   }; 

//LABEL_TEST_YZ_PLANE:
84: I =  { `JNEX ,`LABEL_TEST_XZ_PLANE ,`R5 ,`R1 }; 
85: I =  { `SWIZZLE3D ,`R6 ,`SWIZZLE_XXX  }; 
86: I =  { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
87: I =  { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
88: I =  { `JGEY ,`LABEL7 ,`R2 ,`CREG_AABBMIN }; 
89: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL7:
90: I =  { `JLEY ,`LABEL8 ,`R2 ,`CREG_AABBMAX }; 
91: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL8:
92: I =  { `JGEZ ,`LABEL9 ,`R2 ,`CREG_AABBMIN }; 
93: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL9:
94: I =  { `JLEZ ,`LABEL_TEST_XZ_PLANE ,`R2 ,`CREG_AABBMAX }; 
95: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL_TEST_XZ_PLANE:
96: I =  { `JNEY ,`LABEL_TEST_XY_PLANE ,`R5 ,`R1 }; 
97: I =  { `SWIZZLE3D ,`R6 ,`SWIZZLE_YYY  }; 
98: I =  { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
99: I =  { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
100: I =  { `JGEX ,`LABEL10 ,`R2 ,`CREG_AABBMIN }; 
101: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL10:
102: I =  { `JLEX ,`LABEL11 ,`R2 ,`CREG_AABBMAX }; 
103: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL11:
104: I =  { `JGEZ ,`LABEL12 ,`R2 ,`CREG_AABBMIN }; 
105: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL12:
106: I =  { `JLEZ ,`LABEL_TEST_XY_PLANE ,`R2 ,`CREG_AABBMAX }; 
107: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL_TEST_XY_PLANE:
108: I =  { `SWIZZLE3D ,`R6 ,`SWIZZLE_ZZZ  }; 
109: I =  { `MUL ,`R2 ,`CREG_UNORMALIZED_DIRECTION ,`R6 }; 
110: I =  { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
111: I =  { `JGEX ,`LABEL13 ,`R2 ,`CREG_AABBMIN }; 
112: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL13:
113: I =  { `JLEX ,`LABEL14 ,`R2 ,`CREG_AABBMAX }; 
114: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL14:
115: I =  { `JGEY ,`LABEL15 ,`R2 ,`CREG_AABBMIN }; 
116: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL15:
117: I =  { `JLEY ,`LABEL_HIT ,`R2 ,`CREG_AABBMAX }; 
118: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL_HIT:
119: I =  { `SETX ,`CREG_LAST_t ,32'h1F40000  }; 
120: I =  { `RETURN ,`RT_TRUE   }; 

 //------------------------------------------------------------------------
 //BIU Micro code
//TAG_BIU_UCODE_ADDRESS:
			  
121: I =  { `ZERO ,`OREG_PIXEL_COLOR ,`VOID ,`VOID }; 
122: I =  { `SETX ,`R3 ,`ONE  }; 
123: I =  { `SETX ,`R1 ,32'h00000  }; 
124: I =  { `SUB ,`CREG_E1 ,`CREG_V1 ,`CREG_V0 }; 
125: I =  { `SUB ,`CREG_E2 ,`CREG_V2 ,`CREG_V0 }; 
126: I =  { `SUB ,`CREG_T ,`CREG_CAMERA_POSITION ,`CREG_V0 }; 
127: I =  { `CROSS ,`CREG_P ,`CREG_RAY_DIRECTION ,`CREG_E2 }; 
128: I =  { `CROSS ,`CREG_Q ,`CREG_T ,`CREG_E1 }; 
129: I =  { `DOT ,`CREG_H1 ,`CREG_Q ,`CREG_E2 }; 
130: I =  { `DOT ,`CREG_H2 ,`CREG_P ,`CREG_T }; 
131: I =  { `DOT ,`CREG_H3 ,`CREG_Q ,`CREG_RAY_DIRECTION }; 
132: I =  { `DOT ,`CREG_DELTA ,`CREG_P ,`CREG_E1 }; 
133: I =  { `DIV ,`CREG_t ,`CREG_H1 ,`CREG_DELTA }; 
134: I =  { `DIV ,`CREG_u ,`CREG_H2 ,`CREG_DELTA }; 
135: I =  { `DIV ,`CREG_v ,`CREG_H3 ,`CREG_DELTA }; 
136: I =  { `JGEX ,`LABEL_BIU1 ,`CREG_u ,`R1 }; 
137: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL_BIU1:
138: I =  { `JGEX ,`LABEL_BIU2 ,`CREG_v ,`R1 }; 
139: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL_BIU2:
140: I =  { `ADD ,`R2 ,`CREG_u ,`CREG_v }; 
141: I =  { `JLEX ,`LABEL_BIU3 ,`R2 ,`R3 }; 
142: I =  { `RETURN ,`RT_FALSE   }; 

//LABEL_BIU3:
143: I =  { `JGEX ,`LABEL_BIU4 ,`CREG_t ,`CREG_LAST_t }; 
144: I =  { `COPY ,`CREG_LAST_t ,`CREG_t ,`VOID }; 
145: I =  { `COPY ,`CREG_LAST_u ,`CREG_u ,`VOID }; 
146: I =  { `COPY ,`CREG_LAST_v ,`CREG_v ,`VOID }; 
147: I =  { `COPY ,`CREG_E1_LAST ,`CREG_E1 ,`VOID }; 
148: I =  { `COPY ,`CREG_E2_LAST ,`CREG_E2 ,`VOID }; 
149: I =  { `COPY ,`CREG_UV0_LAST ,`CREG_UV0 ,`VOID }; 
150: I =  { `COPY ,`CREG_UV1_LAST ,`CREG_UV1 ,`VOID }; 
151: I =  { `COPY ,`CREG_UV2_LAST ,`CREG_UV2 ,`VOID }; 
152: I =  { `COPY ,`CREG_TRI_DIFFUSE_LAST ,`CREG_TRI_DIFFUSE ,`VOID }; 
//LABEL_BIU4:
153: I =  { `RETURN ,`RT_TRUE   }; 


//-------------------------------------------------------------------------
//Calculate the adress of the texure coordiantes.

//TAG_TCC_UCODE_ADDRESS:
//Do this calculation only if this triangle is the one closest to the camera
154: I =  { `JGX ,`LABEL_TCC_EXIT ,`CREG_t ,`CREG_LAST_t }; 

//First get the UV coodrinates and store in R1
//R1x: u_coordinate = U0 + last_u * (U1 - U0) + last_v * (U2 - U0);
//R1y: v_coordinate = V0 + last_u * (V1 - V0) + last_v * (V2 - V0);
//R1z: 0

155: I =  { `SUB ,`R1 ,`CREG_UV1_LAST ,`CREG_UV0_LAST }; 
156: I =  { `SUB ,`R2 ,`CREG_UV2_LAST ,`CREG_UV0_LAST }; 
157: I =  { `MUL ,`R1 ,`CREG_LAST_u ,`R1 }; 
158: I =  { `MUL ,`R2 ,`CREG_LAST_v ,`R2 }; 
159: I =  { `ADD ,`R1 ,`R1 ,`R2 }; 
160: I =  { `ADD ,`R1 ,`R1 ,`CREG_UV0 }; 

//R7x : fu = (u_coordinate) * gTexture.mWidth;
//R7y : fv = (v_coordinate) * gTexture.mWidth;
//R7z : 0
161: I =  { `MUL ,`R7 ,`R1 ,`CREG_TEXTURE_SIZE }; 

//R1x: u1 = ((int)fu) % gTexture.mWidth;
//R1y: v1 = ((int)fv) % gTexture.mHeight;
//R1z: 0
//R2x: u2 = (u1 + 1 ) % gTexture.mWidth;
//R2y: v2 = (v2 + 1 ) % gTexture.mHeight;
//R2z: 0
// Notice MOD2 only operates over
// numbers that are power of 2, also notice that the
// textures are assumed to be squares!
//x % 2^n == x & (2^n - 1).

162: I =  { `MOD ,`R1 ,`R7 ,`CREG_TEXTURE_SIZE }; 
163: I =  { `INC ,`R2 ,`R1 ,`VOID }; 
164: I =  { `MOD ,`R2 ,`R2 ,`CREG_TEXTURE_SIZE }; 

//Cool, now we should store the values in the appropiate registers
//OREG_TEX_COORD1.x = u1 + v1 * gTexture.mWidth
//OREG_TEX_COORD1.y = u2 + v1 * gTexture.mWidth
//OREG_TEX_COORD1.z = 0
//OREG_TEX_COORD2.x = u1 + v2 * gTexture.mWidth
//OREG_TEX_COORD2.y = u2 + v2 * gTexture.mWidth
//OREG_TEX_COORD1.z = 0

//R1= [u1, v1, 0]
//R2= [u2, v2, 0]

//R2 = [v2, u2, 0]
165: I =  { `SWIZZLE3D ,`R2 ,`SWIZZLE_YXZ  }; 

//R3 = [v2 v1 0]
166: I =  { `XCHANGEX ,`R3 ,`R1 ,`R2 }; 


//R4 = [u1, u2 0]
167: I =  { `XCHANGEX ,`R4 ,`R2 ,`R1 }; 

//R2 = [v2*H, v1*H, 0]
//R2 = FixedToInteger(R3*CREG_TEXTURE_SIZE)
168: I =  { `UNSCALE ,`R9 ,`R3 ,`VOID }; 
169: I =  { `UNSCALE ,`R8 ,`CREG_TEXTURE_SIZE ,`VOID }; 
170: I =  { `IMUL ,`R2 ,`R9 ,`R8 }; 

//OREG_TEX_COORD1 = [u1 + v2*H, u2 + v1*H, 0]
//R4 = FixedToIinteger(R4)
171: I =  { `UNSCALE ,`R4 ,`R4 ,`VOID }; 
172: I =  { `ADD ,`OREG_TEX_COORD1 ,`R2 ,`R4 }; 
173: I =  { `SETX ,`R5 ,32'h3  }; 
174: I =  { `SETY ,`R5 ,32'h3  }; 
175: I =  { `SETZ ,`R5 ,32'h3  }; 
//Multiply by 3 (the pitch)
176: I =  { `IMUL ,`OREG_TEX_COORD1 ,`OREG_TEX_COORD1 ,`R5 }; 

//R4 = [u2 u1 0]
177: I =  { `SWIZZLE3D ,`R4 ,`SWIZZLE_YXZ  }; 


//OREG_TEX_COORD2 [u2 + v2*H, u1 + v1*H, 0]
178: I =  { `ADD ,`OREG_TEX_COORD2 ,`R2 ,`R4 }; 
//Multiply by 3 (the pitch)
179: I =  { `IMUL ,`OREG_TEX_COORD2 ,`OREG_TEX_COORD2 ,`R5 }; 


//Cool now get the weights

//w1 = (1 - fracu) * (1 - fracv);
//w2 = fracu * (1 - fracv);
//w3 = (1 - fracu) * fracv;
//w4 = fracu *  fracv;

//R4x: fracu 
//R4y: fracv 
//R4z: 0
180: I =  { `FRAC ,`R4 ,`R7 ,`VOID }; 

//R5x: fracv 
//R5y: fracu 
//R5z: 0 
181: I =  { `COPY ,`R5 ,`R4 ,`VOID }; 
182: I =  { `SWIZZLE3D ,`R5 ,`SWIZZLE_YXZ  }; 


//R5x: 1 - fracv 
//R5y: 1 - fracu 
//R5y: 1
183: I =  { `NEG ,`R5 ,`R5 ,`VOID }; 
184: I =  { `INC ,`R5 ,`R5 ,`VOID }; 

//R5x: 1 - fracv 
//R5y: 1 - fracu 
//R5y: (1 - fracv)(1 - fracu) 
185: I =  { `MULP ,`OREG_TEXWEIGHT1 ,`R5 ,`VOID }; 

//OREG_TEXWEIGHT1.x = (1 - fracv)(1 - fracu) 
//OREG_TEXWEIGHT1.y = (1 - fracv)(1 - fracu) 
//OREG_TEXWEIGHT1.z = (1 - fracv)(1 - fracu) 
186: I =  { `SWIZZLE3D ,`OREG_TEXWEIGHT1 ,`SWIZZLE_ZZZ  }; 


//R6x: w2: fracu * (1 - fracv )
//R6y: w3: fracv * (1 - fracu )
//R6z: 0
187: I =  { `MUL ,`R6 ,`R4 ,`R5 }; 

//OREG_TEXWEIGHT2.x = fracu * (1 - fracv )
//OREG_TEXWEIGHT2.y = fracu * (1 - fracv )
//OREG_TEXWEIGHT2.z = fracu * (1 - fracv )
188: I =  { `COPY ,`OREG_TEXWEIGHT2 ,`R6 ,`VOID }; 
189: I =  { `SWIZZLE3D ,`OREG_TEXWEIGHT2 ,`SWIZZLE_XXX  }; 

//OREG_TEXWEIGHT3.x = fracv * (1 - fracu )
//OREG_TEXWEIGHT3.y = fracv * (1 - fracu )
//OREG_TEXWEIGHT3.z = fracv * (1 - fracu )
190: I =  { `COPY ,`OREG_TEXWEIGHT3 ,`R6 ,`VOID }; 
191: I =  { `SWIZZLE3D ,`OREG_TEXWEIGHT3 ,`SWIZZLE_YYY  }; 


//R4x: fracu
//R4y: fracv
//R4z: fracu * fracv
192: I =  { `MULP ,`R4 ,`R4 ,`VOID }; 

//OREG_TEXWEIGHT4.x = fracv * fracu 
//OREG_TEXWEIGHT4.y = fracv * fracu 
//OREG_TEXWEIGHT4.z = fracv * fracu 
193: I =  { `COPY ,`OREG_TEXWEIGHT4 ,`R4 ,`VOID }; 
194: I =  { `SWIZZLE3D ,`OREG_TEXWEIGHT4 ,`SWIZZLE_ZZZ  }; 


//LABEL_TCC_EXIT:
195: I =  { `RETURN ,`RT_TRUE   }; 


//-------------------------------------------------------------------------
//TAG_PSU_UCODE_ADRESS:
//Pixel Shader #1
//This pixel shader has diffuse light but no textures

	 
196: I =  { `CROSS ,`R1 ,`CREG_E1_LAST ,`CREG_E2_LAST }; 
197: I =  { `MAG ,`R2 ,`R1 ,`VOID }; 
198: I =  { `DIV ,`R1 ,`R1 ,`R2 }; 
199: I =  { `MUL ,`R2 ,`CREG_RAY_DIRECTION ,`CREG_LAST_t }; 
200: I =  { `ADD ,`R2 ,`R2 ,`CREG_CAMERA_POSITION }; 
201: I =  { `SUB ,`R2 ,`CURRENT_LIGHT_POS ,`R2 }; 
202: I =  { `MAG ,`R3 ,`R2 ,`VOID }; 
203: I =  { `DIV ,`R2 ,`R2 ,`R3 }; 
204: I =  { `DOT ,`R3 ,`R2 ,`R1 }; 
205: I =  { `MUL ,`CREG_COLOR_ACC ,`CREG_TRI_DIFFUSE_LAST ,`CURRENT_LIGHT_DIFFUSE }; 
206: I =  { `MUL ,`CREG_COLOR_ACC ,`CREG_COLOR_ACC ,`R3 }; 
207: I =  { `COPY ,`OREG_PIXEL_COLOR ,`CREG_COLOR_ACC ,`VOID }; 
208: I =  { `JLEX ,`LABEL_DEBUG_PRINT_REGS ,`CREG_COLOR_ACC ,`R3 }; 
209: I =  { `JMP ,`LABEL_DEBUG_PRINT_REGS ,`VOID ,`VOID }; 
210: I =  { `NOP ,`RT_FALSE   };//{ `INC ,`OREG_PIXEL_PITCH ,`VOID  }; 
211: I =  { `RETURN ,`RT_TRUE   }; 

//-------------------------------------------------------------------------
//Pixel Shader #2
//TAG_PSU_UCODE_ADRESS2:


//This Pixel Shader has no light but it does texturinng 
//with bi-linear interpolation

//CColor TextureColor;
//TextureColor.R = c1.R * w1 + c2.R * w2 + c3.R * w3 + c4.R * w4;
//TextureColor.G = c1.G * w1 + c2.G * w2 + c3.G * w3 + c4.G * w4;
//TextureColor.B = c1.B * w1 + c2.B * w2 + c3.B * w3 + c4.B * w4;

212: I =  { `MUL ,`R1 ,`CREG_TEX_COLOR5 ,`OREG_TEXWEIGHT1 }; 
213: I =  { `MUL ,`R2 ,`CREG_TEX_COLOR2 ,`OREG_TEXWEIGHT2 }; 
214: I =  { `MUL ,`R3 ,`CREG_TEX_COLOR1 ,`OREG_TEXWEIGHT3 }; 
215: I =  { `MUL ,`R4 ,`CREG_TEX_COLOR4 ,`OREG_TEXWEIGHT4 }; 
216: I =  { `ADD ,`OREG_PIXEL_COLOR ,`R1 ,`R2 }; 
217: I =  { `ADD ,`OREG_PIXEL_COLOR ,`OREG_PIXEL_COLOR ,`R3 }; 
218: I =  { `ADD ,`OREG_PIXEL_COLOR ,`OREG_PIXEL_COLOR ,`R4 }; 
219: I =  { `RETURN ,`RT_TRUE   }; //{ `INC ,`OREG_PIXEL_PITCH ,`VOID  }; 


220: I =  { `RETURN ,`RT_TRUE   }; 


//-------------------------------------------------------------------------
//Debug Code
//TAG_DEBUG_LOG_REGISTERS:

//LABEL_DEBUG_PRINT_REGS:
/*
221: I =  { `DEBUG_PRINT ,`CREG_PIXEL_2D_POSITION ,`CREG_PIXEL_2D_POSITION ,`VOID }; 
222: I =  { `DEBUG_PRINT ,`COLOR_ACC ,`COLOR_ACC ,`VOID }; 
223: I =  { `DEBUG_PRINT ,`CREG_LAST_t ,`CREG_LAST_t ,`VOID }; 
224: I =  { `DEBUG_PRINT ,`CREG_E1_LAST ,`CREG_E1_LAST ,`VOID }; 
225: I =  { `DEBUG_PRINT ,`CREG_E2_LAST ,`CREG_E2_LAST ,`VOID }; 
226: I =  { `DEBUG_PRINT ,`CREG_RAY_DIRECTION ,`CREG_RAY_DIRECTION ,`VOID }; 
227: I =  { `DEBUG_PRINT ,`CREG_CAMERA_POSITION ,`CREG_CAMERA_POSITION ,`VOID }; 
228: I =  { `DEBUG_PRINT ,`CREG_V0 ,`CREG_V0 ,`VOID }; 
229: I =  { `DEBUG_PRINT ,`CREG_V1 ,`CREG_V1 ,`VOID }; 
230: I =  { `DEBUG_PRINT ,`CREG_V2 ,`CREG_V2 ,`VOID }; 
231: I =  { `RETURN ,`RT_TRUE   }; 
*/

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