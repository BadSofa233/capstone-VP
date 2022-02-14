// this is the wrapper for the value predictors
// Author:
// Nov 15 2021

module vp_wrapper #(
    parameter P_ALGORITHM = "VTAGE",    // algorithm to be instantiated
    parameter P_CONF_WIDTH = 8,         // number of confidence counter bits
    parameter P_GBH_LEN = 64,              //Maximum global branch history length to be used 
    parameter P_STORAGE_SIZE = 2048  //Max number of prediction values the predictor stores in the prediction value table 
    // TODO: define more parameters for subblocks
) (
    // TODO: add signals for VTAGE
    input   logic                                           clk_i,          // main clock
    input   logic                                           rst_i,          // active high reset
    input   logic                                           clk_ram_i,      //Memory clock for multiport rams

    // forward input interface signals
    input   logic [1:0][31:1]                               fw_pc_aln_i,    //Fetch address at 1 cycle before the Decode stage (Align stage) 
    input   logic [P_GBH_LEN-1:0]                           fw_gbh_aln_i,   //Global Branch History at 1 cycle before the Decode stage (Align stage) 
    input   logic [1:0]                                     fw_valid_aln_i, //Fetch address qualifier 1 cycle before the Decode stage (Align stage)
    
    // forward prediction interface signals
    output  logic [1:0]                                     pred_conf_d_o,      //Indicates if the value predictor is confident to provide a prediction
    output  logic [1:0]                                     pred_valid_d_o,     //Determines if the prediction output is valid and usable. The same as fw_valid_aln_i delay matched with prediction result output path
    output  logic [1:0][31:1]                               pred_pc_e1_o,       //The PC address associated with the prediction at E1 stage
    output  logic [1:0][31:0]                               pred_result_e1_o,   //The actual prediction result for the instruction address pred_pc_d_o
    output  logic [1:0]                                     pred_conf_e1_o,     //Indicates if the prediction pred_result_e1_o is confident 
    output  logic [1:0]                                     pred_valid_e1_o,    //Indicates if the prediction pred_result_e1_o is usable, delayed from fw_valid_aln_i                                                  

    // prediction enable Input interface signals
    input   logic [1:0]                                     pred_en_e1_i,       //Output enables of the predicted result 
    
    // validation interface (feedback) signals
    input   logic [1:0][31:1]                               fb_pc_i,            // address of execution result feedback
    input   logic [1:0][31:0]                               fb_actual_i,        // true execution result of the instruction
    input   logic [1:0]                                     fb_mispredict_i,    // indicates misprediction
    input   logic [1:0]                                     fb_conf_i,          // indicates if the prediction confidence was saturated
    input   logic [1:0]                                     fb_valid_i          // valid qualifier of feedback interface
);

    generate 

        if(P_ALGORITHM == "VTAGE") begin
            vtage_top #(
                // TODO: input parameters to vtage here...
                .P_NUM_PRED         (2),
                .P_GBH_LENGTH       (P_GBH_LENGTH),
                .P_NUM_ENTRIES      (P_NUM_ENTRIES),
                .P_CONF_THRES_WIDTH (P_CONF_THRES_WIDTH),
                .P_HASH_LENGTH      (P_HASH_LENGTH)
            ) vtage_top (
                // TODO: IO signals here, connect wrapper's IO to VP IO
                .fw_gbh_i           (fw_gbh_i),
                .fw_get_i           (fw_get_i),
                .fw_value_o         (fw_value_o),
                .fw_conf_o          (fw_conf_o),
                .fw_tag_o           (fw_tag_o),
                .fw_useful_o        (fw_useful_o),
                .fw_valid_o         (fw_valid_o),
                .fb_incr_conf_i     (fb_incr_conf_i),
                .fb_rst_conf_i      (fb_rst_conf_i),
                .fb_incr_use_i      (fb_incr_use_i),
                .fb_decr_use_i      (fb_decr_use_i),
                .fb_load_tag_i      (fb_load_tag_i),
                .fb_tag_i           (fb_tag_i),
                .fb_load_value_i    (fb_load_value_i),
                .fb_value_i         (fb_value_i)
            );
        end
        else if(P_ALGORITHM == "BASELINE") begin
        
            logic [1:0][31:0]    pred_result_d;
            logic [1:0][31:1]    pred_pc_d;
            logic [1:0]          pred_conf_d;
            logic [1:0]          pred_valid_d;
            
            baseline_top #(
                .P_STORAGE_SIZE     (P_STORAGE_SIZE),
                .P_CONF_WIDTH       (P_CONF_WIDTH),
                .P_NUM_PRED         (2)
            ) baseline_top (
                .clk_i              (clk_i),
                .clk_ram_i          (clk_ram_i),
                .rst_i              (rst_i),
                .fw_pc_i            (fw_pc_aln_i),
                .fw_valid_i         (fw_valid_aln_i),
                .pred_pc_o          (pred_pc_d),
                .pred_result_o      (pred_result_d),
                .pred_conf_o        (pred_conf_d),
                .pred_valid_o       (pred_valid_d),
                .fb_pc_i            (fb_pc_i),
                .fb_actual_i        (fb_actual_i),
                .fb_mispredict_i    (fb_mispredict_i),
                .fb_conf_i          (fb_conf_i),
                .fb_valid_i         (fb_valid_i)
            );
            
            assign pred_conf_d_o    = pred_conf_d;
            assign pred_valid_d_o   = pred_valid_d;
            
            always @(posedge clk_i) begin // TODO: no need for enable, just go
                // if(|pred_en_e1_i) begin
                    pred_pc_e1_o        <= pred_pc_d;
                    pred_conf_e1_o      <= pred_conf_d;
                    pred_valid_e1_o     <= pred_valid_d;
                    pred_result_e1_o    <= pred_result_d;
                // end
            end
            
        end

    endgenerate

endmodule