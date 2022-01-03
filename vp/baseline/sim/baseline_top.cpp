// this is the simulation file for the baseline (last-value) predictor
// Author: Yuhan Li
// Oct 31, 2021

#include "baseline_top_tb_test.h"
#include "baseline_top_cmodel.h"
#include <stdio.h>
#include <time.h>
#include <string.h>

// int debug_test(Baseline_top_tb & dut, Baseline_top_cmodel & dut_cmodel, int P_CONF_WIDTH); 
int debug_test(Baseline_top_tb & dut, int P_CONF_WIDTH); 

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
    
    Baseline_top_cmodel cmodel(P_NUM_PRED, P_CONF_WIDTH, P_STORAGE_SIZE);
    
    // instantiate the design
    Baseline_top_tb dut(&cmodel);
    
    // instantiate CMODEL;
    // TODO: move CMODEL and DUT instantiation into testbench, modify cmodel signals inside tb
    // Baseline_top_cmodel dut_cmodel(P_NUM_PRED, P_CONF_WIDTH, P_STORAGE_SIZE);
    
    // TODO: testcases
    // debug_test(dut, dut_cmodel, P_CONF_WIDTH);
    debug_test(dut, P_CONF_WIDTH);
    
    return 0;
    
}

// debugging testcase, check prediction of one entry
// let the predictor predict and validate one entry excessively
// int debug_test(Baseline_top_tb & dut, Baseline_top_cmodel & dut_cmodel, int P_CONF_WIDTH) {
int debug_test(Baseline_top_tb & dut, int P_CONF_WIDTH) {
    
    int conf_count = 1<<P_CONF_WIDTH; // == 2^P_CONF_WIDTH
    int pc = rand();
    dut.reset_1();
    
    for(int i = 0; i < conf_count + 1; i++) {
        dut.write_fw_pc_i(pc);
        dut.write_fw_valid_i(0xF);
        dut.tick();
        dut.write_fb_pc_i(pc);
        dut.write_fb_mispredict_i(dut.read_pred_result_o(false) != 0xFFFF); // assume execution result is 0xFFFF
        dut.write_fb_actual_i(0xFFFF);
        dut.write_fb_valid_i(0xF);
        // if using cmodel:
        // cmodel.write_...(...)
        
        
        
        printf("itr %d fw_conf %d fw_valid 0x%lX pred 0x%lX\n", i, dut.read_pred_conf_o(false) & (conf_count-1) , dut.read_pred_valid_o(false), dut.read_pred_result_o(false));
        
        // compare confidence
        // using cmodel: 
        // if(i != conf_count && dut.read_pred_conf_o() != cmodel.read_pred_conf_o()) {
            // ...
        // }
        if(i != conf_count && (dut.read_pred_conf_o(false) & (conf_count-1)) != 0) {
            printf("ERROR: prediction confidence is wrong!\n");
            return 1;
        }
        
        // compare other output signals here...
    }
    
    dut.final();

    return 0;
}
