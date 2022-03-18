// this is the RTL for a vtage predictor back, which holds P_NUM_ENTRIES number of entries
// this block controls the bus of the predictor
// Author: Yuhan Li
// Nov 14, 2021

`default_nettype none

`ifndef P_BANK
`define P_BANK 0
`endif

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
    parameter P_BANK = `P_BANK,
    parameter P_NUM_PRED = `P_NUM_PRED,
    parameter P_NUM_ENTRIES = `P_NUM_ENTRIES,
    parameter P_CONF_WIDTH = `P_CONF_WIDTH,
    parameter P_TAG_WIDTH = `P_TAG_WIDTH,
    parameter P_U_WIDTH = `P_U_WIDTH,
    localparam  LP_INDEX_WIDTH          = $clog2(P_NUM_ENTRIES)
) (
    input logic clk_i,
    input logic clk_ram_i,
    input logic rst_i,
    
    input logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0] fw_index_i,
    input logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0] fw_tag_i,
    input logic [P_NUM_PRED-1:0] fw_valid_i,
    
    output logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0] pred_result_o,
    output logic [P_NUM_PRED-1:0][P_CONF_WIDTH:0] pred_conf_o,
    output logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0] pred_tag_o,
    output logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0] pred_useful_o,
    output logic [P_NUM_PRED-1:0] pred_hit_o,
    
    input   logic [P_NUM_PRED-1:0][31:0]                fb_actual_i,        // true execution result of the instruction
    output  logic [P_NUM_PRED-1:0][P_CONF_WIDTH:0]      fb_conf_i,          // original confidence fb
    output  logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  fb_index_i,         // original tag
    output  logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     fb_tag_i,           // original tag
    output  logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]       fb_useful_i,        // original usefulness
    input   logic [P_NUM_PRED-1:0]                      fb_mispredict_i,    // indicates misprediction
    input   logic [P_NUM_PRED-1:0]                      fb_valid_i          // valid qualifier of feedback interface
);

    vtage_entry_t [P_NUM_PRED-1:0] vtage_fw_entry;
    vtage_entry_t [P_NUM_PRED-1:0] vtage_fb_entry;
    
    // vtage table
    multiport_ram #(
        .P_MEM_DEPTH        (P_NUM_ENTRIES),
        .P_MEM_WIDTH        ($bits(vtage_entry_t)),
        .P_SIM              (`P_SIM),
        .P_METHOD           ("MULTIPUMPED")
    ) vtage_table (
        .clk_i              (clk_i),
        .clk_mp_i           (clk_ram_i),
        
        .rda_addr_i         (fw_index_i[0]),
        .rda_data_o         (vtage_fw_entry[0]),
        
        .rdb_addr_i         (fw_index_i[1]),
        .rdb_data_o         (vtage_fw_entry[1]),
        
        .wra_addr_i         (fb_index_i[0]),
        .wra_data_i         (vtage_fb_entry[0]),
        .wra_valid_i        (fb_wen[0]),
        
        .wrb_addr_i         (fb_index_i[1]),
        .wrb_data_i         (vtage_fb_entry[1]),
        .wrb_valid_i        (fb_wen[1])
    );

    generate
        if(P_BANK == 0) begin: gen_lvp_pred
            for(int i = 0; i < P_NUM_PRED; i = i + 1) begin
                assign pred_hit_o[i]        = 1'b1;
                assign pred_result_o[i]     = vtage_fw_entry[i].value;
                assign pred_conf_o[i]       = vtage_fw_entry[i].conf;
                assign pred_tag_o[i]        = '0;
                assign pred_useful_o[i]     = '0;
            end
        end
        else begin: gen_vtage_pred
            logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0] fw_tag_d1;
            always_ff @(posedge clk_i) begin
                fw_tag_d1 <= fw_tag_i;
            end
            for(int i = 0; i < P_NUM_PRED; i = i + 1) begin
                assign pred_hit_o[i]        = fw_tag_d1[i] == vtage_fw_entry[i].tag;
                assign pred_result_o[i]     = vtage_fw_entry[i].value;
                assign pred_conf_o[i]       = vtage_fw_entry[i].conf;
                assign pred_tag_o[i]        = vtage_fw_entry[i].tag;
                assign pred_useful_o[i]     = vtage_fw_entry[i].u;
            end
        end
    endgenerate

    generate
        if(P_BANK == 0) begin: gen_lvp_fb
        end
        else begin: gen_vtage_fb
        end
    endgenerate

endmodule