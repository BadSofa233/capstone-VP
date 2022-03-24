// this is the RTL for a vtage predictor back, which holds P_NUM_ENTRIES number of entries
// this block controls the bus of the predictor
// NB: baseline shall be in another separate module
// Author: Yuhan Li
// Nov 14, 2021

`default_nettype none

// `ifndef P_BANK
// `define P_BANK 0
// `endif

`ifndef P_NUM_PRED
`define P_NUM_PRED 2
`endif

`ifndef P_NUM_ENTRIES
`define P_NUM_ENTRIES 256
`endif

`ifndef P_CONF_WIDTH
`define P_CONF_WIDTH 8
`endif

`ifndef P_TAG_WIDTH
`define P_TAG_WIDTH 8
`endif

`ifndef P_U_WIDTH
`define P_U_WIDTH 2
`endif

module vtage_bank #(
    parameter P_BANK            = `P_BANK,
    parameter P_NUM_PRED        = `P_NUM_PRED,
    parameter P_NUM_ENTRIES     = `P_NUM_ENTRIES,
    parameter P_CONF_WIDTH      = `P_CONF_WIDTH,
    parameter P_TAG_WIDTH       = `P_TAG_WIDTH,
    parameter P_U_WIDTH         = `P_U_WIDTH,
    localparam LP_INDEX_WIDTH   = $clog2(P_NUM_ENTRIES)
) (
    input  logic clk_i,
    // input  logic clk_ram_i,
    input  logic rst_i,
    
    input  logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]   fw_index_i,
    input  logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]      fw_tag_i,
    input  logic [P_NUM_PRED-1:0]                       fw_valid_i,
    
    output logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]   pred_result_o,
    output logic [P_NUM_PRED-1:0][P_CONF_WIDTH:0]       pred_conf_o,
    output logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]      pred_tag_o,
    output logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]        pred_useful_o,
    output logic [P_NUM_PRED-1:0]                       pred_hit_o,
    
    input  logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]   fb_index_i,         // original index
    input  logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]      fb_tag_i,           // original tag
    output logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]      fb_tag_match_o,     // fb_tag of entry in fb_index matches with 
    output logic [P_NUM_PRED-1:0]                       fb_alloc_avail_o,   // entry of fb_index is available for allocation
    
    input  logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]   ud_index_i,
    input  logic [P_NUM_PRED-1:0]                       ud_incr_conf_i,
    input  logic [P_NUM_PRED-1:0]                       ud_rst_conf_i,
    input  logic [P_NUM_PRED-1:0]                       ud_incr_use_i,
    input  logic [P_NUM_PRED-1:0]                       ud_decr_use_i,
    input  logic [P_NUM_PRED-1:0]                       ud_rst_use_i,
    input  logic [P_NUM_PRED-1:0]                       ud_load_tag_i,
    input  logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]      ud_tag_i,
    input  logic [P_NUM_PRED-1:0]                       ud_load_value_i,
    input  logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]   ud_value_i
);

    logic [P_NUM_ENTRIES-1:0][P_TAG_WIDTH-1:0]      entry_fw_tag;
    logic [P_NUM_ENTRIES-1:0][31:0]                 entry_pred_value;
    logic [P_NUM_ENTRIES-1:0][P_CONF_WIDTH-1:0]     entry_pred_conf;
    logic [P_NUM_ENTRIES-1:0][P_TAG_WIDTH-1:0]      entry_pred_tag;
    logic [P_NUM_ENTRIES-1:0][P_U_WIDTH-1:0]        entry_pred_useful;
    
    logic [P_NUM_ENTRIES-1:0][P_TAG_WIDTH-1:0]      entry_fb_tag;
    logic [P_NUM_ENTRIES-1:0]                       entry_fb_tag_match;
    logic [P_NUM_ENTRIES-1:0]                       entry_fb_alloc_avail;
    
    logic [P_NUM_ENTRIES-1:0]                       entry_ud_incr_conf;
    logic [P_NUM_ENTRIES-1:0]                       entry_ud_rst_conf;
    logic [P_NUM_ENTRIES-1:0]                       entry_ud_incr_use;
    logic [P_NUM_ENTRIES-1:0]                       entry_ud_decr_use;
    logic [P_NUM_ENTRIES-1:0]                       entry_ud_rst_use;
    logic [P_NUM_ENTRIES-1:0]                       entry_ud_load_tag;
    logic [P_NUM_ENTRIES-1:0][P_TAG_WIDTH-1:0]      entry_ud_tag;
    logic [P_NUM_ENTRIES-1:0]                       entry_ud_load_value;
    logic [P_NUM_ENTRIES-1:0][LP_INDEX_WIDTH-1:0]   entry_ud_value;
    
    generate
        for(genvar i = 0; i < P_NUM_ENTRIES; i = i + 1) begin: gen_entries
            vtage_entry #(
                .LP_INDEX_WIDTH(LP_INDEX_WIDTH),
                .P_CONF_WIDTH(P_CONF_WIDTH),
                .P_TAG_WIDTH(P_TAG_WIDTH),
                .P_U_WIDTH(P_U_WIDTH)
            ) entry (
                .clk_i                  (clk_i),
                .rst_i                  (rst_i),
                // .fw_tag_i(entry_fw_tag[i]),
                // .fw_valid_i(1'b1),
                .pred_value_o           (entry_pred_value[i]),
                .pred_conf_o            (entry_pred_conf[i]),
                .pred_tag_o             (entry_pred_tag[i]),
                .pred_useful_o          (entry_pred_useful[i]),
                .fb_tag_i               (entry_fb_tag[i]),
                .fb_tag_match_o         (entry_fb_tag_match[i]),
                .fb_alloc_avail_o       (entry_fb_alloc_avail[i]),
                .ud_incr_conf_i         (entry_ud_incr_conf[i]),
                .ud_rst_conf_i          (entry_ud_rst_conf[i]),
                .ud_incr_use_i          (entry_ud_incr_use[i]),
                .ud_decr_use_i          (entry_ud_decr_use[i]),
                .ud_rst_use_i           (entry_ud_rst_use[i]),
                .ud_load_tag_i          (entry_ud_load_tag[i]),
                .ud_tag_i               (entry_ud_tag[i]),
                .ud_load_value_i        (entry_ud_load_value[i]),
                .ud_value_i             (entry_ud_value[i])
            );
        end
    endgenerate
    
    // prediction selection
    generate
        for(genvar p = 0; p < P_NUM_PRED; p = p + 1) begin: gen_entry_sel
            assign pred_hit_o[p]    = fw_valid_i[p] && entry_pred_tag[fw_index_i[p]] == fw_tag_i[p]; // check if tags match
            assign pred_value_o[p]  = entry_pred_value[fw_index_i[p]];
            assign pred_conf_o[p]   = entry_pred_conf[fw_index_i[p]];
            assign pred_tag_o[p]    = entry_pred_tag[fw_index_i[p]];
            assign pred_useful_o[p] = entry_pred_useful[fw_index_i[p]];
        end
    endgenerate

    // fb input selection
    generate
        always_comb begin
            for(integer p = 0; p < P_NUM_PRED; p = p + 1) begin: gen_fb_in_sel
                assign entry_fb_tag[fb_index_i[p]] = fb_tag_i[p];
            end
        end
    endgenerate
    // fb output selection
    generate
        for(genvar p = 0; p < P_NUM_PRED; p = p + 1) begin: gen_fb_out_sel
            assign fb_tag_match_o   = entry_fb_tag_match[fb_index_i[p]];
            assign fb_alloc_avail_o = entry_fb_alloc_avail[fb_index_i[p]];
        end
    endgenerate

    // update selection
    generate
        always_comb begin
            for(integer i = 0; i < P_NUM_ENTRIES; i = i + 1) begin: gen_ud_in_sel
                for(genvar p = 0; p < P_NUM_PRED; p = p + 1) begin
                    if(ud_index_i[p] == i) begin
                        entry_ud_incr_conf[i]   = ud_incr_conf_i[p];
                        entry_ud_rst_conf[i]    = ud_rst_conf_i[p];
                        entry_ud_incr_use[i]    = ud_incr_use_i[p];
                        entry_ud_decr_use[i]    = ud_decr_use_i[p];
                        entry_ud_rst_use[i]     = ud_rst_use_i[p];
                        entry_ud_load_tag[i]    = ud_load_tag_i[p];
                        entry_ud_tag[i]         = ud_tag_i[p];
                        entry_ud_load_value[i]  = ud_load_value_i[p];
                        entry_ud_value[i]       = ud_value_i[p];
                    end
                    else begin
                        entry_ud_incr_conf[i]   = '0;
                        entry_ud_rst_conf[i]    = '0;
                        entry_ud_incr_use[i]    = '0;
                        entry_ud_decr_use[i]    = '0;
                        entry_ud_rst_use[i]     = '0;
                        entry_ud_load_tag[i]    = '0;
                        entry_ud_tag[i]         = '0;
                        entry_ud_load_value[i]  = '0;
                        entry_ud_value[i]       = '0;
                    end
                end
            end
        end
    endgenerate

endmodule