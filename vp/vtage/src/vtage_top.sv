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

`ifndef P_NUM_BANK
`define P_NUM_BANK 4
`endif

`ifndef P_NUM_ENTRIES
`define P_NUM_ENTRIES 1024
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

// TODO: relationship between P_NUM_BANK, LP_INDEX_WIDTH, P_TAG_WIDTH, and P_GBH_LENGTH

module vtage_top #(
    parameter   P_NUM_PRED              = `P_NUM_PRED,
    parameter   P_GBH_LENGTH            = `P_GBH_LENGTH,
    parameter   P_NUM_BANK              = `P_NUM_BANK,
    parameter   P_NUM_ENTRIES           = `P_NUM_ENTRIES,
    parameter   P_CONF_WIDTH            = `P_CONF_WIDTH,
    parameter   P_TAG_WIDTH             = `P_TAG_WIDTH,
    parameter   P_U_WIDTH               = `P_U_WIDTH,
    localparam  LP_INDEX_WIDTH          = $clog2(P_NUM_ENTRIES)
) (
    input   logic                                       clk_i,          // main clock
    input   logic                                       clk_ram_i,          // main clock
    input   logic                                       rst_i,          // active high reset
    
    // --------
    // debug
    // --------
    // output  logic [P_NUM_PRED-1:0] entry_valid_dbgo,
    // output  logic [P_NUM_PRED-1:0][31:0] entry_val_dbgo,
    // output  logic [P_NUM_PRED-1:0][P_CONF_WIDTH-1:0]  conf_dbgo,
    // --------
    
    // forward prediction interface signals
    input   logic [P_NUM_PRED-1:0][31:1]                fw_pc_i,            // current instruction address
    input   logic [P_GBH_LENGTH-1:0]                    fw_gbh_i,           // global branch history
    input   logic [P_NUM_PRED-1:0]                      fw_valid_i,         // input valid qualifier
    
    // prediction output
    // basically the entire two entries
    output  logic [P_NUM_PRED-1:0][31:0]                pred_result_o,      // prediction result value
    output  logic [P_NUM_PRED-1:0][P_CONF_WIDTH:0]      pred_conf_o,        // prediction result confidence
    output  logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  pred_index_o,       // prediction result tag
    output  logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     pred_tag_o,         // prediction result tag
    output  logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]       pred_useful_o,      // prediction result usefulness
    output  logic [P_NUM_PRED-1:0]                      pred_valid_o,       // qualifies the prediction result

    // validation interface (feedback) signals
    input   logic [P_NUM_PRED-1:0][31:0]                fb_actual_i,        // true execution result of the instruction
    output  logic [P_NUM_PRED-1:0][P_CONF_WIDTH:0]      fb_conf_i,          // original confidence fb
    output  logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  fb_index_i,         // original tag
    output  logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     fb_tag_i,           // original tag
    output  logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]       fb_useful_i,        // original usefulness
    input   logic [P_NUM_PRED-1:0]                      fb_mispredict_i,    // indicates misprediction
    input   logic [P_NUM_PRED-1:0]                      fb_valid_i          // valid qualifier of feedback interface
)

    // truncate GBH, hash pc and truncated GBHs
    logic [P_NUM_BANK-1:0][LP_INDEX_WIDTH-1:0]                  lookup_gbh;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  lookup_index;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     lookup_tag;
    generate
        for(genvar bank = 0; bank < P_NUM_BANK; bank = bank + 1) begin: gen_truncate_gbh
            // truncate gbh
            // if(bank == 0) begin
                // assign lookup_gbh[bank] = '0;
            // end
            // else begin
                assign lookup_gbh[bank] = fw_gbh_i[2**bank-1:0]; // 2, 4, 8, ...
            // end
            // generate indices and tags
            for(genvar way = 0; way < P_NUM_PRED; way = way + 1) begin: gen_pred_way
                if(bank == 0) begin : gen_baseline_index
                    assign lookup_index[bank][way] = fw_pc_i[way];
                    assign lookup_tag[bank][way]   = fw_pc_i[way];
                end
                else begin : gen_vtage_index
                    // TODO: hash
                    assign lookup_index[bank][way] = hash_index(lookup_gbh[bank], fw_pc_i[way]);
                    assign lookup_tag[bank][way]   = hash_tag(lookup_gbh[bank], fw_pc_i[way]);
                end
            end
        end
    endgenerate
    
    // generate banks and query entries
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  bank_vt_index; // prediction result value table indices
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     bank_tag;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_CONF_WIDTH-1:0]    bank_conf;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_U_WIDTH-1:0]       bank_u;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_U_WIDTH-1:0]       bank_index; // lookup_index delayed 1
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_hit; // prediction tag match
    generate
        for(genvar bank = 0; bank < P_NUM_BANK; bank = bank + 1) begin: gen_vtage_banks
            vtage_bank #(
                .P_BANK                         (bank),
                .P_NUM_PRED                     (P_NUM_PRED),
                .P_NUM_ENTRIES                  (P_NUM_ENTRIES),
                .P_CONF_WIDTH                   (P_CONF_WIDTH),
                .P_TAG_WIDTH                    (P_TAG_WIDTH),
                .P_U_WIDTH                      (P_U_WIDTH)
            ) vtage_bank (
                .clk_i                          (clk_i),
                .clk_ram_i                      (clk_ram_i),
                .rst_i                          (rst_i),
                
                .fw_index_i                     (lookup_index[bank]),
                .fw_tag_i                       (lookup_tag[bank]),
                .fw_valid_i                     (fw_valid_i),
                
                .pred_result_o                  (bank_vt_index[bank]),
                .pred_conf_o                    (bank_conf[bank]),
                .pred_tag_o                     (bank_tag[bank]),
                .pred_useful_o                  (bank_u[bank]),
                .pred_hit_o                     (bank_hit[bank]),
                
                // TODO: FB
            );
        end
    endgenerate
    always_ff @(posedge clk_i) begin
        bank_index <= lookup_index;
    end
    
    // select result index
    logic [P_NUM_BANK-1:0]                      pred_bank_sel;
    logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  pred_result_index; // selected prediction result value table index
    generate
        for(genvar bank = P_NUM_BANK - 1; bank >= 0; bank = bank - 1) begin: gen_bank_sel
            always_comb begin
                if(|pred_bank_sel == 1'b0) begin // when no bank is selected
                    pred_bank_sel[bank] = bank_hit[bank] & bank_conf[bank][P_CONF_WIDTH]; // select the highest hit and confident
                end
                else begin
                    pred_bank_sel[bank] = 1'b0;
                end
            end
            assign pred_result_index = pred_bank_sel[bank] == 1'b1 ? bank_index[bank];
        end
    endgenerate
    
    // TODO: output all prediction results?
    // select final prediction output
    // logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     bank_tag;
    // logic [P_NUM_PRED-1:0][P_CONF_WIDTH-1:0]    bank_conf;
    // logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]       bank_u;
    // logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]       bank_index; // lookup_index delayed 1
    
    // value table lookup
    // TODO: vt u and bank u
    logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]   pred_vt_u;
    vtage_value_table #(
        .P_NUM_PRED                         (P_NUM_PRED),
        .P_NUM_ENTRIES                      (P_NUM_ENTRIES),
        .P_U_WIDTH                          (P_U_WIDTH)
    ) vtage_value_table (
        .clk_i                              (clk_i),
        .clk_ram_i                          (clk_ram_i),
        
        .rda_addr_i                         (pred_result_index[0]),
        .rdb_addr_i                         (pred_result_index[1]),
        .rda_data_o                         ({pred_result_o[0], pred_vt_u[0]}),
        .rdb_data_o                         ({pred_result_o[1], pred_vt_u[1]}),
        
        // TODO: FB
        .wra_addr_i (),
        .wrb_addr_i (),
        .wra_data_i (),
        .wrb_data_i (),
        .wra_valid_i (),
        .wrb_valid_i (),
    );
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
endmodule