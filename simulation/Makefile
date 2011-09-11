
VERILOGEX = .v # Verilog file extension
 
# testbench path TESTBENCH is passed from the command line
SCENEPATH = 
TESTBENCH = TestBench_THEIA
TESTBENCHPATH = ../testbench/${TESTBENCH}$(VERILOGEX)
SOURCEPATH = ../rtl
GPUCONFIGURATIONSCRIPT=../scripts/configure_gpu.pl
INPUTCONFIGURATIONSCRIPT=../scripts/configure_params.pl 
#iverilog CONFIG
VERILOG_CMD = iverilog
GPUCORES = 4
#VERILOG_FLAGS  = 
 
# VVP (iverilog runtime engine)
VVP_CMD = vvp
#VVP_FLAGS = 
 
#Simulation Vars
SIMDIR = .
DUMPTYPE = none 
DEBUG_CORE_ID = 
SCENEPATH = 
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
                                                                                     
 
 
check: file_check
	$(VERILOG_CMD) -t null $(FILES)
 
# Setup up project directory
new :
	echo "Setting up project ${PROJECT}"
	mkdir rtl testbench simulation	
 
 
compile : testbench_check
	perl $(GPUCONFIGURATIONSCRIPT) $(GPUCORES) 

	cp $(SOURCEPATH)/aDefinitions.v .
ifeq ($(strip $(DEBUG_CORE_ID)),)
	$(VERILOG_CMD) -o  $(SIMDIR)/$(TESTBENCH) $(TESTBENCHPATH) $(SOURCEPATH)/*                          
else
	 $(VERILOG_CMD) -DDEBUG=1 -DDUMP_CODE=1 -DDEBUG_CORE=$(DEBUG_CORE_ID) -o  $(SIMDIR)/$(TESTBENCH) $(TESTBENCHPATH) $(SOURCEPATH)/*
endif
	rm -f aDefinitions.v    
 
run : testbench_check
ifeq ($(strip $(SCENEPATH)),)
		@echo "SCENEPATH not set. Use SCENEPATH=value to set it"
		@exit 2
endif  
	cp -f $(SCENEPATH)/*.mem .
	perl $(INPUTCONFIGURATIONSCRIPT) $(GPUCORES) 
	$(VVP_CMD) ./$(TESTBENCH) -$(DUMPTYPE) $(VVP_FLAGS) 
 
view : testbench_check                                                                                              
	$(WAVEFORM_VIEWER)  $(SIMDIR)/$(TESTBENCH).$(DUMPTYPE)                                               
 
clean : test_bench_check                                                                                                 
	rm $(SIM_DIR)/$(TESTBENCH)*
