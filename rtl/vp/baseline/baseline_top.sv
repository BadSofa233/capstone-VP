// this is the top-level RTL for the baseline (last-value) predictor
// Author: Yuhan Li
// Oct 30, 2021

module baseline_top #(
    // input parameters that define widths of interfaces
    // parameters are like template parameters in C++ and 'generic' in VHDL
    // they generalize the block and allow flexible instantiation
    // if a parameter doesn't affect interface widths, use localparam after module declaration 
    parameter   P_STORAGE_SIZE          = 2048, // max number of last values the predictor stores, 
                                                // equals to max number of instructions the predictor can predict at a given time,
                                                // default to 2048, cannot be greater than 2^P_INDEX_WIDTH

    parameter   P_CONF_THRES_WIDTH      = 8,    // produces a valid prediction when this bit is set in the confidence counter
                                                // i.e. the predictor produces a valid prediction when the 
                                                // estimated probability of error <= 1/(2^P_CONF_THRES_WIDTH)
                                                // default to 8
                                                
    parameter   P_NUM_PRED              = 2,    // max number of predictions that can be made every cycle

    // localparams are like 'const' in C++. They cannot be modified elsewhere
    localparam  P_INDEX_WIDTH           = $clog2(P_STORAGE_SIZE)  // number of LSBs of pc used to index the table
) (
    // define input and output signals here, use type 'logic'
    
    input   logic                                       clk_i,          // main clock
    input   logic                                       rst_i,          // active high reset
    
    // forward data path
    input   logic [P_NUM_PRED-1:0][31:0]                pc_fw_i,        // current instruction address
    output  logic [P_NUM_PRED-1:0][31:0]                pred_o,         // prediction result
    output  logic [P_NUM_PRED-1:0]                      pred_valid_o,   // qualifies the prediction result

    // feedback data path
    input   logic [P_NUM_PRED-1:0][31:0]                pc_fb_i,        // address of execution result feedback
    input   logic [P_NUM_PRED-1:0][31:0]                result_fb_i,    // true execution result of the instruction
    input   logic [P_NUM_PRED-1:0]                      fb_valid_i      // valid qualifier of feedback interface
);

    // declare signals

    logic [P_NUM_PRED-1:0][31:0]                        pc_d1;              // holds the last pc value to capture pc change 
                                                                            // pc_d1 stands for pc delayed 1 cycle
    logic [P_NUM_PRED-1:0][31:0]                        pc_d2; 

    // forward prediction path
    logic [P_NUM_PRED-1:0][P_INDEX_WIDTH-1:0]           pred_index;         // hashed pc, used to index the last-value table
    logic [P_STORAGE_SIZE-1:0][31:0]                    last_value_storage; // memory for last values
    logic [P_STORAGE_SIZE-1:0][P_CONF_THRES_WIDTH-1:0]  confidence_counter;

    // feedback update path
    logic [P_NUM_PRED-1:0][P_INDEX_WIDTH-1:0]           validate_index;     // hashed pc, used to index the last-value table
    logic [P_NUM_PRED-1:0]                              mispredict;         // indecates misprediction

    // define logic


    // forward prediction path

    // latch PC
    // always (or always_ff) @(posedge clk_i) means that the logic in the block happens every rising edge of the signal clk_i
    // '<=' operator is nonblocking assignment, used in sequential blocks (always_ff and always blocks)
    always_ff @(posedge clk_i) begin 
        pc_d1 <= pc_fw_i;
        pc_d2 <= pc_d1;
    end

    for(genvar i = 0; i < P_NUM_PRED; i = i + 1) begin

        // first, hash pc to obtain the index
        always @(posedge clk_i) begin
            // this is just dummy logic
            pred_index[i] <= pc_fw_i[i][P_INDEX_WIDTH-1:0]; // TODO: implement hashing
        end

        // second, read storage to find the last value
        always @(posedge clk_i) begin
            if(pc_d2[i] != pc_d1[i]) begin
                pred_o[i] <= last_value_storage[pred_index];
                // TODO: add feedback data forwarding
            end
        end

        // finally, qualify prediction by confidence
        always @(posedge clk_i) begin
            pred_valid_o[i] <= &confidence_counter[pred_index];
        end

    end

    // feedback update path
    for(genvar i = 0; i < P_NUM_PRED; i = i + 1) begin

        // first, hash pc to obtain the index
        always @(posedge clk_i) begin
            // this is just dummy logic here
            validate_index[i] <= pc_fb_i[i][P_INDEX_WIDTH-1:0]; // TODO: implement hashing
        end

        // second, detect misprediction
        assign mispredict[i] = fb_valid_i[i] && (last_value_storage[validate_index[i]] == result_fb_i[i]);

        // third, update confidence counter
        always @(posedge clk_i) begin
            if(mispredict[i]) begin // clear confidence_counter upon misprediction
                // {P_CONF_THRES_WIDTH{1'b0}} means extend 1'b0 to P_CONF_THRES_WIDTH number of bits
                confidence_counter[validate_index[i]] <= {P_CONF_THRES_WIDTH{1'b0}};
                // you can also write "confidence_counter[validate_index] <= 0;" here but this is not the safest way
            end
            else if (fb_valid_i[i]) begin
                confidence_counter[validate_index[i]] <= confidence_counter[validate_index[i]] + 1'b1; 
                // 1'b1 means 1 bit (1') binary (b) number 1 (1),
                // 32'hABCD means 32 bit hex number ABCD,
                // 4'd13 means 4 bit decimal number 13
            end
        end
        
        // finally, store new "last value"
        always @(posedge clk_i) begin
            if(fb_valid_i[i]) begin
                last_value_storage[validate_index[i]] <= result_fb_i[i];
            end
        end

    end

endmodule
