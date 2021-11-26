// this is the wrapper for the value predictors
// Author:
// Nov 15 2021

module vp_wrapper #(
    parameter P_ALGORITHM = "VTAGE",    // algorithm to be instantiated
    parameter P_NUM_PRED = 2,           // number of concurrent predictions
    parameter P_CONF_WIDTH = 8,         // number of confidence counter bits
    parameter P_GBH_LEN = 32
    // TODO: define more parameters for subblocks
) (
    // TODO: add signals for VTAGE
    input   logic                                           clk_i,          // main clock
    input   logic                                           rst_i,          // active high reset

    // forward input interface signals
    input   logic [P_NUM_PRED-1:0][31:0]                    fw_pc_i,        // current instruction address
    input   logic [P_NUM_PRED-1:0]                          fw_valid_i,     // current instruction address valid qualifier
    input   logic [P_GBH_LEN-1:0]                           fw_gbh_i,       // input global branch history
    // forward prediction interface signals
    output  logic [P_NUM_PRED-1:0][31:0]                    pred_pc_o,      // forward input pc delay matched, used for update
    output  logic [P_NUM_PRED-1:0][31:0]                    pred_result_o,  // prediction result
    output  logic [P_NUM_PRED-1:0]                          pred_conf_o,    // prediction result's confidence, 1 if saturated, 0 else
    output  logic [P_NUM_PRED-1:0]                          pred_valid_o,   // qualifies the prediction result

    // validation interface (feedback) signals
    input   logic [P_NUM_PRED-1:0][31:0]                    fb_pc_i,        // address of execution result feedback
    input   logic [P_NUM_PRED-1:0][31:0]                    fb_actual_i,    // true execution result of the instruction
    input   logic [P_NUM_PRED-1:0]                          fb_mispredict_i,// indicates misprediction
    input   logic [P_NUM_PRED-1:0]                          fb_conf_i,      // indicates if the prediction confidence was saturated
    input   logic [P_NUM_PRED-1:0]                          fb_valid_i      // valid qualifier of feedback interface
);

// define logic and signals here
// logic a; // it's a signals
// logic b;

    generate 

        if(P_ALGORITHM == "VTAGE") begin
            vtage_top #(
                // TODO: input parameters to vtage here...
            ) vtage_top (
                // TODO: IO signals here, connect wrapper's IO to VP IO
                // .fw_pc_i(a),
                // .fw_gbh_i(b),
                // ...
            );
        end
        else if(P_ALGORITHM == "2D_STRIDE") begin
        
        end
        else if(P_ALGORITHM == "DFCM") begin
        
        end
        else if(P_ALGORITHM == "BASELINE") begin
            baseline_top #(
                // TODO: input parameters to vtage here...
                .P_STORAGE_SIZE(P_STORAGE_SIZE),
                .P_CONF_WIDTH(P_CONF_WIDTH),
                .P_NUM_PRED(P_NUM_PRED)
            ) baseline_top (
                // TODO: IO signals here
                .fw_pc_i(fw_pc_i),
                .fw_valid_i(fw_valid_i),
                .pred_pc_o(pred_pc_o),
                .pred_result_o(pred_result_o),
                // ...
                .fw_pc_i(),
                .fw_pc_i(),
                .fw_pc_i(),
                .fw_pc_i(),
                .fw_pc_i(),
                .fw_pc_i(),
                .fw_pc_i()
            );
        end

    endgenerate

endmodule