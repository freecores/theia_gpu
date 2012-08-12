
VERILOGEX = .v # Verilog file extension
 
# testbench path TESTBENCH is passed from the command line
SCENEPATH = 
TESTBENCH = testbench_theia_icarus
TESTBENCHPATH = ../testbench/${TESTBENCH}$(VERILOGEX)
SOURCEPATH = ../rtl

#iverilog CONFIG
VERILOG_CMD = iverilog
#VERILOG_FLAGS  = 
 
# VVP (iverilog runtime engine)
VVP_CMD = vvp
#VVP_FLAGS = 
 
#Simulation Vars
SIMDIR = .
DUMPTYPE = none 

#Viewer
WAVEFORM_VIEWER = gtkwave # Waveform viewer executable
 
 
all: compile run view
 
file_check:
ifeq ($(strip $(FILES)),)
		@echo "FILES not set. Use FILES=value to set it. Put mutltiple files in quotes"
		@exit 2
endif                                                                                             
 
testbench_check:
ifeq ($(strip $(TESTBENCH)),)
		@echo "TESTBENCH not set. Use TESTBENCH=value to set it."
		@exit 2
endif      
                                                                                     
 
 
check: 
	$(VERILOG_CMD) -t null $(FILES)
 
 
 
compile : testbench_check
	

	cp $(SOURCEPATH)/aDefinitions.v .

	$(VERILOG_CMD) -o  $(SIMDIR)/$(TESTBENCH) $(TESTBENCHPATH) $(SOURCEPATH)/*                          

	rm -f aDefinitions.v    
 
run : testbench_check
  
	$(VVP_CMD) -n ./$(TESTBENCH) -$(DUMPTYPE) $(VVP_FLAGS) 
 
 
clean :                                                                                                  
	rm *.{mem,ppm,log}
