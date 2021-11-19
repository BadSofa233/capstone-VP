// this is the top-level RTL for the vtage predictor
// Author: Yuhan Li
// Nov 14, 2021

`default_nettype none

`ifndef P_NUM_PRED
`define P_NUM_PRED 2
`endif

`ifndef P_GBH_LENGTH
`define P_GBH_LENGTH 64
`endif

`ifndef P_NUM_ENTRIES
`define P_NUM_ENTRIES 1024
`endif

`ifndef P_CONF_THRES_WIDTH
`define P_CONF_THRES_WIDTH 8
`endif

module vtage_top #(
    parameter   P_NUM_PRED              = `P_NUM_PRED,
    parameter   P_GBH_LENGTH            = `P_GBH_LENGTH,
    parameter   P_NUM_ENTRIES           = `P_NUM_ENTRIES,
    parameter   P_CONF_THRES_WIDTH      = `P_CONF_THRES_WIDTH,
    parameter   P_HASH_LENGTH           = 15
) vtage_top )
    input   logic                                       clk_i,          // main clock
    input   logic                                       rst_i,          // active high reset
    
    // --------
    // debug
    // --------
    output  logic [P_NUM_PRED-1:0] entry_valid_dbgo,
    output  logic [P_NUM_PRED-1:0][31:0] entry_val_dbgo,
    output  logic [P_NUM_PRED-1:0][P_CONF_THRES_WIDTH-1:0]  conf_dbgo,
    // --------
    
    // forward prediction interface signals
    input   logic [P_NUM_PRED-1:0][31:0]                fw_pc_i,            // current instruction address
    input   logic [P_GBH_LENGTH-1:0]                    fw_gbh_i,           // global branch history
    input   logic [P_NUM_PRED-1:0]                      fw_valid_i,         // input valid qualifier
    output  logic [P_NUM_PRED-1:0][31:0]                fw_pred_o,          // prediction result
    output  logic [P_NUM_PRED-1:0]                      fw_pred_valid_o,    // qualifies the prediction result

    // validation interface (feedback) signals
    input   logic [P_NUM_PRED-1:0][31:0]                fb_pc_i,        // address of execution result feedback
    input   logic [P_NUM_PRED-1:0][31:0]                fb_result_i,    // true execution result of the instruction
    input   logic [P_NUM_PRED-1:0]                      fb_valid_i,     // valid qualifier of feedback interface
    input   logic [P_NUM_PRED-1:0]                      fb_mispredict_i // indicates misprediction
)

    logic [P_NUM_ENTRIES-1:0][31:0]                     val_table;      // the table holding prediction values
    logic [P_NUM_ENTRIES-1:0][1:0]                      useful_table;   // the table holding the max usefulness of each entry
    
    logic [P_NUM_PRED-1:0]                               fw_entry_get;
    logic [P_NUM_PRED-1:0][P_HASH_LENGTH-1:0]            fw_entry_value;     // tristate value
    logic [P_NUM_PRED-1:0][P_CONF_THRES_WIDTH-1:0]       fw_entry_conf;      // tristate confidence count
    logic [P_NUM_PRED-1:0][P_HASH_LENGTH-1:0]            fw_entry_tag;       // tristate tag output
    logic [P_NUM_PRED-1:0][1:0]                          fw_entry_useful;    // tristate usefulness output
    logic [P_NUM_PRED-1:0]                               fw_entry_valid;     // 
    
    logic [P_NUM_PRED-1:0]                               fb_entry_incr_conf; // increment confidence count
    logic [P_NUM_PRED-1:0]                               fb_entry_rst_conf;  // reset confidence
    logic [P_NUM_PRED-1:0]                               fb_entry_incr_use;  // increment usefulness
    logic [P_NUM_PRED-1:0]                               fb_entry_decr_use;  // reset usefulness, do we need this?
    logic [P_NUM_PRED-1:0]                               fb_entry_load_tag;  // load new tag
    logic [P_NUM_PRED-1:0][P_HASH_LENGTH-1:0]            fb_entry_tag;       // new tag to be loaded
    logic [P_NUM_PRED-1:0]                               fb_entry_load_value;// load new value
    logic [P_NUM_PRED-1:0][P_HASH_LENGTH-1:0]            fb_entry_value;     // new value to be loaded
    
    vtage_bank #(
    
    ) vtage_bank (
    
    );
    
    generate
        for(genvar i = 0; i < P_NUM_PRED; i = i + 1) begin : gen_prediction
        
        end
    endgenerate
    
    generate
        for(genvar i = 0; i < P_NUM_PRED; i = i + 1) begin : gen_prediction
        
        end
    endgenerate
    
endmodule