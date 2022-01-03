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
    generate_prediction();
    update_storage();
}

void Baseline_top_cmodel::generate_prediction() {
    // value table lookup, note that there is a 1 cycle RAM read delay 
    
    
    // confidence table lookup, 1 cycle delay
    
    
    // compute fw_pred_o
    
    // compute fw_conf_o
    
    // compute fw_pc_o
    
    // compute fw_valid_o
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