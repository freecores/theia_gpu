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

//`define DEBUG_TO_STDOUT 1

`ifdef DEBUG_TO_STDOUT
	`define DWRITE $write(
`else
	`define DWRITE $fwrite(CP_LOG,
`endif


module ContolCode_Dumper;
//wait( `CP_TOP.Reset == 0 );
integer CP_LOG;
reg [255:1] CPLogFileName;
	

initial 
begin
	//Open output file
	
	CP_LOG = $fopen("cp.log");
end





always @ ( posedge `CP_TOP.Clock )
begin
	
		case (`CP_TOP.wOperation)
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_COPYBLOCK:
		begin
			`DWRITE"\n%dns CP:    COPYBLOCK DSTID: %d    BLKLEN: %d  TAG: %d  DSTOFF: %h    SRCOFF: %h\n\n",$time,
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCKCMD_VPMASK_RNG],
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCKCMD_BLKLEN_RNG],
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCK_TAG_BIT],
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCKCMD_DSTOFF_RNG],
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCKCMD_SRCOFF_RNG]);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_DELIVER_COMMAND:
		begin
			`DWRITE"%dns CP: DELIVER_COMMAND VP[%d] ",$time,
			`CP_TOP.wDestination);
			
			case (`CP_TOP.wSourceAddr1)
				`VP_COMMAND_START_MAIN_THREAD: `DWRITE " START_MAIN_THREAD ");
				`VP_COMMAND_STOP_MAIN_THREAD: `DWRITE " STOP_MAIN_THREAD ");
			endcase
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_NOP:
		begin
			`DWRITE"%dns CP: NOP\n",$time);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_EXIT:
		begin
			`DWRITE"%dns CP: EXIT\n",$time);
			//$stop;
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_ADD:
		begin
		
		if (`CP_TOP.rWriteEnable)
			`DWRITE"%dns CP: ADD R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_SUB:
		begin
			`DWRITE"%dns CP: SUB R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_AND:
		begin
			`DWRITE"%dns CP: AND R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_OR:
		begin
		`DWRITE"%dns CP: OR R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_SHL:
		begin
		`DWRITE"%dns CP: SHL R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_SHR:
		begin
		`DWRITE"%dns CP: SHR R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BLE:
		begin
			`DWRITE"%dns CP: BLE\n",$time);
			
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BL:
		begin
			`DWRITE"%dns CP: BL\n",$time);
			
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BG:
		begin
			`DWRITE"%dns CP: BG\n",$time);
			
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BGE:
		begin
			`DWRITE"%dns CP: BGE\n",$time);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BEQ:
		begin
			`DWRITE"%dns CP: BEQ %d,   R[%d] {%h} R[%d] {%h}\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0);
			
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BNE:
		begin
			`DWRITE"%dns CP: BNE\n",$time);
			
		end
		//-------------------------------------	
		`CONTROL_PROCESSOR_OP_BRANCH:
		begin
			`DWRITE"%dns CP: BRANCH %h\n",$time,`CP_TOP.wDestination );
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_ASSIGN:
		begin
			`DWRITE"%dns CP: ASSIGN R[%d] I(%h)= %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wImmediateValue,`CP_TOP.rResult);
			
		end
		//-------------------------------------
		default:
		begin
		
		end	
		//-------------------------------------		
		endcase
	
	
end
endmodule

