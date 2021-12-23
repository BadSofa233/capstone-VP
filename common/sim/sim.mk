# this is the common Makefile script for verilator simulation workflow
# it defines targets
# Author: Yuhan Li
# Nov 1 2021

# set verilator headers root directory
VERILATOR_DIR = /usr/share/verilator
VERILATOR_INCL_DIR = $(VERILATOR_DIR)/include

# set the path to the common scripts
SCRIPT_DIR = $(VP_ROOT_DIR)/common/sim

# set the executable name and compilation arguments
EXE = obj_dir/$(MODULE)_sim

# default target, run verilator to compile RTL design, compile the C++ testbench, and execute the program
all: executable
	@printf "\nStarting sims...\n\n"
	$(EXE) $(EXE_RUNTIME_ARGS)
	@printf "\nSims complete.\n"

# compiles executable
executable: verilate testbench cmodel
	@printf "\nCompiling executable...\n\n"
	g++ -I $(VERILATOR_INCL_DIR) -I $(VERILATOR_INCL_DIR)/vltstd -I $(SCRIPT_DIR) -I obj_dir -I $(CM_INCL_DIR) $(CMODEL_COMP_ARGS) $(VERILATOR_INCL_DIR)/verilated.cpp $(VERILATOR_INCL_DIR)/verilated_vcd_c.cpp $(SIM_TOP_FILES) $(MODULE)_cmodel.o obj_dir/V$(MODULE)__ALL.a $(EXE_COMP_ARGS) -o $(EXE)

# compiles the testbench
testbench: $(SRC_DIR)/$(RTL_FILES)
	@printf "\nGenerating testbench...\n\n"
	dos2unix $(SCRIPT_DIR)/generate_testbench.sh
	bash $(SCRIPT_DIR)/generate_testbench.sh $(SRC_DIR) $(MODULE) $(SIM_DIR)

cmodel: $(CM_FILES)
	@printf "\nCompiling cmodel...\n\n"
	g++ -I $(CM_INCL_DIR) $(CMODEL_COMP_ARGS) -c $(CM_FILES)

# compiles the RTL design
verilate: $(SRC_DIR)/$(RTL_FILES) 
	@printf "\nRunning verilate...\n\n"
	verilator -Wall --cc $(SRC_DIR)/$(RTL_FILES) $(VERILATOR_COMP_ARGS)
	$(MAKE) -C obj_dir -j -f V$(MODULE).mk

# remove output
clean:
	@printf "\nRunning clean...\n\n"
	rm -rf obj_dir/
	rm -f $(MODULE)_tb_trace.vcd
	rm -f $(MODULE)_tb.h
