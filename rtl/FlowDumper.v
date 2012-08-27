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
//`define VP2_TOP( core ) `THEIA_TOP.\VPX[ core ].VP
`define MAX_OMEM_DUMP_SIZE 32
`define MAX_RF_MEM_DUMP_SIZE 128

//`define DEBUG_TO_STDOUT 1

`ifdef DEBUG_TO_STDOUT
	`define DWRITE $write(
`else
	`define DWRITE $fwrite(VP_LOG,
`endif
module VectorProcessor_Dumper # (parameter CVPID = 2);


integer RESULT_FILE,VP_LOG,OMEM_LOG,VP_REG_LOG,i;
reg [255:1] VPLogFileName,OMEMLogFileName,RegLogFileName;



	
	

initial 
begin
	//Open output file
	$swrite(VPLogFileName,"vp.%01d.log",CVPID);
	$swrite(OMEMLogFileName,"OMEM.vp.%01d.log",CVPID);
	$swrite(RegLogFileName,"rf.vp.%01d.log",CVPID);
	RESULT_FILE = $fopen("test_result.log");
	VP_LOG = $fopen(VPLogFileName);
end



//always @ (posedge `THEIA_TOP.VPX[  CVPID ].VP.Clock )
always @ (posedge `VP_TOP.Clock)
begin
//-----------------------------------------------------------------

	if (`VP_TOP.EXE.II0.iInstruction0[`INST_EOF_RNG])
	begin
		$display(VP_LOG,"End of flow instruction detected");
		$fwrite(RESULT_FILE,"Simulation ended at time %dns\n",$time);
		$fwrite(RESULT_FILE,"multithread = %d\n",`VP_TOP.EXE.wThreadControl[`SPR_TCONTROL0_MT_ENABLED]);
		$fwrite(RESULT_FILE,"Simulation RESULT %h\n",`VP_TOP.EXE.RF.RF_X.Ram[66]);
		$fclose(RESULT_FILE);
		$fclose( VP_LOG );
		
		//Now write the output log
		OMEM_LOG = $fopen(OMEMLogFileName);
		for (i = 0; i < `MAX_OMEM_DUMP_SIZE; i = i +1)
		begin
			$fwrite(OMEM_LOG,"@%d\t%h\n",i,`THEIA_TOP.VPX[ CVPID ].OMEM.Ram[i]);
		end	
		$fclose(OMEM_LOG);
		
		VP_REG_LOG = $fopen(RegLogFileName);
		for (i = 0; i < `MAX_RF_MEM_DUMP_SIZE; i = i +1)
		begin
			$fwrite(VP_REG_LOG,"r%01d\t%h %h %h\n",i,
			`THEIA_TOP.VPX[ CVPID ].VP.EXE.RF.RF_X.Ram[i],
			`THEIA_TOP.VPX[ CVPID ].VP.EXE.RF.RF_Y.Ram[i],
			`THEIA_TOP.VPX[ CVPID ].VP.EXE.RF.RF_Z.Ram[i]);
		end	
		$fclose(VP_REG_LOG);
		$stop;
		$finish;
	end	
//`ifdef 0	
	if (`VP_TOP.EXE.II0.rIssueNow && `VP_TOP.EXE.II0.oIssueBcast[`ISSUE_RSID_RNG] != 0)
	begin
	   
			
		//Issue state dump
		`DWRITE"\n%dns VP[%d] IP %d    ISSUE ",$time,`VP_TOP.iVPID-1,`VP_TOP.EXE.II0.oIP0-1);
		
		//Issue instruction undecoded
		`DWRITE" (%h) \t",`VP_TOP.EXE.II0.iInstruction0);
		
		if (`VP_TOP.EXE.II0.iInstruction0[`INST_BRANCH_BIT])
			`DWRITE" BRANCH ");
		
		case ( `VP_TOP.EXE.II0.oIssueBcast[`ISSUE_RSID_RNG] )
			`RS_ADD0: `DWRITE" ADD_0 ");
			`RS_ADD1: `DWRITE" ADD_1 ");
			`RS_DIV: `DWRITE" DIV ");
			`RS_MUL: `DWRITE" MUL ");
			`RS_SQRT: `DWRITE" SQRT ");
			`RS_LOGIC:
			begin
			`DWRITE" LOGIC( ");
			case (`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SCALE_RNG])
			0: `DWRITE"AND");
			1: `DWRITE"OR");
			2: `DWRITE"NOT");
			3: `DWRITE"SHL");
			4: `DWRITE"SHR");
			default:
			  `DWRITE"UNKNOWN");
			endcase
			`DWRITE")  ");
			end
			`RS_IO:`DWRITE" IO ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_RSID_RNG]);
		endcase
		
		if ( `VP_TOP.EXE.II0.iInstruction0[`INST_IMM] == 0)
		begin
			if (`VP_TOP.EXE.II0.iInstruction0[`INST_DEST_ZERO])
				`DWRITE "R[%d + %d]", `VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II0.iFrameOffset);
			else 
				`DWRITE "R[%d]", `VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG]);
		end	
		else
		begin
		
				case (`VP_TOP.EXE.II0.iInstruction0[`INST_ADDRMODE_RNG])
				3'b000: `DWRITE"R[%d]",`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG]);
				3'b001: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II0.iFrameOffset);
				3'b010: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II0.iFrameOffset);
				3'b011: `DWRITE"R[%d + %d + %d]",`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II0.iFrameOffset,`VP_TOP.EXE.II0.wSource1_Temp[`X_RNG]);
				3'b100: `DWRITE"R[%d]",`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG]);
				3'b101: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II0.iFrameOffset);
				3'b110: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II0.iFrameOffset);
				3'b111: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II0.iFrameOffset);
				endcase
		end	
		
		case ( `VP_TOP.EXE.II0.oIssueBcast[`ISSUE_WE_RNG] )
			3'b000: `DWRITE".nowrite ");
			3'b001: `DWRITE".z ");
			3'b010: `DWRITE".y ");
			3'b100: `DWRITE".x ");
			3'b111: `DWRITE".xyz ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_WE_RNG]);
		endcase
		
		if (`VP_TOP.EXE.II0.iInstruction0[`INST_IMM])
			/*if (`VP_TOP.EXE.II0.iInstruction0[`INST_SRC0_DISPLACED] && `VP_TOP.EXE.II0.iInstruction0[`INST_SRC1_DISPLACED])
				`DWRITE "R[%d] 0 ",`VP_TOP.EXE.II0.oSourceAddress0);
			else
				`DWRITE "I(%h)",`VP_TOP.EXE.II0.iInstruction0[`INST_IMM_RNG]);*/
				case (`VP_TOP.EXE.II0.iInstruction0[`INST_ADDRMODE_RNG])
				3'b000: `DWRITE"I(%h) R[%d]",`VP_TOP.EXE.II0.iInstruction0[`INST_IMM_RNG], `VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG]);
				3'b001: `DWRITE"**!!I(%h) R[%d + %d] ",`VP_TOP.EXE.II0.iInstruction0[`INST_IMM_RNG],`VP_TOP.EXE.II0.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II0.iFrameOffset);
				3'b010: `DWRITE"R[%d+%d] R[%d+%d+%d]",`VP_TOP.EXE.II0.oSourceAddress1,`VP_TOP.EXE.II0.iFrameOffset,`VP_TOP.EXE.II0.oSourceAddress0,`VP_TOP.EXE.II0.iFrameOffset,`VP_TOP.EXE.II0.iIndexRegister);
				3'b011: `DWRITE"0 R[%d + %d]",`VP_TOP.EXE.II0.oSourceAddress0,`VP_TOP.EXE.II0.iFrameOffset);
				3'b100: `DWRITE"I(%h) 0",`VP_TOP.EXE.II0.iInstruction0[`INST_IMM_RNG]);
				3'b101: `DWRITE"I(%h) 0",`VP_TOP.EXE.II0.iInstruction0[`INST_IMM_RNG]);
				3'b110: `DWRITE"R[%d + %d + %d] 0", `VP_TOP.EXE.II0.oSourceAddress1,`VP_TOP.EXE.II0.iFrameOffset,`VP_TOP.EXE.II0.iIndexRegister);
				3'b111: `DWRITE"R[%d + %d + %d] R[%d + %d]",`VP_TOP.EXE.II0.iInstruction0[`INST_SCR1_ADDR_RNG],`VP_TOP.EXE.II0.iFrameOffset,`VP_TOP.EXE.II0.iIndexRegister,`VP_TOP.EXE.II0.oSourceAddress0,`VP_TOP.EXE.II0.iFrameOffset);
				endcase
		else
		begin
			if (`VP_TOP.EXE.II0.iInstruction0[`INST_SRC1_DISPLACED] == 0)
				`DWRITE "R[%d] ",`VP_TOP.EXE.II0.oSourceAddress1);
			else
				`DWRITE "R[%d + %d] ",	`VP_TOP.EXE.II0.iInstruction0[`INST_SCR1_ADDR_RNG],`VP_TOP.EXE.II0.iFrameOffset);
				
			if (`VP_TOP.EXE.II0.iInstruction0[`INST_SRC0_DISPLACED] == 0)
				`DWRITE "R[%d] ",`VP_TOP.EXE.II0.oSourceAddress0);
			else	
				`DWRITE "R[%d + %d] ",	`VP_TOP.EXE.II0.iInstruction0[`INST_SRC0_ADDR_RNG],`VP_TOP.EXE.II0.iFrameOffset);
		end	
		
		`DWRITE"\t\t\t\t");
		case ( `VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SRC1RS_RNG] )
			`RS_ADD0: `DWRITE" ADD_0 ");
			`RS_ADD1: `DWRITE" ADD_1 ");
			`RS_DIV: `DWRITE" DIV ");
			`RS_MUL: `DWRITE" MUL ");
			`RS_SQRT: `DWRITE" SQRT ");
			`RS_IO: `DWRITE" IO ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SRC1RS_RNG]);
		endcase
		`DWRITE" | ");
		
		case ( `VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SRC0RS_RNG] )
			`RS_ADD0: `DWRITE" ADD_0 ");
			`RS_ADD1: `DWRITE" ADD_1 ");
			`RS_DIV: `DWRITE" DIV ");
			`RS_MUL: `DWRITE" MUL ");
			`RS_SQRT: `DWRITE" SQRT ");
			`RS_IO: `DWRITE" IO ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SRC0RS_RNG]);
		endcase
		`DWRITE" | ");
		
		`DWRITE" %h.%b | %h.%b s(%b)|  -> ",
		`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SRC1_DATA_RNG],
		`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SWZZ1_RNG],
		`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SRC0_DATA_RNG],
		`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SWZZ0_RNG],
		`VP_TOP.EXE.II0.oIssueBcast[`ISSUE_SCALE_RNG]);
		
		`DWRITE" %h | %h",
		`VP_TOP.EXE.wModIssue[`MOD_ISSUE_SRC1_DATA_RNG],
		`VP_TOP.EXE.wModIssue[`MOD_ISSUE_SRC0_DATA_RNG]
		);
	end


////////////// Same for thread 1...








//-----------------------------------------------------------------
	
	
	if (`VP_TOP.EXE.II1.rIssueNow && `VP_TOP.EXE.II1.oIssueBcast[`ISSUE_RSID_RNG] != 0)
	begin
	   
			
		//Issue state dump
		`DWRITE"\n THREAD 1 %dns IP %d    ISSUE ",$time,`VP_TOP.EXE.II1.oIP0-1);
		
		//Issue instruction undecoded
		`DWRITE" (%h) \t",`VP_TOP.EXE.II1.iInstruction0);
		
		if (`VP_TOP.EXE.II1.iInstruction0[`INST_BRANCH_BIT])
			`DWRITE" BRANCH ");
		
		case ( `VP_TOP.EXE.II1.oIssueBcast[`ISSUE_RSID_RNG] )
			`RS_ADD0: `DWRITE" ADD_0 ");
			`RS_ADD1: `DWRITE" ADD_1 ");
			`RS_DIV: `DWRITE" DIV ");
			`RS_MUL: `DWRITE" MUL ");
			`RS_SQRT: `DWRITE" SQRT ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.II1.oIssueBcast[`ISSUE_RSID_RNG]);
		endcase
		
		if ( `VP_TOP.EXE.II1.iInstruction0[`INST_IMM] == 0)
		begin
			if (`VP_TOP.EXE.II1.iInstruction0[`INST_DEST_ZERO])
				`DWRITE "R[%d + %d]", `VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II1.iFrameOffset);
			else 
				`DWRITE "R[%d]", `VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG]);
		end	
		else
		begin
		
				case (`VP_TOP.EXE.II1.iInstruction0[`INST_ADDRMODE_RNG])
				3'b000: `DWRITE"R[%d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG]);
				3'b001: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II1.iFrameOffset);
				3'b010: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II1.iFrameOffset);
				3'b011: `DWRITE"R[%d + %d + %d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II1.iFrameOffset,`VP_TOP.EXE.II1.wSource1_Temp[`X_RNG]);
				3'b100: `DWRITE"R[%d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG]);
				3'b101: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II1.iFrameOffset);
				3'b110: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II1.iFrameOffset);
				3'b111: `DWRITE"R[%d + %d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II1.iFrameOffset);
				endcase
		end	
		
		case ( `VP_TOP.EXE.II1.oIssueBcast[`ISSUE_WE_RNG] )
			3'b000: `DWRITE".nowrite ");
			3'b001: `DWRITE".z ");
			3'b010: `DWRITE".y ");
			3'b100: `DWRITE".x ");
			3'b111: `DWRITE".xyz ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.II1.oIssueBcast[`ISSUE_WE_RNG]);
		endcase
		
		if (`VP_TOP.EXE.II1.iInstruction0[`INST_IMM])
			/*if (`VP_TOP.EXE.II1.iInstruction0[`INST_SRC0_DISPLACED] && `VP_TOP.EXE.II1.iInstruction0[`INST_SRC1_DISPLACED])
				`DWRITE "R[%d] 0 ",`VP_TOP.EXE.II1.oSourceAddress0);
			else
				`DWRITE "I(%h)",`VP_TOP.EXE.II1.iInstruction0[`INST_IMM_RNG]);*/
				case (`VP_TOP.EXE.II1.iInstruction0[`INST_ADDRMODE_RNG])
				3'b000: `DWRITE"I(%h) R[%d]",`VP_TOP.EXE.II1.iInstruction0[`INST_IMM_RNG], `VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG]);
				3'b001: `DWRITE"I(%h) R[%d + %d]",`VP_TOP.EXE.II1.iInstruction0[`INST_DST_RNG],`VP_TOP.EXE.II1.oSourceAddress0,`VP_TOP.EXE.II1.iFrameOffset);
				3'b010: `DWRITE"R[%d+%d] R[%d+%d+%d]",`VP_TOP.EXE.II1.oSourceAddress1,`VP_TOP.EXE.II1.iFrameOffset,`VP_TOP.EXE.II1.oSourceAddress0,`VP_TOP.EXE.II1.iFrameOffset,`VP_TOP.EXE.II1.iIndexRegister);
				3'b011: `DWRITE"0 R[%d + %d]",`VP_TOP.EXE.II1.oSourceAddress0,`VP_TOP.EXE.II1.iFrameOffset);
				3'b100: `DWRITE"I(%h) 0",`VP_TOP.EXE.II1.iInstruction0[`INST_IMM_RNG]);
				3'b101: `DWRITE"I(%h) 0",`VP_TOP.EXE.II1.iInstruction0[`INST_IMM_RNG]);
				3'b110: `DWRITE"R[%d + %d + %d] 0", `VP_TOP.EXE.II1.oSourceAddress1,`VP_TOP.EXE.II1.iFrameOffset,`VP_TOP.EXE.II1.iIndexRegister);
				3'b111: `DWRITE"R[%d + %d + %d] R[%d + %d]",`VP_TOP.EXE.II1.iInstruction0[`INST_SCR1_ADDR_RNG],`VP_TOP.EXE.II1.iFrameOffset,`VP_TOP.EXE.II1.iIndexRegister,`VP_TOP.EXE.II1.oSourceAddress0,`VP_TOP.EXE.II1.iFrameOffset);
				endcase
		else
		begin
			if (`VP_TOP.EXE.II1.iInstruction0[`INST_SRC1_DISPLACED] == 0)
				`DWRITE "R[%d] ",`VP_TOP.EXE.II1.oSourceAddress1);
			else
				`DWRITE "R[%d + %d] ",	`VP_TOP.EXE.II1.iInstruction0[`INST_SCR1_ADDR_RNG],`VP_TOP.EXE.II1.iFrameOffset);
				
			if (`VP_TOP.EXE.II1.iInstruction0[`INST_SRC0_DISPLACED] == 0)
				`DWRITE "R[%d] ",`VP_TOP.EXE.II1.oSourceAddress0);
			else	
				`DWRITE "R[%d + %d] ",	`VP_TOP.EXE.II1.iInstruction0[`INST_SRC0_ADDR_RNG],`VP_TOP.EXE.II1.iFrameOffset);
		end	
		
		`DWRITE"\t\t\t\t");
		case ( `VP_TOP.EXE.II1.oIssueBcast[`ISSUE_SRC1RS_RNG] )
			`RS_ADD0: `DWRITE" ADD_0 ");
			`RS_ADD1: `DWRITE" ADD_1 ");
			`RS_DIV: `DWRITE" DIV ");
			`RS_MUL: `DWRITE" MUL ");
			`RS_SQRT: `DWRITE" SQRT ");
			`RS_IO: `DWRITE" IO ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.II1.oIssueBcast[`ISSUE_SRC1RS_RNG]);
		endcase
		`DWRITE" | ");
		
		case ( `VP_TOP.EXE.II1.oIssueBcast[`ISSUE_SRC0RS_RNG] )
			`RS_ADD0: `DWRITE" ADD_0 ");
			`RS_ADD1: `DWRITE" ADD_1 ");
			`RS_DIV: `DWRITE" DIV ");
			`RS_MUL: `DWRITE" MUL ");
			`RS_SQRT: `DWRITE" SQRT ");
			`RS_IO: `DWRITE" IO ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.II1.oIssueBcast[`ISSUE_SRC0RS_RNG]);
		endcase
		`DWRITE" | ");
		
		`DWRITE" %h | %h",
		`VP_TOP.EXE.wModIssue[`MOD_ISSUE_SRC1_DATA_RNG],
		`VP_TOP.EXE.wModIssue[`MOD_ISSUE_SRC0_DATA_RNG]
		);
	end






////////////////////////// DUMP EXE UNITS!

if (`VP_TOP.EXE.II0.wCommitFromPendingStation)
begin
	if ( `VP_TOP.EXE.II0.wBranchTaken)
		`DWRITE"\nTHREAD 0: BRANCH TAKEN ");
	
end		
	
if (`VP_TOP.EXE.II1.wCommitFromPendingStation)
begin
	if ( `VP_TOP.EXE.II1.wBranchTaken)
	
		`DWRITE"\nTHREAD 1: BRANCH TAKEN ");
	
end
//-----------------------------------------------------------------		
if (`VP_TOP.EXE.LOGIC_STA.RS.iCommitGranted)
begin
`DWRITE"\n%dns VP[%d]\t COMMIT LOGIC( ",$time,`VP_TOP.iVPID-1);
			
			case (`VP_TOP.EXE.LOGIC_STA.wResultSelector)
			0: `DWRITE"AND");
			1: `DWRITE"OR");
			2: `DWRITE"NOT");
			3: `DWRITE"SHL");
			4: `DWRITE"SHR");
			default:
			  `DWRITE"UNKNOWN");
			endcase
			`DWRITE")  ");
	 `DWRITE" R[%d]",`VP_TOP.EXE.LOGIC_STA.oCommitData[`COMMIT_DST_RNG]);
	
	case ( `VP_TOP.EXE.LOGIC_STA.oCommitData[`COMMIT_WE_RNG] )
			3'b000: `DWRITE".nowrite ");
			3'b001: `DWRITE".z ");
			3'b010: `DWRITE".y ");
			3'b100: `DWRITE".x ");
			3'b111: `DWRITE".xyz ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.LOGIC_STA.oCommitData[`COMMIT_WE_RNG]);
		endcase
	`DWRITE" %h %h %h\n",`VP_TOP.EXE.LOGIC_STA.oCommitData[`COMMIT_X_RNG],`VP_TOP.EXE.LOGIC_STA.oCommitData[`COMMIT_Y_RNG],`VP_TOP.EXE.LOGIC_STA.oCommitData[`COMMIT_Z_RNG]);
end		
//-----------------------------------------------------------------		
if (`VP_TOP.EXE.ADD_STA0.RS.iCommitGranted)
begin
	`DWRITE"\n%dns\t VP[%d] COMMIT ADD_0 R[%d]",$time,`VP_TOP.iVPID-1,`VP_TOP.EXE.ADD_STA0.oCommitData[`COMMIT_DST_RNG]);
	
	case ( `VP_TOP.EXE.ADD_STA0.oCommitData[`COMMIT_WE_RNG] )
			3'b000: `DWRITE".nowrite ");
			3'b001: `DWRITE".z ");
			3'b010: `DWRITE".y ");
			3'b100: `DWRITE".x ");
			3'b111: `DWRITE".xyz ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.ADD_STA0.oCommitData[`COMMIT_WE_RNG]);
		endcase
	`DWRITE" %h %h %h\n",`VP_TOP.EXE.ADD_STA0.oCommitData[`COMMIT_X_RNG],`VP_TOP.EXE.ADD_STA0.oCommitData[`COMMIT_Y_RNG],`VP_TOP.EXE.ADD_STA0.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		
if (`VP_TOP.EXE.ADD_STA1.RS.iCommitGranted)
begin
	`DWRITE"\n%dns\t VP[%d] COMMIT ADD_1 R[%d]",$time,`VP_TOP.iVPID-1,`VP_TOP.EXE.ADD_STA1.oCommitData[`COMMIT_DST_RNG]);
	
	case ( `VP_TOP.EXE.ADD_STA1.oCommitData[`COMMIT_WE_RNG] )
			3'b000: `DWRITE".nowrite ");
			3'b001: `DWRITE".z ");
			3'b010: `DWRITE".y ");
			3'b100: `DWRITE".x ");
			3'b111: `DWRITE".xyz ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.ADD_STA1.oCommitData[`COMMIT_WE_RNG]);
		endcase
	`DWRITE" %h %h %h\n",`VP_TOP.EXE.ADD_STA1.oCommitData[`COMMIT_X_RNG],`VP_TOP.EXE.ADD_STA1.oCommitData[`COMMIT_Y_RNG],`VP_TOP.EXE.ADD_STA1.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		
if (`VP_TOP.EXE.DIV_STA.RS.iCommitGranted)
begin
	`DWRITE"\n%dns\t VP[%d] COMMIT DIV R[%d]",$time,`VP_TOP.iVPID-1,`VP_TOP.EXE.DIV_STA.oCommitData[`COMMIT_DST_RNG]);
	
	case ( `VP_TOP.EXE.DIV_STA.oCommitData[`COMMIT_WE_RNG] )
			3'b000: `DWRITE".nowrite ");
			3'b001: `DWRITE".z ");
			3'b010: `DWRITE".y ");
			3'b100: `DWRITE".x ");
			3'b111: `DWRITE".xyz ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.DIV_STA.oCommitData[`COMMIT_WE_RNG]);
		endcase
	`DWRITE" %h %h %h\n",`VP_TOP.EXE.DIV_STA.oCommitData[`COMMIT_X_RNG],`VP_TOP.EXE.DIV_STA.oCommitData[`COMMIT_Y_RNG],`VP_TOP.EXE.DIV_STA.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		
if (`VP_TOP.EXE.MUL_STA.RS.iCommitGranted)
begin
	`DWRITE"\n%dns\t VP[%d] COMMIT MUL R[%d]",$time,`VP_TOP.iVPID-1, `VP_TOP.EXE.MUL_STA.oCommitData[`COMMIT_DST_RNG]);
	
	case ( `VP_TOP.EXE.MUL_STA.oCommitData[`COMMIT_WE_RNG] )
			3'b000: `DWRITE".nowrite ");
			3'b001: `DWRITE".z ");
			3'b010: `DWRITE".y ");
			3'b100: `DWRITE".x ");
			3'b111: `DWRITE".xyz ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.MUL_STA.oCommitData[`COMMIT_WE_RNG]);
		endcase
	`DWRITE" %h %h %h\n",`VP_TOP.EXE.MUL_STA.oCommitData[`COMMIT_X_RNG],`VP_TOP.EXE.MUL_STA.oCommitData[`COMMIT_Y_RNG],`VP_TOP.EXE.MUL_STA.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		
if (`VP_TOP.EXE.SQRT_STA.RS.iCommitGranted)
begin
	`DWRITE"\n%dns\t VP[%d] COMMIT SQRT R[%d]",$time,`VP_TOP.iVPID-1,`VP_TOP.EXE.SQRT_STA.oCommitData[`COMMIT_DST_RNG]);
	
	case ( `VP_TOP.EXE.SQRT_STA.oCommitData[`COMMIT_WE_RNG] )
			3'b000: `DWRITE".nowrite ");
			3'b001: `DWRITE".z ");
			3'b010: `DWRITE".y ");
			3'b100: `DWRITE".x ");
			3'b111: `DWRITE".xyz ");
			default:
			`DWRITE" %b ",`VP_TOP.EXE.SQRT_STA.oCommitData[`COMMIT_WE_RNG]);
		endcase
	`DWRITE" %h %h %h \n",`VP_TOP.EXE.SQRT_STA.oCommitData[`COMMIT_X_RNG],`VP_TOP.EXE.SQRT_STA.oCommitData[`COMMIT_Y_RNG], `VP_TOP.EXE.SQRT_STA.oCommitData[`COMMIT_Z_RNG]);
end
//-----------------------------------------------------------------		

end //always


endmodule
