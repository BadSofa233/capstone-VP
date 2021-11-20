// this is the top-level RTL for the baseline (last-value) predictor
// Author: Yuhan Li
// Oct 30, 2021

`default_nettype none

`ifndef P_STORAGE_SIZE
`define P_STORAGE_SIZE 2048
`endif

`ifndef P_CONF_THRES_WIDTH
`define P_CONF_THRES_WIDTH 8
`endif

`ifndef P_NUM_PRED
`define P_NUM_PRED 2
`endif

module baseline_top #(
    // input parameters that define widths of interfaces
    // parameters are like template parameters in C++ and 'generic' in VHDL
    // they generalize the block and allow flexible instantiation
    // if a parameter doesn't affect interface widths, use localparam after module declaration 
    parameter   P_STORAGE_SIZE      = `P_STORAGE_SIZE,      // max number of last values the predictor stores, 
                                                            // equals to max number of instructions the predictor can predict at a given time,
                                                            // default to 2048, cannot be greater than 2^P_INDEX_WIDTH

    parameter   P_CONF_THRES_WIDTH  = `P_CONF_THRES_WIDTH,  // produces a valid prediction when this bit is set in the confidence counter
                                                            // i.e. the predictor produces a valid prediction when the 
                                                            // estimated probability of error <= 1/(2^P_CONF_THRES_WIDTH)
                                                            // default to 8
                                                
    parameter   P_NUM_PRED          = `P_NUM_PRED,          // max number of predictions that can be made every cycle

    // localparams are like 'const' in C++. They cannot be modified elsewhere
    localparam  P_INDEX_WIDTH       = $clog2(P_STORAGE_SIZE)// number of LSBs of pc used to index the table
) (
    // define input and output signals here, use type 'logic'
    
    input   logic                                       clk_i,          // main clock
    input   logic                                       rst_i,          // active high reset
    
    // --------
    // debug
    // --------
    output  logic [P_NUM_PRED-1:0] entry_valid_dbgo,
    output  logic [P_NUM_PRED-1:0][31:0] entry_val_dbgo,
    output  logic [P_NUM_PRED-1:0][P_CONF_THRES_WIDTH-1:0]  conf_dbgo,
    // --------
    
    // forward input interface signals
    input   logic [P_NUM_PRED-1:0][31:0]                    fw_pc_i,        // current instruction address
    input   logic [P_NUM_PRED-1:0][31:0]                    fw_valid_i,     // current instruction address valid qualifier
    // forward prediction interface signals
    output  logic [P_NUM_PRED-1:0][31:0]                    pred_pc_o,      // forward input pc delay matched, used for update
    output  logic [P_NUM_PRED-1:0][31:0]                    pred_result_o,  // prediction result
    output  logic [P_NUM_PRED-1:0][P_CONF_THRES_WIDTH-1:0]  pred_conf_o,    // prediction result's confidence, used for update
    output  logic [P_NUM_PRED-1:0]                          pred_valid_o,   // qualifies the prediction result

    // validation interface (feedback) signals
    input   logic [P_NUM_PRED-1:0][31:0]                    fb_pc_i,        // address of execution result feedback
    input   logic [P_NUM_PRED-1:0][31:0]                    fb_actual_i,    // true execution result of the instruction
    input   logic [P_NUM_PRED-1:0]                          fb_mispredict_i,// indicates misprediction
    input   logic [P_NUM_PRED-1:0][P_CONF_THRES_WIDTH-1:0]  fb_conf_i,// indicates misprediction
    input   logic [P_NUM_PRED-1:0]                          fb_valid_i      // valid qualifier of feedback interface
);

    // declare signals and logic here
    logic [P_STORAGE_SIZE-1:0][31:0]                    last_value_storage; // memory for last values
    logic [P_STORAGE_SIZE-1:0][P_CONF_THRES_WIDTH-1:0]  confidence_counter;
    logic [P_STORAGE_SIZE-1:0]                          entry_valid/* verilator public */;        // indicates if the entry is useful

    // the 'initial' block of a Verilog file gets executed once at the start
    initial begin
        $display("RTL INFO: P_STORAGE_SIZE set to %d, P_CONF_THRES_WIDTH set to %d, P_NUM_PRED set to %d", P_STORAGE_SIZE, P_CONF_THRES_WIDTH, P_NUM_PRED);
    end

    // clear entry valid bits
    for(genvar i = 0; i < P_STORAGE_SIZE; i = i + 1) begin
        always @(posedge clk_i) begin
            if(rst_i) begin
                entry_valid[i] <= 1'b0; // 1'b0 means 1 bit (1') binary (b) number 0 (0),
                                        // 32'hABCD means 32 bit hex number ABCD,
                                        // 4'd13 means 4 bit decimal number 13
            end
        end
    end

    // if the signals are specific to parameter, use 'generate' and 'endgenerate'
    // in this case, there is one pred_index, fw_pc_*, validate_index ... for each P_NUM_PRED
    // so you can use 'generate' and for loop to generate signals and logic
    generate 
        for(genvar i = 0; i < P_NUM_PRED; i = i + 1) begin
            // --------------------------------------------------------------------------------
            // forward data path signals (gives predictions)
            // --------------------------------------------------------------------------------
            logic [P_INDEX_WIDTH-1:0]           pred_index;         // truncated pc, used to index the last-value table
            // logic [31:0]                        fw_pc_d1;           // holds the last pc value to capture pc change 
                                                                       // // fw_pc_d1 stands for fw_pc_i delayed 1 cycle
            // logic [31:0]                        fw_pc_d2; 

            // --------------------------------------------------------------------------------
            // feedback data path signals (updates predictor)
            // --------------------------------------------------------------------------------
            logic [P_INDEX_WIDTH-1:0]           validate_index;     // hashed pc, used to index the last-value table
            logic [31:0]                        fb_result_d1;       // delayed fb_actual_i
            logic                               fb_valid_d1;        // delayed fb_valid_i
            
            // latch PC
            // always (or always_ff) @(posedge clk_i) means that the logic in the block happens every rising edge of the signal clk_i
            // '<=' operator is nonblocking assignment, used in sequential blocks (always_ff and always blocks)
            // always_ff @(posedge clk_i) begin 
                // fw_pc_d1 <= fw_pc_i[i];
                // fw_pc_d2 <= fw_pc_d1;
            // end
            
            // --------------------------------------------------------------------------------
            // forward data path logic (gives predictions)
            // --------------------------------------------------------------------------------
            // first, truncate pc to obtain the index
            always @(posedge clk_i) begin
                pred_index <= fw_pc_i[i][P_INDEX_WIDTH-1:0];
            end

            // second, read storage to find the last value
            always @(posedge clk_i) begin
                if(validate_index == pred_index && fb_valid_d1) begin
                    pred_result_o[i] <= fb_result_d1;
                end
                else begin
                    pred_result_o[i] <= last_value_storage[pred_index];
                end
            end

            // finally, qualify prediction by confidence
            always @(posedge clk_i) begin
                pred_valid_o[i] <= &confidence_counter[pred_index] && entry_valid[pred_index]; 
            end

            // --------------------------------------------------------------------------------
            // feedback data path logic (updates predictor)
            // --------------------------------------------------------------------------------
            // first, truncate pc to obtain the index, delay matching the rest of feedback path for 1 cycle
            always @(posedge clk_i) begin
                validate_index <= fb_pc_i[i][P_INDEX_WIDTH-1:0];
            end
            // delay matching the index hashing
            always @(posedge clk_i) begin
                fb_result_d1 <= fb_actual_i[i];
                fb_valid_d1 <= fb_valid_i[i];
            end

            // second, detect misprediction, determine if the cpnfidence counter should be reset
            assign mispredict_o[i] = fb_valid_d1 && 
                                     (last_value_storage[validate_index] != fb_result_d1) && 
                                     &confidence_counter[pred_index] && 
                                     entry_valid[pred_index]; 

            // third, update confidence counter
            always @(posedge clk_i) begin
                if(mispredict_o[i] || !entry_valid[validate_index]) begin // clear confidence_counter upon misprediction
                    // {P_CONF_THRES_WIDTH{1'b0}} means extend 1'b0 to P_CONF_THRES_WIDTH number of bits
                    confidence_counter[validate_index] <= {P_CONF_THRES_WIDTH{1'b0}};
                    // you can also write "confidence_counter[validate_index] <= 0;" here but this is not the safest way
                end
                else if (fb_valid_d1 && !(&confidence_counter[validate_index])) begin
                    // increment (saturate) confidence counter upon correct prediction
                    confidence_counter[validate_index] <= confidence_counter[validate_index] + 1'b1; 
                end
            end
            
            // finally, store new "last value"
            always @(posedge clk_i) begin
                if(fb_valid_d1) begin
                    last_value_storage[validate_index] <= fb_result_d1;
                    entry_valid[validate_index] <= 1'b1;
                end
            end
            
            
            // --------
            // debug
            // --------
            assign entry_valid_dbgo[i] = entry_valid[validate_index];
            assign entry_val_dbgo[i] = last_value_storage[validate_index];
            assign conf_dbgo[i] = confidence_counter[validate_index];
            // --------
        end
        
    endgenerate
        
    
endmodule
