// this is the RTL for a single vtage predictor entry
// Author: Yuhan Li
// Nov 14, 2021

`ifndef P_CONF_WIDTH
`define P_CONF_WIDTH 8
`endif

`ifndef P_TAG_WIDTH
`define P_TAG_WIDTH 8
`endif

`ifndef P_U_WIDTH
`define P_U_WIDTH 2
`endif

// module vtage_entry #(
    // parameter   P_NUM_PRED              = `P_NUM_PRED,
    // parameter   P_GBH_LENGTH            = `P_GBH_LENGTH,
    // parameter   P_NUM_ENTRIES           = `P_NUM_ENTRIES,
    // parameter   P_CONF_THRES_WIDTH      = `P_CONF_THRES_WIDTH,
    // parameter   P_HASH_LENGTH           = 15
// ) (
    // input  logic [P_NUM_PRED-1:0]                               fw_get_i,
    // output logic [P_NUM_PRED-1:0][P_HASH_LENGTH-1:0]            fw_value_o,     // tristate value
    // output logic [P_NUM_PRED-1:0][P_CONF_THRES_WIDTH-1:0]       fw_conf_o,      // tristate confidence count
    // output logic [P_NUM_PRED-1:0][P_HASH_LENGTH-1:0]            fw_tag_o,       // tristate tag output
    // output logic [P_NUM_PRED-1:0][1:0]                          fw_useful_o,    // tristate usefulness output
    // output logic [P_NUM_PRED-1:0]                               fw_valid_o,     // 
    
    // input  logic [P_NUM_PRED-1:0]                               fb_incr_conf_i, // increment confidence count
    // input  logic [P_NUM_PRED-1:0]                               fb_rst_conf_i,  // reset confidence
    // input  logic [P_NUM_PRED-1:0]                               fb_incr_use_i,  // increment usefulness
    // input  logic [P_NUM_PRED-1:0]                               fb_decr_use_i,  // reset usefulness, do we need this?
    // input  logic [P_NUM_PRED-1:0]                               fb_load_tag_i,  // load new tag
    // input  logic [P_NUM_PRED-1:0][P_HASH_LENGTH-1:0]            fb_tag_i,       // new tag to be loaded
    // input  logic [P_NUM_PRED-1:0]                               fb_load_value_i,// load new value
    // input  logic [P_NUM_PRED-1:0][P_HASH_LENGTH-1:0]            fb_value_i      // new value to be loaded
// );


// endmodule

typedef struct packed {
    logic [P_CONF_WIDTH:0]      conf;
    logic [P_TAG_WIDTH-1:0]     tag;
    logic [P_U_WIDTH-1:0]       u;
    logic [31:0]                value;
} vtage_entry_t;
