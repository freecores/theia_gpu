`include "aDefinitions.v"

`define CU_STATE_AFTER_RESET       0
`define CU_STATE_WAIT_FOR_CP       1
`define CU_STATE_HANDLE_CP_REQUEST 2
`define CU_STATE_START_MAIN_THREAD 3
`define CU_STATE_STOP_MAIN_THREAD  4

module ControlUnit
(
input wire                          Clock,
input wire                          Reset,
input wire [`CBC_BUS_WIDTH-1:0]     iCpCommand,
input wire [`VPID_WIDTH-1:0]        iVPID,
output wire                         oVpEnabled,
output wire                         oBusy
);



reg [4:0]                      rCurrentState, rNextState;
wire                           wRequestDetected;
reg                            rPopFifo;
reg                            rToggleVpEnabled;
wire [`CBC_BUS_WIDTH-1:0]      wCurrentRequest;


assign wRequestDetected = (iCpCommand[`CP_MSG_BCAST] || (iCpCommand[`CP_MSG_DST_RNG] == iVPID) ) ? 1'b1 : 1'b0;

//Incomming requests are stored in the FIFO
sync_fifo  # (`CBC_BUS_WIDTH,8 ) IN_FIFO
(
 .clk(    Clock              ),
 .reset(  Reset              ),
 .din(    iCpCommand         ),
 .wr_en(  wRequestDetected   ),
 .rd_en(  rPopFifo           ),
 .dout(   wCurrentRequest    ),
 .full(   oBusy              )
 
);


UPCOUNTER_POSEDGE # (1) UP1
(
.Clock(      Clock                                      ), 
.Reset(      Reset                                      ),
.Initial(    1'b0                                       ),
.Enable(     rToggleVpEnabled                           ),
.Q(          oVpEnabled                                 )
);

//Next states logic and Reset sequence
always @(posedge Clock ) 
  begin 
			
    if (Reset )  
		rCurrentState <= `CU_STATE_AFTER_RESET; 
    else        
		rCurrentState <= rNextState; 
		
end




always @ ( * )
begin
	case (rCurrentState)
	//--------------------------------------
	`CU_STATE_AFTER_RESET:
	begin
	   rPopFifo         = 1'b0;
		rToggleVpEnabled = 1'b0;
		
		rNextState = `CU_STATE_WAIT_FOR_CP;
	end
	//--------------------------------------
	`CU_STATE_WAIT_FOR_CP:
	begin
		rPopFifo         = 1'b0;
		rToggleVpEnabled = 1'b0;
	
		if ( wRequestDetected )
			rNextState = `CU_STATE_HANDLE_CP_REQUEST;
		else
			rNextState = `CU_STATE_WAIT_FOR_CP;
	end
	//--------------------------------------
	`CU_STATE_HANDLE_CP_REQUEST:
	begin
		rPopFifo         = 1'b0;
		rToggleVpEnabled = 1'b0;
	
		case ( wCurrentRequest[`CP_MSG_OPERATION_RNG] )
			`VP_COMMAND_START_MAIN_THREAD: rNextState = `CU_STATE_START_MAIN_THREAD;
			`VP_COMMAND_STOP_MAIN_THREAD:  rNextState = `CU_STATE_STOP_MAIN_THREAD; 
		default:
			rNextState = `CU_STATE_WAIT_FOR_CP;
		endcase
			
		
	end
	//--------------------------------------
	`CU_STATE_START_MAIN_THREAD:
	begin
		rPopFifo         = 1'b0;
		rToggleVpEnabled = ~oVpEnabled;
		
		
		rNextState = `CU_STATE_WAIT_FOR_CP;
	end
	//--------------------------------------
	`CU_STATE_STOP_MAIN_THREAD:
	begin
		rPopFifo         = 1'b0;
		rToggleVpEnabled = oVpEnabled;
		
		
		rNextState = `CU_STATE_WAIT_FOR_CP;
	end
	//--------------------------------------
	default:
	begin
		rPopFifo         = 1'b0;
		rToggleVpEnabled = 1'b0;
		
		rNextState = `CU_STATE_AFTER_RESET;
	end
	//--------------------------------------
endcase
end //always
endmodule
