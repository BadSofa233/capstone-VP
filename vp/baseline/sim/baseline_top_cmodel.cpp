// this is the cmodel file for the baseline (last-value) predictor
// Author: Yuhan Li
// Nov 18, 2021

#include "baseline_top_cmodel.h"

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
    generate_prediction();
    update_storage();
    clk_i = 1;
    generate_prediction();
    update_storage();
    clk_i = 0;
    generate_prediction();
    update_storage();
}

void Baseline_top_cmodel::generate_prediction() {
    if(P_NUM_PRED == 2) {
        // value table lookup, note that there is a 1 cycle RAM read delay
        unsigned fw_pc_0 = (unsigned)fw_pc_i; // read lower 32 bits of fw_pc_i
        unsigned fw_pc_1 = fw_pc_i >> 32; // read higher 32 bits or fw_pc_i
        uint64_t pred_value_0 = last_value_storage[fw_pc_0];
        uint64_t pred_value_1 = last_value_storage[fw_pc_1];
        
        // confidence table lookup, 1 cycle delay
        uint64_t pred_conf_0 = conf_storage[fw_pc_0];
        uint64_t pred_conf_1 = conf_storage[fw_pc_1];
        // determine if pred_conf_0 and pred_conf_1 are saturated
        unsigned pred_conf_0 = (pred_conf_0 == (1<<P_CONF_WIDTH)-1);
        unsigned pred_conf_1 = (pred_conf_1 == (1<<P_CONF_WIDTH)-1);
        
        // compute pred_result_o
        if(clk_i) {
            pred_result_o = (pred_value_1 << 32) | pred_value_0;
        }
        
        // compute pred_conf_o
        if(clk_i) {
            pred_conf_o = (pre_conf_1<<1) | pre_conf_0;
        }
        
        // compute pred_pc_o
        if(clk_i) {
            pred_pc_o = fw_pc_i;
        }
        
        // compute pred_valid_o
        if(clk_i) {
            pred_valid_o = fw_valid_i;
        }
    }
    else { // one prediction per cycle
        
    }
}

void Baseline_top_cmodel::update_storage() {
    // note the difference of single or dual predictions
    if(P_NUM_PRED == 1) { // single prediction
        // update last value table
        // what happens upon correct prediction? upon misprediction?
        
        
        
        // update confidence table
        // what happens upon correct prediction? upon misprediction?
        
    }
    else { // dual prediction
        // detect conflicts
        
        // what happens when conflict?
        
        
        // what happens when no conflict?
        
        
        // update last value table
        // take misprediction and conflict into account
        
        
        
        // update confidence table
        // take misprediction and conflict into account
        
    }
}