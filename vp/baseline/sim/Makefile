# this is the execution Makefile script for baseline_top
# it compiles module baseline_top and simulates it in baseline_top.cpp
# Author: Yuhan Li
# Oct 31 2021

VP_ROOT_DIR = $(abspath ../../../)
DESIGN_DIR = $(abspath ../)
SRC_DIR = $(DESIGN_DIR)/src

MODULE ?= baseline_top

# RTL source files
RTL_FILES = $(SRC_DIR)/$(MODULE).sv

# simulation source files
SIM_FILES = $(MODULE).cpp $(VP_ROOT_DIR)/common/sim/Vwrapper.h $(MODULE)_tb.h

# define parameters for the block
P_STORAGE_SIZE ?= 2048
P_CONF_THRES_WIDTH ?= 8
P_NUM_PRED ?= 2

# trace dumping
DUMP ?= 0

# write parameter definitions to RTL
VERILATOR_COMP_ARGS += +define+P_STORAGE_SIZE=$(P_STORAGE_SIZE) 
VERILATOR_COMP_ARGS += +define+P_CONF_THRES_WIDTH=$(P_CONF_THRES_WIDTH) 
VERILATOR_COMP_ARGS += +define+P_NUM_PRED=$(P_NUM_PRED)

# enable trace
ifeq ($(DUMP),1)
	VERILATOR_COMP_ARGS += --trace
endif

# write parameter definitions to sim runtime
EXE_RUNTIME_ARGS += -P_STORAGE_SIZE $(P_STORAGE_SIZE)
EXE_RUNTIME_ARGS += -P_CONF_THRES_WIDTH $(P_CONF_THRES_WIDTH)
EXE_RUNTIME_ARGS += -P_NUM_PRED $(P_NUM_PRED)

# include the common simulation script
include $(VP_ROOT_DIR)/common/sim/sim.mk