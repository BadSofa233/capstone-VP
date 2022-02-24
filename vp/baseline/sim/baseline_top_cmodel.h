// this is the cmodel header file for the baseline (last-value) predictor
// Author: Yuhan Li
// Nov 18, 2021

#ifndef BASELINE_TOP_CMODEL_H
#define BASELINE_TOP_CMODEL_H

#include <inttypes.h>

class Baseline_top_cmodel {
private:
    // -------- parameters -------- //
    int P_NUM_PRED;
    int P_CONF_WIDTH;
    int P_STORAGE_SIZE;
    
    // -------- internal signals -------- //
    int * last_value_storage;
    uint64_t * conf_storage;

public:
    // -------- input signals -------- //
    bool clk_i;          // clock signal, used to determine delay
    bool clk_ram_i;      // clock for value table and confidence table, not used in sim
    bool rst_i;          // active high reset
    
    // forward input interface signals
    // TODO: clean up
    uint64_t                        fw_pc_i;        // current instruction address
    uint64_t                        fw_valid_i;     // current instruction address valid qualifier

    // validation interface (feedback) signals
    uint64_t                        fb_pc_i;         // address of execution result feedback
    uint64_t                        fb_actual_i;     // true execution result of the instruction
    uint64_t                        fb_mispredict_i; // indicates misprediction
    uint64_t                        fb_conf_i;       // indicates if the prediction confidence was saturated
    uint64_t                        fb_valid_i;      // valid qualifier of feedback interface

    // -------- output signals -------- //
    // forward prediction interface signals
    uint64_t                        pred_pc_o;      // forward input pc delay matched, used for update
    uint64_t                        pred_result_o;  // prediction result
    uint64_t                        pred_conf_o;    // prediction result's confidence, 1 if saturated, 0 else
    uint64_t                        pred_valid_o;   // qualifies the prediction result

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