// this is the simulation file for the baseline (last-value) predictor
// Author: Yuhan Li
// Oct 31, 2021

#include "baseline_top_tb.h"
#include "baseline_top_cmodel.h"
#include <inttypes.h>
#include <stdio.h>
#include <time.h>
#include <string.h>


int debug_test(Baseline_top_tb & dut, int P_CONF_WIDTH); 
int confidence_test(Baseline_top_tb & dut, int pc, int cycles); 
int conflict_test(Baseline_top_tb & dut, int pc, int cycles, int P_CONF_WIDTH); 
int random_test(Baseline_top_tb & dut, int cycles); 
void build_confidence(Baseline_top_tb & dut, uint64_t pc, uint64_t fb_value, int P_CONF_WIDTH);

int main(int argc, char **argv, char **env) {
    
    bool rand_seed = true;
    int seed = 0;
    
    int P_STORAGE_SIZE = 2048;
    int P_CONF_WIDTH = 8;
    int P_NUM_PRED = 2;
    
    int cycles = 10;
    int pc = -1;
    
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
        else if(strcmp(argv[i], "-cycles") == 0) {
            i++;
            cycles = atoi(argv[i]);
        }
        else if(strcmp(argv[i], "-pc") == 0) {
            i++;
            pc = atoi(argv[i]);
        }
    }
    
    if(rand_seed) {
        srand(time(NULL));
    }
    else {
        srand(seed);
    }
    
    if(pc < 0) {
        pc = rand();
    }
    
    // print parameters
    printf("SIM INFO: P_STORAGE_SIZE set to %d, P_CONF_WIDTH set to %d, P_NUM_PRED set to %d\n", P_STORAGE_SIZE, P_CONF_WIDTH, P_NUM_PRED);
    
    // relay runtime parameters to verilator
    Verilated::commandArgs(argc, argv);
    
    Baseline_top_cmodel cmodel(P_NUM_PRED, P_CONF_WIDTH, P_STORAGE_SIZE);
    
    // instantiate the design
    Baseline_top_tb dut(&cmodel);
    
    // TODO: testcases
    // debug_test(dut, P_CONF_WIDTH);
    
    confidence_test(dut, pc, cycles);
    
    conflict_test(dut, pc, cycles, P_CONF_WIDTH);
    
    random_test(dut, cycles);
    
    return 0;
    
}

// test the confidence of one entry excessively with different misprediction feedbacks, 
// first random misp feedback, then excessive correct feedback, then random misp again
// also randomizes pred0 vs pred1
int confidence_test(Baseline_top_tb & dut, int pc, int cycles) {
    uint64_t rand_result;
    unsigned rand_pred;
    unsigned pred_result;
    uint64_t pc_in;
    uint64_t fb_actual;
    unsigned fb_valid;
    unsigned fb_mispredict;
    unsigned fb_conf;
    // random misp to same pc
    for(int i = 0; i < cycles; i++) {
        rand_result = rand();
        rand_pred = rand() & 1;
        pc_in = rand_pred ? (uint64_t)pc << 31 : pc; // left shift PC if it's pred 1
        
        // printf("rand_pred %d, pc_in 0x%lX\n", rand_pred, pc_in);
        
        dut.write_fw_pc_i(pc_in);
        dut.write_fw_valid_i(0b11);
        
        dut.tick();
        
        pred_result     = rand_pred ? dut.read_pred_result_o(false) >> 32 : dut.read_pred_result_o(false);
        fb_valid        = (rand_pred ? 0b10 : 0b01 ) & (rand() & 0b11); // randomize fb_valid, make not all feedbacks valid
        fb_actual       = rand_pred ? rand_result << 32 : rand_result;
        fb_mispredict   = pred_result == rand_result ? 0 : 0b11;
        fb_conf         = dut.read_pred_conf_o(false);
        
        dut.write_fb_pc_i(pc_in);
        dut.write_fb_mispredict_i(fb_mispredict); // random misp
        dut.write_fb_actual_i(fb_actual);
        dut.write_fb_valid_i(fb_valid);
        dut.write_fb_conf_i(fb_conf);
    }
    // correct feedback, no misp, still randomized pred and fb_valid
    rand_result = rand();
    while(dut.read_pred_conf_o(false) == 0) { // test confidence build up
        rand_pred = rand() & 1;
        pc_in = rand_pred ? (uint64_t)pc << 31 : pc; // left shift PC if it's pred 1
        dut.write_fw_pc_i(pc_in);
        dut.write_fw_valid_i(0b11);
        
        dut.tick();
        
        pred_result     = rand_pred ? dut.read_pred_result_o(false) >> 32 : dut.read_pred_result_o(false);
        fb_valid        = (rand_pred ? 0b10 : 0b01 ) & (rand() & 0b11); // randomize fb_valid, make not all feedbacks valid
        fb_actual       = rand_pred ? rand_result << 32 : rand_result;
        fb_mispredict   = pred_result == rand_result ? 0 : 0b11;
        fb_conf         = dut.read_pred_conf_o(false);
        
        dut.write_fb_pc_i(pc_in);
        dut.write_fb_mispredict_i(fb_mispredict); // random misp
        dut.write_fb_actual_i(fb_actual);
        dut.write_fb_valid_i(fb_valid);
        dut.write_fb_conf_i(fb_conf);
    }
    for(int i = 0; i < cycles; i++) { // test maintaining the confidence
        rand_pred = rand() & 1;
        pc_in = rand_pred ? (uint64_t)pc << 31 : pc; // left shift PC if it's pred 1
        dut.write_fw_pc_i(pc_in);
        dut.write_fw_valid_i(0b11);
        
        dut.tick();
        
        pred_result     = rand_pred ? dut.read_pred_result_o(false) >> 32 : dut.read_pred_result_o(false);
        fb_valid        = (rand_pred ? 0b10 : 0b01 ) & (rand() & 0b11); // randomize fb_valid, make not all feedbacks valid
        fb_actual       = rand_pred ? rand_result << 32 : rand_result;
        fb_mispredict   = pred_result == rand_result ? 0 : 0b11;
        fb_conf         = dut.read_pred_conf_o(false);
        
        dut.write_fb_pc_i(pc_in);
        dut.write_fb_mispredict_i(fb_mispredict); // random misp
        dut.write_fb_actual_i(fb_actual);
        dut.write_fb_valid_i(fb_valid);
        dut.write_fb_conf_i(fb_conf);
    }
    
    // finally, randomize everything again except PC
    // random misp to same pc
    for(int i = 0; i < cycles; i++) {
        rand_result = rand();
        rand_pred = rand() & 1;
        pc_in = rand_pred ? (uint64_t)pc << 31 : pc; // left shift PC if it's pred 1
        dut.write_fw_pc_i(pc_in);
        dut.write_fw_valid_i(0b11);
        
        dut.tick();
        
        pred_result     = rand_pred ? dut.read_pred_result_o(false) >> 32 : dut.read_pred_result_o(false);
        fb_valid        = (rand_pred ? 0b10 : 0b01 ) & (rand() & 0b11); // randomize fb_valid, make not all feedbacks valid
        fb_actual       = rand_pred ? rand_result << 32 : rand_result;
        fb_mispredict   = pred_result == rand_result ? 0 : 0b11;
        fb_conf         = dut.read_pred_conf_o(false);
        
        dut.write_fb_pc_i(pc_in);
        dut.write_fb_mispredict_i(fb_mispredict); // random misp
        dut.write_fb_actual_i(fb_actual);
        dut.write_fb_valid_i(fb_valid);
        dut.write_fb_conf_i(fb_conf);
    }
    
    dut.final();
    
    printf("INFO: confidence test passed.\n");
    
    return 0;
}

// testing conflict address, randomized value, misp, and valid
int conflict_test(Baseline_top_tb & dut, int pc, int cycles, int P_CONF_WIDTH) {
    uint64_t actual_value0 = rand(), actual_value1 = actual_value0;
    uint64_t rand_result = (actual_value1 << 32) | actual_value0;
    uint64_t pc_in = ((uint64_t)pc << 31) | (uint64_t)pc;
    int cycle;
    
    // confidence build-up, both correct
    build_confidence(dut, pc_in, rand_result, P_CONF_WIDTH);
    
    // two concurrent mispredictions
    actual_value0 = ~actual_value0 & 0xFFFFFFFF;
    actual_value1 = ~actual_value1 & 0xFFFFFFFF;
    rand_result = (actual_value1 << 32) | actual_value0;
    
    dut.write_fb_pc_i(pc_in);
    dut.write_fb_mispredict_i(0b11);
    dut.write_fb_actual_i(rand_result);
    dut.write_fb_valid_i(0b11);
    dut.write_fb_conf_i(dut.read_pred_conf_o(false));
    
    dut.write_fw_pc_i(pc_in);
    dut.write_fw_valid_i(0b11);
    
    dut.tick();

    // assert confidence being 0
    if(dut.read_pred_conf_o(false) & (1<<P_CONF_WIDTH | 1<<(2*P_CONF_WIDTH+1))) {
        printf("ERROR: confidence not reset after two concurrent mispredictions.\n");
        exit(1);
    }
    
    if(dut.read_pred_result_o(false) != rand_result) {
        printf("ERROR: prediction result not updated after two concurrent mispredictions.\n");
        exit(1);
    }
    
    // build confidence again
    build_confidence(dut, pc_in, rand_result, P_CONF_WIDTH);
    
    // pred0 misprediction pred1 correct
    actual_value0 = ~actual_value0 & 0xFFFFFFFF;
    actual_value1 = actual_value1 & 0xFFFFFFFF;
    rand_result = (actual_value1 << 32) | actual_value0;
    
    dut.write_fb_pc_i(pc_in);
    dut.write_fb_mispredict_i(0b10);
    dut.write_fb_actual_i(rand_result);
    dut.write_fb_valid_i(0b11);
    dut.write_fb_conf_i(dut.read_pred_conf_o(false));
    
    dut.write_fw_pc_i(pc_in);
    dut.write_fw_valid_i(0b11);
    
    dut.tick();

    // assert confidence being 0
    if(dut.read_pred_conf_o(false) & (1<<P_CONF_WIDTH | 1<<(2*P_CONF_WIDTH+1))) {
        printf("ERROR: confidence not reset after conflict with pred0 misp.\n");
        exit(1);
    }
    
    // the prediction result should still be the old value because pred1 correct
    if(dut.read_pred_result_o(false) != ((actual_value1 << 32) | actual_value1)) {
        printf("ERROR: prediction result not updated after conflict with pred0 misp.\n");
        exit(1);
    }
    
    // build confidence again
    actual_value0 = ~actual_value0 & 0xFFFFFFFF;
    actual_value1 = actual_value1 & 0xFFFFFFFF;
    rand_result = (actual_value1 << 32) | actual_value0;
    build_confidence(dut, pc_in, rand_result, P_CONF_WIDTH);
    
    // pred0 misprediction pred1 correct
    actual_value0 = actual_value0 & 0xFFFFFFFF;
    actual_value1 = ~actual_value1 & 0xFFFFFFFF;
    rand_result = (actual_value1 << 32) | actual_value0;
    
    dut.write_fb_pc_i(pc_in);
    dut.write_fb_mispredict_i(0b01);
    dut.write_fb_actual_i(rand_result);
    dut.write_fb_valid_i(0b11);
    dut.write_fb_conf_i(dut.read_pred_conf_o(false));
    
    dut.write_fw_pc_i(pc_in);
    dut.write_fw_valid_i(0b11);
    
    dut.tick();

    // assert confidence being 0
    if(dut.read_pred_conf_o(false) & (1<<P_CONF_WIDTH | 1<<(2*P_CONF_WIDTH+1))) {
        printf("ERROR: confidence not reset after conflict with pred1 misp.\n");
        exit(1);
    }
    
    if(dut.read_pred_result_o(false) != ((actual_value1 << 32) | actual_value1)) {
        printf("ERROR: prediction result not updated after conflict with pred1 misp.\n");
        exit(1);
    }
    
}

int random_test(Baseline_top_tb & dut, int cycles) {
    uint64_t rand_result;
    unsigned rand_pred;
    unsigned pred_result;
    uint64_t pc_in;
    uint64_t fb_actual;
    unsigned fb_valid;
    unsigned fb_mispredict;
    unsigned fb_conf;
    cycles = 10000;
    
     // generate numbers
    for(int i = 0; i < cycles; i++) {
        rand_result = rand();
        int rand_flg = rand() % 4; // random from 0 to 3
        int flg =0;



        //rand_pred = rand() & 1;
        
        int pc_in = rand();
        
        dut.write_fw_pc_i(pc_in);
        dut.write_fw_valid_i(rand_flg);
        
        dut.tick();

        if (rand_flg == 0) {

        }else if (rand_flg == 1){
            pred_result = dut.read_pred_result_o(false) >> 32;
            flg = rand() % 1;
            fb_valid = flg ? 0b00 : 0b01;
            fb_actual = rand_result << 32;
            fb_mispredict   = pred_result == rand_result ? 0 : 0b11;
            fb_conf         = dut.read_pred_conf_o(false);
            dut.write_fb_pc_i(pc_in);
            dut.write_fb_mispredict_i(fb_mispredict); // random misp
            dut.write_fb_actual_i(fb_actual);
            dut.write_fb_valid_i(fb_valid);
            dut.write_fb_conf_i(fb_conf);
        }else if (rand_flg == 2){
            pred_result = dut.read_pred_result_o(false);
            flg = rand() % 1;
            fb_valid = flg ? 0b00 : 0b10;
            fb_actual=    rand_result;
            fb_mispredict   = pred_result == rand_result ? 0 : 0b11;
            fb_conf         = dut.read_pred_conf_o(false);
            dut.write_fb_pc_i(pc_in);
            dut.write_fb_mispredict_i(fb_mispredict); // random misp
            dut.write_fb_actual_i(fb_actual);
            dut.write_fb_valid_i(fb_valid);
            dut.write_fb_conf_i(fb_conf);
        }else if (rand_flg == 3){
            // pred_result = dut.read_pred_result_o(false);
            // flg = rand() % 1;
            // fb_valid = flg ? 0b00 : 0b10;
            // fb_actual=    rand_result;
            // fb_mispredict   = pred_result == rand_result ? 0 : 0b11;
            // fb_conf         = dut.read_pred_conf_o(false);
            // dut.write_fb_pc_i(pc_in);
            // dut.write_fb_mispredict_i(fb_mispredict); // random misp
            // dut.write_fb_actual_i(fb_actual);
            // dut.write_fb_valid_i(fb_valid);
            // dut.write_fb_conf_i(fb_conf);

            // //
            // //rand_result = rand();
            // pred_result = dut.read_pred_result_o(false) >> 32;
            // int flg = rand() % 1;
            // fb_valid = flg ? 0b00 : 0b01;
            // fb_actual = rand_result << 32;
            // fb_mispredict   = pred_result == rand_result ? 0 : 0b11;
            // fb_conf         = dut.read_pred_conf_o(false);
            // dut.write_fb_pc_i(pc_in);
            // dut.write_fb_mispredict_i(fb_mispredict); // random misp
            // dut.write_fb_actual_i(fb_actual);
            // dut.write_fb_valid_i(fb_valid);
            // dut.write_fb_conf_i(fb_conf);
        }
        

    }
    dut.final();
    
    printf("INFO: random test passed.\n");
    
    return 0;
}

// debugging testcase, check prediction of one entry
// let the predictor predict and validate one entry excessively
int debug_test(Baseline_top_tb & dut, int P_CONF_WIDTH) {
    
    int conf_count = 1<<P_CONF_WIDTH; // == 2^P_CONF_WIDTH
    uint64_t pc = rand() & 0xFFFFFFFF;
    dut.reset_1();
    
    for(int i = 0; i < conf_count + 2; i++) {
        dut.write_fw_pc_i(pc);
        dut.write_fw_valid_i(0b11);
        dut.tick();
        dut.write_fb_pc_i(pc);
        dut.write_fb_mispredict_i((dut.read_pred_result_o(false)) != 0xFFFF); // assume execution result is 0xFFFF
        dut.write_fb_actual_i(0xFFFF);
        dut.write_fb_valid_i(0b01);
        
        // printf("itr %d fw_conf %d fw_valid 0x%lX pred 0x%lX\n", i, dut.read_pred_conf_o(false) & (conf_count-1) , dut.read_pred_valid_o(false), dut.read_pred_result_o(false));
        
        // we check the signals within the DUT so no need for extra work here
    }
    
    dut.write_fw_pc_i(pc << 31);
    dut.write_fw_valid_i(0b11);
    dut.tick();
    dut.write_fb_pc_i(pc << 31);
    dut.write_fb_mispredict_i((dut.read_pred_result_o(false) >> 32) != 0xFFFF); // assume execution result is 0xFFFF
    dut.write_fb_actual_i(0xFFFF00000000);
    dut.write_fb_valid_i(0b10);
    
    // printf("itr %d fw_conf %d fw_valid 0x%lX pred 0x%lX\n", conf_count + 2, dut.read_pred_conf_o(false) & (conf_count-1) , dut.read_pred_valid_o(false), dut.read_pred_result_o(false));
    
    dut.final();

    return 0;
}

void build_confidence(Baseline_top_tb & dut, uint64_t pc, uint64_t fb_value, int P_CONF_WIDTH) {
    int cycle = 0;
    // printf("pc 0x%lX\n", pc);
    do {
        dut.write_fw_pc_i(pc);
        dut.write_fw_valid_i(0b11);
        
        dut.tick();
        
        dut.write_fb_pc_i(pc);
        dut.write_fb_mispredict_i(dut.read_pred_result_o(false) != fb_value);
        dut.write_fb_actual_i(fb_value);
        dut.write_fb_valid_i(0b11);
        dut.write_fb_conf_i(dut.read_pred_conf_o(false));
        cycle++;
    } while((dut.read_pred_conf_o(false) & (1<<P_CONF_WIDTH | 1<<(2*P_CONF_WIDTH+1))) == 0);
    printf("INFO: conflict test confidence high in %d cycles.\n", cycle);
}