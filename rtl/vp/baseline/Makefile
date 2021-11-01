MODULE ?= baseline_top

RTL_FILES ?= $(MODULE).sv
SIM_FILES ?= $(MODULE).cpp

VERILATOR_DIR = /usr/share/verilator

all: $(RTL_FILES) $(SIM_FILES)
	verilator -Wall --cc $(RTL_FILES) --exe V$(MODULE).cpp
	-$(MAKE) -C obj_dir -j -f V$(MODULE).mk
	g++ -I $(VERILATOR_DIR)/include -I obj_dir $(VERILATOR_DIR)/include/verilated.cpp $(MODULE).cpp obj_dir/V$(MODULE)__ALL.a -o obj_dir/$(MODULE)_sim
	obj_dir/$(MODULE)_sim

verilate:
	verilator -Wall --cc $(RTL_FILES) --exe V$(MODULE).cpp
	-$(MAKE) -C obj_dir -j -f V$(MODULE).mk

clean:
	rm -rf obj_dir