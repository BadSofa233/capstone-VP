# this is the common Makefile script for verilator simulation workflow
# it defines targets
# Author: Yuhan Li
# Nov 1 2021

# set verilator headers root directory
VERILATOR_DIR = /usr/share/verilator

# set the path to the common scripts
SCRIPT_DIR = $(VP_ROOT_DIR)/common/sim

# set the executable name and compilation arguments
EXE = obj_dir/$(MODULE)_sim

# default target, run verilator to compile RTL design, compile the C++ testbench, and execute the program
all: $(RTL_FILES) $(SIM_FILES) verilate
	dos2unix $(SCRIPT_DIR)/generate_testbench.sh
	bash $(SCRIPT_DIR)/generate_testbench.sh $(DESIGN_DIR)/ $(MODULE)
	g++ -I $(VERILATOR_DIR)/include -I $(VERILATOR_DIR)/include/vltstd -I $(SCRIPT_DIR) -I obj_dir $(VERILATOR_DIR)/include/verilated.cpp $(VERILATOR_DIR)/include/verilated_vcd_c.cpp $(MODULE).cpp obj_dir/V$(MODULE)__ALL.a -o $(EXE) $(EXE_COMP_ARGS)
	@printf "\nStarting sims...\n\n"
	$(EXE) $(EXE_RUNTIME_ARGS)
	@printf "\nSims complete.\n"

# only compiles the RTL design
verilate:
	verilator -Wall --cc $(RTL_FILES) $(VERILATOR_COMP_ARGS)
	$(MAKE) -C obj_dir -j -f V$(MODULE).mk

# remove output
clean:
	rm -rf obj_dir