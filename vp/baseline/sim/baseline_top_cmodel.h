// this is the cmodel header file for the baseline (last-value) predictor
// Author: Yuhan Li
// Nov 18, 2021

#ifndef BASELINE_TOP_CMODEL_H
#define BASELINE_TOP_CMODEL_H

#include "ap_int.h"

class Baseline_top_cmodel {
private:
    // -------- parameters -------- //
    int P_NUM_PRED;
    int P_CONF_WIDTH;
    int P_STORAGE_SIZE;
    
    // -------- internal signals -------- //
    int * last_value_storage;
    ap_int<DEF_CONF_WIDTH> * conf_storage;

public:
    // -------- input signals -------- //
    bool clk_i;          // TODO: do we need this?
    bool rst_i;          // active high reset
    
    // forward input interface signals
    ap_int<DEF_NUM_PRED*31>           fw_pc_i;        // current instruction address
    ap_int<DEF_NUM_PRED>              fw_valid_i;     // current instruction address valid qualifier

    // validation interface (feedback) signals
    ap_int<DEF_NUM_PRED*31>           fb_pc_i;        // address of execution result feedback
    ap_int<DEF_NUM_PRED*31>           fb_actual_i;    // true execution result of the instruction
    ap_int<DEF_NUM_PRED>              fb_mispredict_i;// indicates misprediction
    ap_int<DEF_NUM_PRED>              fb_conf_i;      // indicates if the prediction confidence was saturated
    ap_int<DEF_NUM_PRED>              fb_valid_i;      // valid qualifier of feedback interface

    // -------- output signals -------- //
    // forward prediction interface signals
    ap_int<DEF_NUM_PRED*31>           pred_pc_o;      // forward input pc delay matched, used for update
    ap_int<DEF_NUM_PRED*31>           pred_result_o;  // prediction result
    ap_int<DEF_NUM_PRED>              pred_conf_o;    // prediction result's confidence, 1 if saturated, 0 else
    ap_int<DEF_NUM_PRED>              pred_valid_o;   // qualifies the prediction result

private:
    // -------- internal functions -------- //
    void generate_prediction(); // forward prediction
    void update_storage(); // feedback update

public:
    // we need to instantiate the CMODEL with the same parameters as the DUT
    Baseline_top_cmodel(int num_pred, int conf_width, int storage_size);
    ~Baseline_top_cmodel();
    
    void tick(); // update state
};

#endif