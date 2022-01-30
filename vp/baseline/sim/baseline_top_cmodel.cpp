
// this is the cmodel file for the baseline (last-value) predictor
// Author: Yuhan Li
// Nov 18, 2021

#include "baseline_top_cmodel.h"
// #include "stdio.h"

Baseline_top_cmodel::Baseline_top_cmodel(int num_pred, int conf_width, int storage_size) { 
    P_NUM_PRED = num_pred;
    P_CONF_WIDTH = conf_width;
    P_STORAGE_SIZE = storage_size;
    
    // assign storage space for value table
    last_value_storage = new int[P_STORAGE_SIZE];
    conf_storage = new uint64_t[P_STORAGE_SIZE];
}

Baseline_top_cmodel::~Baseline_top_cmodel() {
    if(last_value_storage) {
        delete[] last_value_storage;
        last_value_storage = nullptr;
    }
}

void Baseline_top_cmodel::tick() {
    clk_i = 0;
    update_storage();
    generate_prediction();
    clk_i = 1;
    update_storage();
    generate_prediction();
    clk_i = 0;
    update_storage();
    generate_prediction();
}

void Baseline_top_cmodel::generate_prediction() {
    if(P_NUM_PRED == 2) {
        // value table lookup, note that there is a 1 cycle RAM read delay
        unsigned fw_pc_0 = (unsigned)fw_pc_i; // read lower 32 bits of fw_pc_i
        unsigned fw_pc_1 = fw_pc_i >> 32; // read higher 32 bits or fw_pc_i
        uint64_t pred_value_0 = last_value_storage[fw_pc_0 % P_STORAGE_SIZE];
        uint64_t pred_value_1 = last_value_storage[fw_pc_1 % P_STORAGE_SIZE];
        
        // confidence table lookup, 1 cycle delay
        uint64_t pred_conf_0 = conf_storage[fw_pc_0 % P_STORAGE_SIZE];
        uint64_t pred_conf_1 = conf_storage[fw_pc_1 % P_STORAGE_SIZE];
        // determine if pred_conf_0 and pred_conf_1 are saturated
        unsigned pred_conf_sat_0 = (pred_conf_0 == 1<<P_CONF_WIDTH);
        unsigned pred_conf_sat_1 = (pred_conf_1 == 1<<P_CONF_WIDTH);
        
        // compute pred_result_o
        if(clk_i) {
            pred_result_o = (pred_value_1 << 32) | pred_value_0;
        }
        
        // compute pred_conf_o
        if(clk_i) {
            pred_conf_o = (pred_conf_sat_1 << 1) | pred_conf_sat_0;
            // printf("CMODEL: pred_conf_0 0x%lX, pred_conf_1 0x%lX\n", pred_conf_0, pred_conf_1);
        }
        
        // compute pred_pc_o
        if(clk_i) {
            pred_pc_o = fw_pc_i;
            // printf("CMODEL: pc 0x%lX\n", fw_pc_i);
        }
        
        // compute pred_valid_o
        if(clk_i) {
            pred_valid_o = fw_valid_i & 0b11;
        }
    }
    else { // one prediction per cycle
        // value table lookup, note that there is a 1 cycle RAM read delay
        uint64_t pred_value = last_value_storage[fw_pc_i % P_STORAGE_SIZE];

        // confidence table lookup, 1 cycle delay
        uint64_t pred_conf = conf_storage[fw_pc_i % P_STORAGE_SIZE];

        // determine if pred_conf is saturated
        unsigned pred_conf_sat = (pred_conf == (1 << P_CONF_WIDTH));

        // compute pred_result_o
        if(clk_i) {
            pred_result_o = pred_value;
        }
        
        // compute pred_conf_o
        if(clk_i) {
            pred_conf_o = pred_conf_sat;
        }
        
        // compute pred_pc_o
        if(clk_i) {
            pred_pc_o = fw_pc_i;
        }
        
        // compute pred_valid_o
        if(clk_i) {
            pred_valid_o = fw_valid_i & 1;
        }
    }
}

void Baseline_top_cmodel::update_storage() {
    // note the difference of single or dual predictions
    if(P_NUM_PRED == 1) { // single prediction
        // update last value table
        // what happens upon correct prediction? upon misprediction?
        // last_value_storage[fw_pc_0 % P_STORAGE_SIZE] = pred_pc_o; // you should use the feedback interface (fb_*) instead of forward input (fw_*) or prediction output (pred_*)
        if(clk_i) {
            if(fb_valid_i) {
                last_value_storage[fb_pc_i % P_STORAGE_SIZE] = fb_actual_i; 
            }
        }
        
        // update confidence table
        // what happens upon correct prediction? upon misprediction?
        // upon correct prediction, add 1 to the confidence of that PC until saturation
        // upon misprediction, reset confidence count of that PC
        // conf_storage[fw_pc_0 % P_STORAGE_SIZE] = pred_conf_o; // use fb_*
        if(clk_i) {
            uint64_t fb_new_conf = fb_mispredict_i ? 0 : 
                                   conf_storage[fb_pc_i % P_STORAGE_SIZE] + 1 < (1 << P_CONF_WIDTH) ? 
                                   conf_storage[fb_pc_i % P_STORAGE_SIZE] + 1 : (1 << P_CONF_WIDTH);
            if(fb_valid_i) {
                conf_storage[fb_pc_i % P_STORAGE_SIZE] = fb_new_conf;
            }
        }
    }
    else { // dual prediction
        // detect conflicts (when fb_pc_i LSB 32 and fb_pc_i MSB 32 are the same)
        unsigned fb_pc_0            = (unsigned)fb_pc_i; // read lower 32 bits of fb_pc_i
        unsigned fb_pc_1            = fb_pc_i >> 32; // read higher 32 bits or fb_pc_i
        unsigned fb_actual_0        = (unsigned)fb_actual_i;
        unsigned fb_actual_1        = fb_actual_i >> 32;
        unsigned fb_mispredict_0    = (unsigned)fb_mispredict_i; // read lower 32 bits of fb_mispredict_i
        unsigned fb_mispredict_1    = fb_mispredict_i >> 32; // read higher 32 bits or fb_mispredict_i
        unsigned fb_valid_0         = fb_valid_i & 1;
        unsigned fb_valid_1         = (fb_valid_i >> 1) & 1;
        unsigned fb_new_conf_0;
        unsigned fb_new_conf_1;

        bool conflict = (fb_pc_0 == fb_pc_1) && fb_valid_0 && fb_valid_1;
        
        // what happens when conflict?
        if(conflict) {
            bool both_correct = (fb_mispredict_i & 0b11) == 0; // check if fb_mispredict_i is 0
            if(both_correct) {
                // add 2 to confidence table, store one fb_actual_i
                fb_new_conf_0 = conf_storage[fb_pc_0 % P_STORAGE_SIZE] + 2 < (1 << P_CONF_WIDTH) ?
                                conf_storage[fb_pc_0 % P_STORAGE_SIZE] + 2 : (1 << P_CONF_WIDTH); 
                
                if(clk_i) {
                    conf_storage[fb_pc_1 % P_STORAGE_SIZE] = fb_new_conf_0; 
                    last_value_storage[fb_pc_1 % P_STORAGE_SIZE] = fb_actual_0; 
                }
            }
            else {
                // reset confidence counter, store MSB 32 of fb_actual_i
                if(clk_i) {
                    conf_storage[fb_pc_1 % P_STORAGE_SIZE] = 0; 
                    last_value_storage[fb_pc_1 % P_STORAGE_SIZE] = fb_actual_1; 
                }
            }
        }
        else {
            if(clk_i) {
                if(fb_valid_0) {
                    last_value_storage[fb_pc_0 % P_STORAGE_SIZE] = fb_actual_0; 
                    fb_new_conf_0 = fb_mispredict_0 ? 0 : 
                                    conf_storage[fb_pc_0 % P_STORAGE_SIZE] + 1 < (1 << P_CONF_WIDTH) ? 
                                    conf_storage[fb_pc_0 % P_STORAGE_SIZE] + 1 : (1 << P_CONF_WIDTH);
                    conf_storage[fb_pc_0 % P_STORAGE_SIZE] = fb_new_conf_0;
                }
            }

            if(clk_i) {
                if(fb_valid_1) {
                    last_value_storage[fb_pc_1 % P_STORAGE_SIZE] = fb_actual_1; 
                    fb_new_conf_1 = fb_mispredict_1 ? 0 : 
                                    conf_storage[fb_pc_1 % P_STORAGE_SIZE] + 1 < (1 << P_CONF_WIDTH) ? 
                                    conf_storage[fb_pc_1 % P_STORAGE_SIZE] + 1 : (1 << P_CONF_WIDTH);
                    conf_storage[fb_pc_1 % P_STORAGE_SIZE] = fb_new_conf_1;
                }
            }
        }        
    }
}
