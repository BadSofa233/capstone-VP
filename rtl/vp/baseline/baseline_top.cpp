// this is the simulation file for the baseline (last-value) predictor
// Author: Yuhan Li
// Oct 31, 2021

#include "Vbaseline_top.h"
#include "verilated.h"
#include <stdio.h>
#include <time.h>
#include <string.h>

// toggle the clock twice
void tick(Vbaseline_top * DUT) {
    DUT->eval();
    DUT->clk_i = 1;
    DUT->eval();
    DUT->clk_i = 0;
    DUT->eval();
}

// assert one cycle of reset to DUT
void reset(Vbaseline_top * DUT) {
    DUT->rst_i = 1;
    tick(DUT);
    DUT->rst_i = 0;
    tick(DUT);
}

int main(int argc, char **argv, char **env) {
    
    int P_STORAGE_SIZE = 2048;
    int P_CONF_THRES_WIDTH = 8;
    int P_NUM_PRED = 2;
    
    for(int i = 0; i < argc; i++) {
        if(strcmp(argv[i], "-P_STORAGE_SIZE") == 0) {
            i++;
            P_STORAGE_SIZE = atoi(argv[i]);
        }
        else if(strcmp(argv[i], "-P_CONF_THRES_WIDTH") == 0) {
            i++;
            P_CONF_THRES_WIDTH = atoi(argv[i]);
        }
        else if(strcmp(argv[i], "-P_NUM_PRED") == 0) {
            i++;
            P_NUM_PRED = atoi(argv[i]);
        }
    }
    
    // print parameters
    printf("SIM INFO: P_STORAGE_SIZE set to %d, P_CONF_THRES_WIDTH set to %d, P_NUM_PRED set to %d\n", P_STORAGE_SIZE, P_CONF_THRES_WIDTH, P_NUM_PRED);
    
    // relay runtime parameters to verilator
    Verilated::commandArgs(argc, argv);
    
    // instantiate the design, don't forget to delete!
    Vbaseline_top* DUT = new Vbaseline_top;
    
    // debugging testcase, check prediction of one entry
    // let the predictor predict and validate one entry excessively
    int conf_count = 1<<4;
    srand(time(NULL));
    int pc = rand();
    reset(DUT);
    
    for(int i = 0; i < conf_count; i++) {
        DUT->fw_pc_i = pc;
        DUT->fb_pc_i = pc;
        DUT->fb_result_i = 0xFFFF;
        DUT->fb_valid_i = 1;
        
        tick(DUT);
        
        printf("itr %d ent_vld %d ent_val 0x%lX pred 0x%lX conf %d valid %d misp %d\n", i, DUT->entry_valid_dbgo, DUT->entry_val_dbgo, DUT->pred_o, DUT->conf_dbgo, DUT->pred_valid_o, DUT->mispredict_o);
        
    }
    
    DUT->final();
    
    // TODO: testcases
    
    delete DUT;
    
    return 0;
    
}
