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

module ContolCode_Dumper;
//wait( `CP_TOP.Reset == 0 );
always @ ( posedge `CP_TOP.Clock )
begin
	
		case (`CP_TOP.wOperation)
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_COPYBLOCK:
		begin
			$write("\n%dns CP:    COPYBLOCK DSTID: %d    BLKLEN: %d  TAG: %d  DSTOFF: %h    SRCOFF: %h\n\n",$time,
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCKCMD_VPMASK_RNG],
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCKCMD_BLKLEN_RNG],
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCK_TAG_BIT],
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCKCMD_DSTOFF_RNG],
			`CP_TOP.oCopyBlockCommand[`MCU_COPYMEMBLOCKCMD_SRCOFF_RNG]);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_DELIVER_COMMAND:
		begin
			$write("%dns CP: DELIVER_COMMAND VP[%d] ",$time,
			`CP_TOP.wDestination);
			
			case (`CP_TOP.wSourceAddr1)
				`VP_COMMAND_START_MAIN_THREAD: $write( " START_MAIN_THREAD ");
				`VP_COMMAND_STOP_MAIN_THREAD: $write( " STOP_MAIN_THREAD ");
			endcase
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_NOP:
		begin
			$write("%dns CP: NOP\n",$time);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_EXIT:
		begin
			$write("%dns CP: EXIT\n",$time);
			//$stop;
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_ADD:
		begin
		
		if (`CP_TOP.rWriteEnable)
			$write("%dns CP: ADD R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_SUB:
		begin
			$write("%dns CP: SUB R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_AND:
		begin
			$write("%dns CP: AND R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_OR:
		begin
		$write("%dns CP: OR R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_SHL:
		begin
		$write("%dns CP: SHL R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_SHR:
		begin
		$write("%dns CP: SHR R[%d] R[%d]{%h} R[%d]{%h} = %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0,`CP_TOP.rResult);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BLE:
		begin
			$write("%dns CP: BLE\n",$time);
			
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BL:
		begin
			$write("%dns CP: BL\n",$time);
			
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BG:
		begin
			$write("%dns CP: BG\n",$time);
			
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BGE:
		begin
			$write("%dns CP: BGE\n",$time);
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BEQ:
		begin
			$write("%dns CP: BEQ %d,   R[%d] {%h} R[%d] {%h}\n",$time,`CP_TOP.wDestination,`CP_TOP.wSourceAddr1,`CP_TOP.wSourceData1,`CP_TOP.wSourceAddr0,`CP_TOP.wSourceData0);
			
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_OP_BNE:
		begin
			$write("%dns CP: BNE\n",$time);
			
		end
		//-------------------------------------	
		`CONTROL_PROCESSOR_OP_BRANCH:
		begin
			$write("%dns CP: BRANCH %h\n",$time,`CP_TOP.wDestination );
		end
		//-------------------------------------
		`CONTROL_PROCESSOR_ASSIGN:
		begin
			$write("%dns CP: ASSIGN R[%d] I(%h)= %h\n",$time,`CP_TOP.wDestination,`CP_TOP.wImmediateValue,`CP_TOP.rResult);
			
		end
		//-------------------------------------
		default:
		begin
		
		end	
		//-------------------------------------		
		endcase
	
	
end
endmodule

