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

module vtage_entry #(
    parameter   LP_INDEX_WIDTH          = 8,
    parameter   P_CONF_WIDTH            = `P_CONF_WIDTH,
    parameter   P_TAG_WIDTH             = `P_TAG_WIDTH,
    parameter   P_U_WIDTH               = `P_U_WIDTH
) (
    input  logic                        clk_i,
    input  logic                        rst_i,
    
    // input  logic [P_TAG_WIDTH-1:0]      fw_tag_i,
    // input  logic                        fw_valid_i,
    
    output logic [LP_INDEX_WIDTH-1:0]   pred_value_o,
    output logic [P_CONF_WIDTH:0]       pred_conf_o,
    output logic [P_TAG_WIDTH-1:0]      pred_tag_o,
    output logic [P_U_WIDTH-1:0]        pred_useful_o,
    
    input  logic [P_TAG_WIDTH-1:0]      fb_tag_i,
    output logic                        fb_tag_match_o,
    output logic                        fb_alloc_avail_o,
    
    input  logic                        ud_incr_conf_i,
    input  logic                        ud_rst_conf_i,
    input  logic                        ud_incr_use_i,
    input  logic                        ud_decr_use_i,
    input  logic                        ud_rst_use_i,
    input  logic                        ud_load_tag_i,
    input  logic [P_TAG_WIDTH-1:0]      ud_tag_i,
    input  logic                        ud_load_value_i,
    input  logic [LP_INDEX_WIDTH-1:0]   ud_value_i
);

    logic [LP_INDEX_WIDTH-1:0]      value;
    logic [P_CONF_WIDTH:0]          conf;
    logic [P_TAG_WIDTH-1:0]         tag;
    logic [P_U_WIDTH-1:0]           useful;
    
    initial begin
        conf    = '0;
        tag     = '0;
        useful  = '0;
    end
    
    // pred value output
    assign pred_value_o     = value;
    assign pred_conf_o      = conf;
    assign pred_tag_o       = tag;
    assign pred_useful_o    = useful;
    
    // feedback info
    assign fb_tag_match_o   = fb_tag_i == tag;
    assign fb_alloc_avail_o = useful == '0;
    
    // value update
    always @(posedge clk_i) begin
        if(ud_load_value_i) begin
            value <= ud_value_i;
        end
    end
    
    // tag update
    always @(posedge clk_i) begin
        if(ud_load_tag_i) begin
            tag <= ud_tag_i;
        end
    end
    
    // conf update
    always @(posedge clk_i) begin
        if(rst_i | ud_rst_conf_i) begin
            conf <= '0;
        end
        else if(ud_incr_conf_i & ~conf[P_CONF_WIDTH]) begin // increment and saturate
            conf <= conf + 1'b1;
        end
    end
    
    // useful update
    always @(posedge clk_i) begin
        if(rst_i | ud_rst_use_i) begin
            useful <= '0;
        end
        else if(ud_incr_use_i & ~(&useful)) begin // increment and saturate to all 1s
            useful <= useful + 1'b1;
        end
        else if(ud_decr_use_i & (|useful)) begin // decrement and saturate to 0
            useful <= useful - 1'b1;
        end
    end
    
endmodule

// typedef struct packed {
    // logic [P_CONF_WIDTH:0]      conf;
    // logic [P_TAG_WIDTH-1:0]     tag;
    // logic [P_U_WIDTH-1:0]       u;
    // logic [31:0]                value;
// } vtage_entry_t;
