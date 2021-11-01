# this is the common Makefile script for verilator simulation workflow
# it defines targets
# Author: Yuhan Li
# Nov 1 2021

# set verilator headers root directory
VERILATOR_DIR = /usr/share/verilator

# set the executable name and compilation arguments
EXE = obj_dir/$(MODULE)_sim

# default target, run verilator to compile RTL design, compile the C++ testbench, and execute the program
all: $(RTL_FILES) $(SIM_FILES) verilate
	g++ -I $(VERILATOR_DIR)/include -I $(VERILATOR_DIR)/include/vltstd -I obj_dir $(VERILATOR_DIR)/include/verilated.cpp $(MODULE).cpp obj_dir/V$(MODULE)__ALL.a -o $(EXE) $(EXE_COMP_ARGS)
	$(EXE) $(EXE_RUNTIME_ARGS)

# only compiles the RTL design
verilate:
	verilator -Wall --cc $(RTL_FILES) $(VERILATOR_COMP_ARGS)
	$(MAKE) -C obj_dir -j -f V$(MODULE).mk

# remove output
clean:
	rm -rf obj_dir