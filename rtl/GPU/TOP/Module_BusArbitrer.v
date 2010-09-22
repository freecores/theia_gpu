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



module Module_BusArbitrer
(
input wire Clock,
input wire Reset,

input wire [`MAX_CORES-1:0] iRequest,
output wire [`MAX_CORES-1:0] oGrant,
output wire [1:0] oBusSelect
);





wire wFFMS_connect;
wire wIncRR_pointer;
wire[3:0] wCurrentMasterMask;
reg[3:0] wCurrentBusMaster;
wire wCurrentRequest;

//Just one requester can have the bus at a given
//point in time, the mask makes sure this happens
assign oGrant[0] = iRequest[0] & wCurrentMasterMask[0];
assign oGrant[1] = iRequest[1] & wCurrentMasterMask[1];
assign oGrant[2] = iRequest[2] & wCurrentMasterMask[2];
assign oGrant[3] = iRequest[3] & wCurrentMasterMask[3];


//When a requester relinquishes the bus (by negating its [iRequest] signal),
//the switch is turned to the next position
//So while iRequest == 1 the ciruclar list will not move
CIRCULAR_SHIFTLEFT_POSEDGE_EX # (4) SHL_A
(
 .Clock( Clock ),
 .Enable( ~wCurrentRequest ),
 .Reset( Reset ),
 .Initial(4'b1), 
 .O( wCurrentMasterMask )
 
);

assign oBusSelect = wCurrentBusMaster;

MUXFULLPARALELL_2SEL_GENERIC # ( 1 ) MUXA
 (
 .Sel(wCurrentBusMaster[1:0]),
  .I1(iRequest[0]),
  .I2(iRequest[1]),
  .I3(iRequest[2]),
  .I4(iRequest[3]),
  .O1( wCurrentRequest )
  );

always @ ( * )
begin
	case (wCurrentMasterMask)
		4'b0001: wCurrentBusMaster <= 0;
		4'b0010: wCurrentBusMaster <= 1;
		4'b0100: wCurrentBusMaster <= 2;
		4'b1000: wCurrentBusMaster <= 3;
		default: wCurrentBusMaster <= 0;
	endcase
end

endmodule
