# this is the execution Makefile script for baseline_top
# it compiles module baseline_top and simulates it in baseline_top.cpp
# Author: Yuhan Li
# Oct 31 2021

VP_ROOT_DIR = $(abspath ../../../)
DESIGN_DIR = $(abspath ../)
SRC_DIR = $(DESIGN_DIR)/src
SIM_DIR = $(abspath ./)

MODULE ?= baseline_top

# RTL source files
RTL_FILES = $(MODULE).sv
RTL_FILES += $(VP_ROOT_DIR)/vp/multiport_ram/src/multiport_ram.sv

# simulation top source files
SIM_TOP_FILES = $(MODULE).cpp

# cmodel simulation source files and include path
CM_FILES = $(MODULE)_cmodel.h $(MODULE)_cmodel.cpp

# define parameters for the block
P_STORAGE_SIZE ?= 2048
P_CONF_WIDTH ?= 8
P_NUM_PRED ?= 2

# trace dumping
DUMP ?= 0

# write parameter definitions to RTL
VERILATOR_COMP_ARGS += +define+P_STORAGE_SIZE=$(P_STORAGE_SIZE) 
VERILATOR_COMP_ARGS += +define+P_CONF_WIDTH=$(P_CONF_WIDTH) 
VERILATOR_COMP_ARGS += +define+P_NUM_PRED=$(P_NUM_PRED)

# enable trace
ifeq ($(DUMP),1)
	VERILATOR_COMP_ARGS += --trace
	EXE_COMP_ARGS += -DDUT_DUMP_TRACE=1
endif

# write parameter definitions to sim runtime
EXE_RUNTIME_ARGS += -P_STORAGE_SIZE $(P_STORAGE_SIZE)
EXE_RUNTIME_ARGS += -P_CONF_WIDTH $(P_CONF_WIDTH)
EXE_RUNTIME_ARGS += -P_NUM_PRED $(P_NUM_PRED)

# include the common simulation script
include $(VP_ROOT_DIR)/common/sim/sim.mk