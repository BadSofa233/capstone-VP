// this is the simulation file for the baseline (last-value) predictor
// Author: Yuhan Li
// Oct 31, 2021

#include "baseline_top_tb.h"
#include "baseline_top_cmodel.h"
#include <stdio.h>
#include <time.h>
#include <string.h>

int debug_test(Baseline_top_tb & dut, Baseline_top_cmodel & dut_cmodel); 

int main(int argc, char **argv, char **env) {
    
    bool rand_seed = true;
    int seed = 0;
    
    int P_STORAGE_SIZE = 2048;
    int P_CONF_WIDTH = 8;
    int P_NUM_PRED = 2;
    
    for(int i = 0; i < argc; i++) {
        if(strcmp(argv[i], "-seed") == 0) {
            rand_seed = false;
            i++;
            seed = atoi(argv[i]);
        }
        else if(strcmp(argv[i], "-P_STORAGE_SIZE") == 0) {
            i++;
            P_STORAGE_SIZE = atoi(argv[i]);
        }
        else if(strcmp(argv[i], "-P_CONF_WIDTH") == 0) {
            i++;
            P_CONF_WIDTH = atoi(argv[i]);
        }
        else if(strcmp(argv[i], "-P_NUM_PRED") == 0) {
            i++;
            P_NUM_PRED = atoi(argv[i]);
        }
    }
    
    if(rand_seed) {
        srand(time(NULL));
    }
    else {
        srand(seed);
    }
    
    // print parameters
    printf("SIM INFO: P_STORAGE_SIZE set to %d, P_CONF_WIDTH set to %d, P_NUM_PRED set to %d\n", P_STORAGE_SIZE, P_CONF_WIDTH, P_NUM_PRED);
    
    // relay runtime parameters to verilator
    Verilated::commandArgs(argc, argv);
    
    // instantiate the design
    Baseline_top_tb dut;
    
    // instantiate CMODEL;
    Baseline_top_cmodel dut_cmodel;
    
    // TODO: testcases
    debug_test(dut, dut_cmodel);
    
    return 0;
    
}

// debugging testcase, check prediction of one entry
// let the predictor predict and validate one entry excessively
int debug_test(Baseline_top_tb & dut, Baseline_top_cmodel & dut_cmodel) {
    
    int conf_count = 1<<4;
    int pc = rand();
    dut.reset_1();
    
    for(int i = 0; i < conf_count; i++) {
        dut.write_fw_pc_i(pc);
        dut.write_fb_pc_i(pc);
        dut.write_fb_actual_i(0xFFFF);
        dut.write_fb_valid_i(1);
        
        dut.tick();
        
        // printf("itr %d ent_vld %d ent_val 0x%lX pred 0x%lX conf %d valid %d misp %d\n", i, dut.read_entry_valid_dbgo(), dut.read_entry_val_dbgo(), dut.read_pred_o(), dut.read_conf_dbgo(), dut.read_pred_valid_o(), dut.read_mispredict_o());
        
    }
    
    dut.final();

    return 0;
}
