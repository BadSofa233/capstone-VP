// this is RTL for the vtage update controller
// Author: Yuhan Li
// March 24, 2022

module vtage_update_unit #(
    parameter   P_NUM_PRED              = `P_NUM_PRED,
    parameter   P_NUM_BANK              = `P_NUM_BANK,
    parameter   P_NUM_ENTRIES           = `P_NUM_ENTRIES,
    parameter   P_CONF_WIDTH            = `P_CONF_WIDTH,
    parameter   P_TAG_WIDTH             = `P_TAG_WIDTH,
    parameter   P_U_WIDTH               = `P_U_WIDTH,
    localparam  LP_INDEX_WIDTH          = $clog2(P_NUM_ENTRIES),
    localparam  LP_BANK_SEL_WIDTH       = $clog2(P_NUM_BANK)
) (
    input  logic clk_i,
    input  logic rst_i,
    
    input  logic fb_actual_i,
    input  logic fb_conf_i,
    input  logic fb_bank_i,
    input  logic fb_index_i,
    input  logic fb_tag_i,
    input  logic fb_useful_i,
    input  logic fb_mispredict_i,
    input  logic fb_valid_i,
    
    input  logic bank_fb_match_i,
    input  logic bank_fb_alloc_avail_i,
    
    output logic ud_bank_sel_o,
    output logic ud_incr_conf_o,
    output logic ud_rst_conf_o,
    output logic ud_incr_use_o,
    output logic ud_decr_use_o,
    output logic ud_rst_use_o,
    output logic ud_ct_index_o,
    output logic ud_load_tag_o,
    output logic ud_tag_o,
    output logic ud_load_value_o,
    output logic ud_ct_value_o,
    
    output logic ud_vt_index_o,
    output logic ud_vt_value_o,
    output logic ud_vt_useful_o,
    output logic ud_vt_load_o
)

    logic [P_NUM_PRED-1:0]      fb_match;

    // verify the feedback input still matches
    
    // correct prediction path
    // send increment conf to the original

endmodule