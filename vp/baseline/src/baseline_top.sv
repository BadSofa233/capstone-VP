// this is the top-level RTL for the baseline (last-value) predictor
// Author: Yuhan Li
// Oct 30, 2021

`default_nettype none

`ifndef P_STORAGE_SIZE
`define P_STORAGE_SIZE 2048
`endif

`ifndef P_CONF_WIDTH
`define P_CONF_WIDTH 8
`endif

`ifndef P_NUM_PRED
`define P_NUM_PRED 2
`endif

module baseline_top #(
    // input parameters that define widths of interfaces
    // parameters are like template parameters in C++ and 'generic' in VHDL
    // they generalize the block and allow flexible instantiation
    // if a parameter doesn't affect interface widths, use localparam after module declaration 
    parameter   P_STORAGE_SIZE  = `P_STORAGE_SIZE,      // max number of last values the predictor stores, 
                                                        // equals to max number of instructions the predictor can predict at a given time,
                                                        // default to 2048, cannot be greater than 2^P_INDEX_WIDTH

    parameter   P_CONF_WIDTH    = `P_CONF_WIDTH,        // produces a valid prediction when this bit is set in the confidence counter
                                                        // i.e. the predictor produces a valid prediction when the 
                                                        // estimated probability of error <= 1/(2^P_CONF_WIDTH)
                                                        // default to 8
                                                
    parameter   P_NUM_PRED      = `P_NUM_PRED,          // max number of predictions that can be made every cycle
    parameter   P_PACKED_PRED   = 4,                    // number of results packed in one prediction

    // localparams are like 'const' in C++. They cannot be modified elsewhere
    localparam  P_INDEX_WIDTH   = $clog2(P_STORAGE_SIZE)// number of LSBs of pc used to index the table
) (
    // define input and output signals here, use type 'logic'
    
    // TB_GEN_DEF CLOCK clk_i
    // TB_GEN_DEF RESET rst_i
    input   logic                                       clk_i,          // main clock
    input   logic                                       rst_i,          // active high reset
    
    // --------
    // debug
    // --------
    // --------
    
    // forward input interface signals
    // TB_GEN_DEF INTERFACE fw DIR I CTRL VALID
    input   logic [P_NUM_PRED-1:0][31:0]                    fw_pc_i,        // current instruction address
    input   logic [P_NUM_PRED-1:0]                          fw_valid_i,     // current instruction address valid qualifier
    // forward prediction interface signals
    // TB_GEN_DEF INTERFACE pred DIR O CTRL VALID
    output  logic [P_NUM_PRED-1:0][31:0]                    pred_pc_o,      // forward input pc delay matched, used for update
    output  logic [P_NUM_PRED-1:0][31:0]                    pred_result_o,  // prediction result
    output  logic [P_NUM_PRED-1:0]                          pred_conf_o,    // prediction result's confidence, 1 if saturated, 0 else
    output  logic [P_NUM_PRED-1:0]                          pred_valid_o,   // qualifies the prediction result

    // validation interface (feedback) signals
    // TB_GEN_DEF INTERFACE fb DIR I CTRL VALID
    input   logic [P_NUM_PRED-1:0][31:0]                    fb_pc_i,        // address of execution result feedback
    input   logic [P_NUM_PRED-1:0][31:0]                    fb_actual_i,    // true execution result of the instruction
    input   logic [P_NUM_PRED-1:0]                          fb_mispredict_i,// indicates misprediction
    input   logic [P_NUM_PRED-1:0]                          fb_conf_i,      // indicates if the prediction confidence was saturated
    input   logic [P_NUM_PRED-1:0]                          fb_valid_i      // valid qualifier of feedback interface
);

    // declare signals and logic here
    logic [P_STORAGE_SIZE-1:0][31:0]                        value_table; // memory for last values
    logic [P_STORAGE_SIZE-1:0][P_CONF_WIDTH-1:0]            confidence_table;
    
    logic [P_NUM_PRED-1:0]                                  fb_wen;
    logic [P_NUM_PRED-1:0]                                  fb_conf_incr;
    logic                                                   fb_conf_add2;
    logic [P_NUM_PRED-1:0]                                  fb_conf_reset;
    
    logic [P_NUM_PRED-1:0][P_CONF_WIDTH-1:0]                fb_old_conf;
    logic [P_NUM_PRED-1:0][P_CONF_WIDTH-1:0]                fb_new_conf;
    

    // the 'initial' block of a Verilog file gets executed once at the start
    initial begin
        $display("RTL INFO: P_STORAGE_SIZE set to %d, P_CONF_WIDTH set to %d, P_NUM_PRED set to %d", P_STORAGE_SIZE, P_CONF_WIDTH, P_NUM_PRED);
    end

    // delay matching input PC and valid
    // TODO: support variable delay matching
    always @(posedge clk_i) begin
        pred_pc_o    <= fw_pc_i;
        pred_valid_o <= fw_valid_i;
    end

    // if the signals are specific to parameter, use 'generate' and 'endgenerate'
    // in this case, there is one pred_index, fw_pc_*, validate_index ... for each P_NUM_PRED
    // so you can use 'generate' and for loop to generate signals and logic
    generate 
        
        // value table
        for(genvar p = 0; p < P_NUM_PRED; p = p + 1) begin
            // read
            always @(posedge clk_i) begin
                if(fw_valid_i[p]) begin
                    pred_result_o[p] <= value_table[fw_pc_i[p][P_INDEX_WIDTH-1:0]];
                end
            end
            // write
            always @(posedge clk_i) begin
                if(fb_wen[p]) begin
                    value_table[fb_pc_i[p][P_INDEX_WIDTH-1:0]] <= fb_actual_i[p];
                end
            end
        end
        
        // confidence unit
        for(genvar p = 0; p < P_NUM_PRED; p = p + 1) begin
            // read confidenc table
            always @(posedge clk_i) begin
                if(fw_valid_i[p]) begin
                    fb_old_conf[p] <= confidence_table[fw_pc_i[p][P_INDEX_WIDTH-1:0]];
                end
            end
            // take MSB for pred_conf_o
            assign pred_conf_o[p] = fb_old_conf[p][P_CONF_WIDTH-1];
            // generate new confidence
            assign fb_new_conf[p] = fb_conf_incr[p]  ? fb_old_conf[p] + 1'b1 : 
                                    fb_conf_add2     ? fb_old_conf[p] + P_CONF_WIDTH'(2) : 
                                    fb_conf_reset[p] ? {P_CONF_WIDTH{1'b0}} : fb_old_conf[p];
            // write to confidence table
            always @(posedge clk_i) begin
                if(fb_wen[p]) begin
                    confidence_table[fb_pc_i[p][P_INDEX_WIDTH-1:0]] <= fb_new_conf[p];
                end
            end
        end
        
        // update control unit
        if(P_NUM_PRED == 1) begin
            assign fb_wen        = rst_i ? 1'b0 : fb_valid_i;
            assign fb_conf_add2  = 1'b0;                                            // not possible when P_NUM_PRED == 1
            assign fb_conf_incr  = rst_i ? 1'b0 : (~fb_mispredict_i && ~fb_conf_i); // increment confidence only when no saturation && no misprediction
            assign fb_conf_reset = rst_i ? 1'b0 : fb_mispredict_i;                 // reset confidence when there's misprediction
        end
        else if (P_NUM_PRED == 2) begin 
            logic fb_conflict;
            logic fb_both_correct;
            
            assign fb_conflict     = (fb_pc_i[0] == fb_pc_i[1]) && (&fb_valid_i);                   // when two update PCs match, conflict happens
            assign fb_both_correct = ~(|fb_mispredict_i);                                           // when no misprediction (fb_mispredict_i == 0), two predictions are both correct
            assign fb_wen          = (rst_i | ~(|fb_valid_i)) ? 2'b00 : fb_conflict ? 2'b10 : fb_valid_i;              // when conflict, merge fb[0] to fb[1], only write fb[1]
            assign fb_conf_add2    = rst_i ? 1'b0 : fb_conflict && fb_both_correct;                 // if the predictions were both correct, add 2 to confidence counter
            assign fb_conf_incr    = rst_i || fb_conflict ? 2'b00 :(~fb_mispredict_i & ~fb_conf_i); // increment confidence only when: // no conflict && no saturation && no misprediction
            assign fb_conf_reset   = rst_i                           ? 2'b00 :                      // reset confidence when there's misprediction or
                                     fb_conflict && !fb_both_correct ? 2'b10 : fb_mispredict_i;     // there's conflict and not both correct (there must be at least one wrong)
        end

        // --------
        // debug
        // --------
        // --------
    
    endgenerate
        
    
endmodule
