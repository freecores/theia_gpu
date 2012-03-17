`include "aDefinitions.v"

/**********************************************************************************
Theia, Ray Cast Programable graphic Processing Unit.
Copyright (C) 2012  Diego Valverde (diego.valverde.g@gmail.com)

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


module RegisterFile # ( parameter DATA_WIDTH=`DATA_ROW_WIDTH, parameter ADDR_WIDTH=`DATA_ADDRESS_WIDTH )
(
input wire                                 Clock,
input wire                                 Reset,
input wire [ADDR_WIDTH-1:0]                iReadAddress0,
input wire [ADDR_WIDTH-1:0]                iReadAddress1,
input wire [2:0]                           iWriteEnable,
input wire [ADDR_WIDTH-1:0]                iWriteAddress,
input wire [DATA_WIDTH-1:0]                iData,
output wire [`DATA_ADDRESS_WIDTH-1:0]      oFrameOffset,
output wire [DATA_WIDTH-1:0]               oData0,
output wire [DATA_WIDTH-1:0]               oData1

);

parameter DATA_CHANNEL_WIDTH = DATA_WIDTH / 3;

wire wEnableFrameOffsetOverwrite;
assign wEnableFrameOffsetOverwrite = (iWriteAddress == `SPR_CONTROL) ? 1'b1 : 1'b0;

FFD_POSEDGE_SYNCRONOUS_RESET # ( `DATA_ADDRESS_WIDTH ) FDD_FRAMEOFFSET
( 	Clock, Reset, (wEnableFrameOffsetOverwrite & iWriteEnable[2]) ,iData[`X_RNG], oFrameOffset  );

RAM_DUAL_READ_PORT # ( DATA_CHANNEL_WIDTH, ADDR_WIDTH ) RF_X
(
 .Clock(             Clock            ),
 .iWriteEnable(      iWriteEnable[2]  ),
 .iReadAddress0(     iReadAddress0    ),
 .iReadAddress1(     iReadAddress1    ),
 .iWriteAddress(     iWriteAddress    ),
 .iDataIn(           iData[`X_RNG]    ),
 .oDataOut0(         oData0[`X_RNG]   ),
 .oDataOut1(         oData1[`X_RNG]   )
);


RAM_DUAL_READ_PORT # ( DATA_CHANNEL_WIDTH, ADDR_WIDTH ) RF_Y
(
 .Clock(             Clock            ),
 .iWriteEnable(      iWriteEnable[1]  ),
 .iReadAddress0(     iReadAddress0    ),
 .iReadAddress1(     iReadAddress1    ),
 .iWriteAddress(     iWriteAddress    ),
 .iDataIn(           iData[`Y_RNG]    ),
 .oDataOut0(         oData0[`Y_RNG]   ),
 .oDataOut1(         oData1[`Y_RNG]   )
);


RAM_DUAL_READ_PORT # ( DATA_CHANNEL_WIDTH, ADDR_WIDTH ) RF_Z
(
 .Clock(             Clock            ),
 .iWriteEnable(      iWriteEnable[0]  ),
 .iReadAddress0(     iReadAddress0    ),
 .iReadAddress1(     iReadAddress1    ),
 .iWriteAddress(     iWriteAddress    ),
 .iDataIn(           iData[`Z_RNG]    ),
 .oDataOut0(         oData0[`Z_RNG]   ),
 .oDataOut1(         oData1[`Z_RNG]   )
);

endmodule
