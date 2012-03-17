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


module Dumper;

always @ (posedge uut.Clock)
begin
//-----------------------------------------------------------------
	if (uut.II.iInstruction0[`INST_EOF_RNG])
		$display("End of flow instruction detected");
	
	if (uut.II.rIssueNow && uut.II.oIssueBcast[`ISSUE_RSID_RNG] != 0)
	begin
	   
			
		//Issue state dump
		$write("%dns IP %d    ISSUE ",$time,uut.II.oIP0);
		
		if (uut.II.iInstruction0[`INST_BRANCH_BIT])
			$write(" BRANCH ");
		
		case ( uut.II.oIssueBcast[`ISSUE_RSID_RNG] )
			`RS_ADD0: $write(" ADD_0 ");
			`RS_ADD1: $write(" ADD_1 ");
			`RS_DIV: $write(" DIV ");
			`RS_MUL: $write(" MUL ");
			`RS_SQRT: $write(" SQRT ");
			default:
			$write(" %b ",uut.II.oIssueBcast[`ISSUE_RSID_RNG]);
		endcase
		
		if ( uut.II.iInstruction0[`INST_IMM] == 0 && uut.II.iInstruction0[`INST_DEST_ZERO])
			$write( "R[%d + %d]", uut.II.iInstruction0[`INST_DST_RNG],uut.II.iFrameOffset);
		else
			$write( "R[%d]", uut.II.iInstruction0[`INST_DST_RNG]);
		
		case ( uut.II.oIssueBcast[`ISSUE_WE_RNG] )
			3'b000: $write(".nowrite ");
			3'b001: $write(".z ");
			3'b010: $write(".y ");
			3'b100: $write(".x ");
			3'b111: $write(".xyz ");
			default:
			$write(" %b ",uut.II.oIssueBcast[`ISSUE_WE_RNG]);
		endcase
		if (uut.II.iInstruction0[`INST_IMM])
			$write( "I(%h)",uut.II.iInstruction0[`INST_IMM_RNG]);
		else
		begin
			if (uut.II.iInstruction0[`INST_SRC1_DISPLACED] == 0)
				$write( "R[%d] ",uut.II.oSourceAddress1);
			else
				$write( "R[%d + %d] ",	uut.II.iInstruction0[`INST_SCR1_ADDR_RNG],uut.II.iFrameOffset);
				
			if (uut.II.iInstruction0[`INST_SRC0_DISPLACED] == 0)
				$write( "R[%d] ",uut.II.oSourceAddress0);
			else	
				$write( "R[%d + %d] ",	uut.II.iInstruction0[`INST_SRC0_ADDR_RNG],uut.II.iFrameOffset);
		end	
		
		$write("\t\t\t\t");
		case ( uut.II.oIssueBcast[`ISSUE_SRC1RS_RNG] )
			`RS_ADD0: $write(" ADD_0 ");
			`RS_ADD1: $write(" ADD_1 ");
			`RS_DIV: $write(" DIV ");
			`RS_MUL: $write(" MUL ");
			`RS_SQRT: $write(" SQRT ");
			default:
			$write(" %b ",uut.II.oIssueBcast[`ISSUE_SRC1RS_RNG]);
		endcase
		$write(" | ");
		
		case ( uut.II.oIssueBcast[`ISSUE_SRC0RS_RNG] )
			`RS_ADD0: $write(" ADD_0 ");
			`RS_ADD1: $write(" ADD_1 ");
			`RS_DIV: $write(" DIV ");
			`RS_MUL: $write(" MUL ");
			`RS_SQRT: $write(" SQRT ");
			default:
			$write(" %b ",uut.II.oIssueBcast[`ISSUE_SRC0RS_RNG]);
		endcase
		$write(" | ");
		
		$display(" %h | %h",
		uut.wModIssue[`MOD_ISSUE_SRC1_DATA_RNG],
		uut.wModIssue[`MOD_ISSUE_SRC0_DATA_RNG]
		);
	end

//-----------------------------------------------------------------		
if (uut.ADD_STA0.RS.iCommitGranted)
begin
	$write("%dns\t COMMIT ADD_0 R[%d]",$time,uut.ADD_STA0.oCommitData[`COMMIT_DST_RNG]);
	
	case ( uut.ADD_STA0.oCommitData[`COMMIT_WE_RNG] )
			3'b000: $write(".nowrite ");
			3'b001: $write(".z ");
			3'b010: $write(".y ");
			3'b100: $write(".x ");
			3'b111: $write(".xyz ");
			default:
			$write(" %b ",uut.ADD_STA0.oCommitData[`COMMIT_WE_RNG]);
		endcase
	$write(" %h %h %h\n",uut.ADD_STA0.oCommitData[`COMMIT_X_RNG],uut.ADD_STA0.oCommitData[`COMMIT_Y_RNG],uut.ADD_STA0.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		
if (uut.ADD_STA1.RS.iCommitGranted)
begin
	$write("%dns\t COMMIT ADD_1 R[%d]",$time,uut.ADD_STA1.oCommitData[`COMMIT_DST_RNG]);
	
	case ( uut.ADD_STA1.oCommitData[`COMMIT_WE_RNG] )
			3'b000: $write(".nowrite ");
			3'b001: $write(".z ");
			3'b010: $write(".y ");
			3'b100: $write(".x ");
			3'b111: $write(".xyz ");
			default:
			$write(" %b ",uut.ADD_STA1.oCommitData[`COMMIT_WE_RNG]);
		endcase
	$write(" %h %h %h\n",uut.ADD_STA1.oCommitData[`COMMIT_X_RNG],uut.ADD_STA1.oCommitData[`COMMIT_Y_RNG],uut.ADD_STA1.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		
if (uut.DIV_STA.RS.iCommitGranted)
begin
	$write("%dns\t COMMIT DIV R[%d]",$time,uut.DIV_STA.oCommitData[`COMMIT_DST_RNG]);
	
	case ( uut.DIV_STA.oCommitData[`COMMIT_WE_RNG] )
			3'b000: $write(".nowrite ");
			3'b001: $write(".z ");
			3'b010: $write(".y ");
			3'b100: $write(".x ");
			3'b111: $write(".xyz ");
			default:
			$write(" %b ",uut.DIV_STA.oCommitData[`COMMIT_WE_RNG]);
		endcase
	$write(" %h %h %h\n",uut.DIV_STA.oCommitData[`COMMIT_X_RNG],uut.DIV_STA.oCommitData[`COMMIT_Y_RNG],uut.DIV_STA.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		
if (uut.MUL_STA.RS.iCommitGranted)
begin
	$write("%dns\t COMMIT MUL R[%d]",$time,uut.MUL_STA.oCommitData[`COMMIT_DST_RNG]);
	
	case ( uut.MUL_STA.oCommitData[`COMMIT_WE_RNG] )
			3'b000: $write(".nowrite ");
			3'b001: $write(".z ");
			3'b010: $write(".y ");
			3'b100: $write(".x ");
			3'b111: $write(".xyz ");
			default:
			$write(" %b ",uut.MUL_STA.oCommitData[`COMMIT_WE_RNG]);
		endcase
	$write(" %h %h %h\n",uut.MUL_STA.oCommitData[`COMMIT_X_RNG],uut.MUL_STA.oCommitData[`COMMIT_Y_RNG],uut.MUL_STA.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		
if (uut.SQRT_STA.RS.iCommitGranted)
begin
	$write("%dns\t COMMIT SQRT R[%d]",$time,uut.SQRT_STA.oCommitData[`COMMIT_DST_RNG]);
	
	case ( uut.SQRT_STA.oCommitData[`COMMIT_WE_RNG] )
			3'b000: $write(".nowrite ");
			3'b001: $write(".z ");
			3'b010: $write(".y ");
			3'b100: $write(".x ");
			3'b111: $write(".xyz ");
			default:
			$write(" %b ",uut.SQRT_STA.oCommitData[`COMMIT_WE_RNG]);
		endcase
	$write(" %h \n",uut.SQRT_STA.oCommitData[`COMMIT_DATA_RNG]);
end
//-----------------------------------------------------------------		
	
end //always

endmodule
