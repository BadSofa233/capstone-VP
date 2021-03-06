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
`define P_NUM_ENTRIES 256
`endif

`ifndef P_CONF_WIDTH
`define P_CONF_WIDTH 8
`endif

`ifndef P_TAG_WIDTH
`define P_TAG_WIDTH 5
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
    localparam  LP_INDEX_WIDTH          = $clog2(P_NUM_ENTRIES),
    localparam  LP_BANK_SEL_WIDTH       = $clog2(P_NUM_BANK)
) (
    input   logic                                       clk_i,          // main clock
    input   logic                                       clk_ram_i,      // main clock
    input   logic                                       rst_i,          // active high reset
    
    // --------
    // debug
    // --------
    // output  logic [P_NUM_PRED-1:0] entry_valid_dbgo,
    // output  logic [P_NUM_PRED-1:0][31:0] entry_val_dbgo,
    // output  logic [P_NUM_PRED-1:0][P_CONF_WIDTH-1:0]  conf_dbgo,
    // --------
    
    // forward prediction interface signals
    input   logic [P_NUM_PRED-1:0][31:1]                    fw_pc_i,            // current instruction address
    input   logic [P_GBH_LENGTH-1:0]                        fw_gbh_i,           // global branch history
    input   logic [P_NUM_PRED-1:0]                          fw_valid_i,         // input valid qualifier
    
    // prediction output
    // basically the entire two entries
    output  logic [P_NUM_PRED-1:0][31:0]                    pred_result_o,      // prediction result value
    output  logic [P_NUM_PRED-1:0][P_CONF_WIDTH:0]          pred_conf_o,        // prediction result confidence
    output  logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]      pred_index_o,       // prediction result tag
    output  logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]         pred_tag_o,         // prediction result tag
    output  logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]           pred_useful_o,      // prediction result usefulness
    output  logic [P_NUM_PRED-1:0][LP_BANK_SEL_WIDTH-1:0]   pred_bank_o,        // prediction result usefulness
    output  logic [P_NUM_PRED-1:0]                          pred_valid_o,       // qualifies the prediction result

    // validation interface (feedback) signals
    input   logic [P_NUM_PRED-1:0][31:0]                    fb_actual_i,        // true execution result of the instruction
    input   logic [P_NUM_PRED-1:0][P_CONF_WIDTH:0]          fb_conf_i,          // original confidence fb
    input   logic [P_NUM_PRED-1:0][LP_BANK_SEL_WIDTH-1:0]   fb_bank_i,          // original tag
    input   logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]      fb_index_i,         // original tag
    input   logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]         fb_tag_i,           // original tag
    input   logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]           fb_useful_i,        // original usefulness
    input   logic [P_NUM_PRED-1:0]                          fb_mispredict_i,    // indicates misprediction
    input   logic [P_NUM_PRED-1:0]                          fb_valid_i          // valid qualifier of feedback interface
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
                assign lookup_gbh[bank] = fw_gbh_i[4**bank-1:0]; // 4, 16, 64, ...
            // end
            // generate indices and tags
            for(genvar way = 0; way < P_NUM_PRED; way = way + 1) begin: gen_pred_way
                if(bank == 0) begin : gen_baseline_index
                    assign lookup_index[bank][way] = fw_pc_i[way];
                    assign lookup_tag[bank][way]   = '0;
                end
                else begin : gen_vtage_index
                    // hash index (lookup_gbh[bank], fw_pc_i[way])
                    assign lookup_index[bank][way] = lookup_gbh[bank][7:0]     ^ lookup_gbh[bank][15:8]  ^ lookup_gbh[bank][23:16] ^ lookup_gbh[bank][31:24] ^ 
                                                     lookup_gbh[bank][39:32]   ^ lookup_gbh[bank][47:40] ^ lookup_gbh[bank][55:48] ^ lookup_gbh[bank][63:56] ^ 
                                                     {fw_pc_i[way][7:1], 1'b0} ^ fw_pc_i[way][15:8]      ^ fw_pc_i[way][23:16]     ^ fw_pc_i[way][31:24];
                    // hash tag (lookup_gbh[bank], fw_pc_i[way])
                    assign lookup_tag[bank][way]   = lookup_gbh[bank][5:0]   ^ lookup_gbh[bank][11:6]  ^ lookup_gbh[bank][17:12]         ^ lookup_gbh[bank][23:18] ^ 
                                                     lookup_gbh[bank][29:24] ^ lookup_gbh[bank][35:30] ^ lookup_gbh[bank][41:36]         ^ lookup_gbh[bank][23:42] ^ 
                                                     lookup_gbh[bank][53:48] ^ lookup_gbh[bank][59:54] ^ {2'b0, lookup_gbh[bank][63:60]} ^ {fw_pc_i[way][4:1], 1'b0} ^
                                                     fw_pc_i[way][11:6]      ^ fw_pc_i[way][17:12]     ^ fw_pc_i[way][23:18]             ^ fw_pc_i[way][29:24] ^
                                                     {4'b0, fw_pc_i[way][31:30]};
                end
            end
        end
    endgenerate
    
    // generate banks and query entries
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  bank_fw_vt_index; // prediction result value table indices
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     bank_fw_tag;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_CONF_WIDTH-1:0]    bank_fw_conf;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_U_WIDTH-1:0]       bank_fw_u;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_U_WIDTH-1:0]       bank_fw_index; // lookup_index delayed 1
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_fw_hit; // prediction tag match
    
    // suppress prediction for 128 cycles after misp
    logic [7:0]                                                 last_misp_cycles;
    logic [P_NUM_PRED-1:0]                                      pred_misp_supress;
    
    // feedback signals
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     bank_fb_tag;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_fb_match;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_fb_alloc_avail;
    
    // bank update signals
    logic [P_NUM_PRED-1:0][LP_BANK_SEL_WIDTH-1:0]               ud_bank_sel;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  ud_ct_index;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      ud_incr_conf;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      ud_rst_conf;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      ud_incr_use;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      ud_decr_use;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      ud_rst_use;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      ud_load_tag;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     ud_tag;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      ud_ct_load_value;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  ud_value; // new pointer to a value table entry
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  bank_ud_index;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_ud_incr_conf;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_ud_rst_conf;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_ud_incr_use;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_ud_decr_use;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_ud_rst_use;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_ud_load_tag;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     bank_ud_tag;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0]                      bank_ud_load_value;
    logic [P_NUM_BANK-1:0][P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]  bank_ud_value; // new pointer to a value table entry
    logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]                  ud_vt_index;
    logic [P_NUM_PRED-1:0][31:0]                                ud_vt_value;
    logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]                       ud_vt_useful;
    logic [P_NUM_PRED-1:0]                                      ud_vt_load;

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
                // .clk_ram_i                      (clk_ram_i),
                .rst_i                          (rst_i),
                
                .fw_index_i                     (lookup_index[bank]),
                .fw_tag_i                       (lookup_tag[bank]),
                .fw_valid_i                     (fw_valid_i),
                
                .pred_result_o                  (bank_fw_vt_index[bank]),
                .pred_conf_o                    (bank_fw_conf[bank]),
                .pred_tag_o                     (bank_fw_tag[bank]),
                .pred_useful_o                  (bank_fw_u[bank]),
                .pred_hit_o                     (bank_fw_hit[bank]),
                
                .fb_index_i                     (fb_index_i[bank]),
                .fb_tag_i                       (bank_fb_tag[bank]),
                .fb_tag_match_o                 (bank_fb_match[bank]),
                .fb_alloc_avail_o               (bank_fb_alloc_avail[bank]),
                
                .ud_index_i                     (bank_ud_index[bank]),
                .ud_incr_conf_i                 (bank_ud_incr_conf[bank]),
                .ud_rst_conf_i                  (bank_ud_rst_conf[bank]),
                .ud_incr_use_i                  (bank_ud_incr_use[bank]),
                .ud_decr_use_i                  (bank_ud_decr_use[bank]),
                .ud_rst_use_i                   (bank_ud_rst_use[bank]),
                .ud_load_tag_i                  (bank_ud_load_tag[bank]),
                .ud_tag_i                       (bank_ud_tag[bank]),
                .ud_load_value_i                (bank_ud_load_value[bank]),
                .ud_value_i                     (bank_ud_value[bank])
            );
        end
    endgenerate
    always_ff @(posedge clk_i) begin
        bank_fw_index <= lookup_index;
    end
    
    // select result index
    logic [P_NUM_PRED-1:0][LP_BANK_SEL_WIDTH-1:0]   pred_bank_sel;
    logic [P_NUM_PRED-1:0][LP_INDEX_WIDTH-1:0]      pred_result_index; // selected prediction result value table index
    generate // a priority mux
        // for(genvar way = 0; way < P_NUM_PRED; way = way + 1) begin: gen_prmux
            // if(bank_fw_hit[3] & bank_fw_conf[3][P_CONF_WIDTH]) begin: gen_hit3
                // pred_bank_sel[way] = '3;
            // end
            // else if(bank_fw_hit[2] & bank_fw_conf[2][P_CONF_WIDTH]) begin: gen_hit2
                // pred_bank_sel[way] = '2;
            // end
            // else if(bank_fw_hit[1] & bank_fw_conf[1][P_CONF_WIDTH]) begin: gen_hit1
                // pred_bank_sel[way] = '1;
            // end
            // else begin: gen_hit0
                // pred_bank_sel[way] = '0;
            // end
        // end
        always_comb begin
            for(integer bank = 0; bank < P_NUM_BANK; bank = bank + 1) begin: gen_bank_sel
                if(bank_fw_hit[bank]) begin
                    pred_bank_sel = bank;
                end
                else begin
                    pred_bank_sel = 1'b0; // select baseline as default
                end
            end
        end
    endgenerate
    
    assign pred_bank_o          = pred_bank_sel;
    assign pred_result_index    = bank_fw_vt_index[pred_bank_sel];
    assign pred_index_o         = bank_fw_index[pred_bank_sel];
    assign pred_conf_o          = bank_fw_conf[pred_bank_sel];
    assign pred_useful_o        = bank_fw_u[pred_bank_sel];
    assign pred_tag_o           = bank_fw_tag[pred_bank_sel];
    
    // suppress prediction for 128 cycles after misp
    always_ff @(posedge clk_i) begin
        if(rst_i | (|fb_mispredict_i)) begin
            last_misp_cycles <= '0;
        end
        else if(~last_misp_cycles[7]) begin
            last_misp_cycles <= last_misp_cycles + 1'b1;
        end
    end
    assign pred_valid_o = last_misp_cycles[7];
    
    // update signal selection
    generate
        always_comb begin
            for(integer i = 0; i < P_NUM_BANK; i = i + 1) begin: gen_bank_ud_sel
                for(genvar p = 0; p < P_NUM_PRED; p = p + 1) begin
                    if(ud_bank_sel[p] == i) begin
                        bank_ud_index[i]        = ud_ct_index[p];
                        bank_ud_incr_conf[i]    = ud_incr_conf[p];
                        bank_ud_rst_conf[i]     = ud_rst_conf[p];
                        bank_ud_incr_use[i]     = ud_incr_use[p];
                        bank_ud_decr_use[i]     = ud_decr_use[p];
                        bank_ud_rst_use[i]      = ud_rst_use[p];
                        bank_ud_load_tag[i]     = ud_load_tag[p];
                        bank_ud_tag[i]          = ud_tag[p];
                        bank_ud_load_value[i]   = ud_load_value[p];
                        bank_ud_value[i]        = ud_ct_value[p];
                    end
                    else begin
                        bank_ud_index[i]        = '0;
                        bank_ud_incr_conf[i]    = '0;
                        bank_ud_rst_conf[i]     = '0;
                        bank_ud_incr_use[i]     = '0;
                        bank_ud_decr_use[i]     = '0;
                        bank_ud_rst_use[i]      = '0;
                        bank_ud_load_tag[i]     = '0;
                        bank_ud_tag[i]          = '0;
                        bank_ud_load_value[i]   = '0;
                        bank_ud_value[i]        = '0;
                    end
                end
            end
        end
    endgenerate
    
    // TODO: output all prediction results?
    // maybe not, because we only care about the pred with the highest gbh
    // and allocate upwards
    // select final prediction output
    // logic [P_NUM_PRED-1:0][P_TAG_WIDTH-1:0]     bank_fw_tag;
    // logic [P_NUM_PRED-1:0][P_CONF_WIDTH-1:0]    bank_fw_conf;
    // logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]       bank_fw_u;
    // logic [P_NUM_PRED-1:0][P_U_WIDTH-1:0]       bank_fw_index; // lookup_index delayed 1
    
    // value table lookup
    // TODO: vt u
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
        
        .wra_addr_i                         (ud_vt_index[0]),
        .wrb_addr_i                         (ud_vt_index[1]),
        .wra_data_i                         ({ud_vt_value[0], ud_vt_useful[0]}),
        .wrb_data_i                         ({ud_vt_value[1], ud_vt_useful[1]}),
        .wra_valid_i                        (ud_vt_load[0]),
        .wrb_valid_i                        (ud_vt_load[1])
    );
    
    // update unit
    vtage_update_unit #(
        .P_NUM_PRED                         (P_NUM_PRED),
        .P_NUM_BANK                         (P_NUM_BANK),
        .P_NUM_ENTRIES                      (P_NUM_ENTRIES),
        .P_CONF_WIDTH                       (P_CONF_WIDTH),
        .P_TAG_WIDTH                        (P_TAG_WIDTH),
        .P_U_WIDTH                          (P_U_WIDTH)
    ) vtage_update_unit (
        .clk_i                              (clk_i),
        .rst_i                              (rst_i),
    
        .fb_actual_i                        (fb_index_i),
        .fb_conf_i                          (fb_actual_i),
        .fb_bank_i                          (fb_bank_i),
        .fb_index_i                         (fb_index_i),
        .fb_tag_i                           (fb_tag_i),
        .fb_useful_i                        (fb_useful_i),
        .fb_mispredict_i                    (fb_mispredict_i),
        .fb_valid_i                         (fb_valid_i),
        
        .bank_fb_match_i                    (bank_fb_match), // 0th fb cycle
        .bank_fb_alloc_avail_i              (bank_fb_alloc_avail), // 0th fb cycle
        
        .ud_bank_sel_o                      (ud_bank_sel),
        .ud_incr_conf_o                     (ud_incr_conf),
        .ud_rst_conf_o                      (ud_rst_conf),
        .ud_incr_use_o                      (ud_incr_use),
        .ud_decr_use_o                      (ud_decr_use),
        .ud_rst_use_o                       (ud_rst_use),
        .ud_ct_index_o                      (ud_ct_index),
        .ud_load_tag_o                      (ud_load_tag),
        .ud_tag_o                           (ud_tag),
        .ud_load_value_o                    (ud_load_value),
        .ud_ct_value_o                      (ud_ct_value),
        
        .ud_vt_index_o                      (ud_vt_index),
        .ud_vt_value_o                      (ud_vt_value),
        .ud_vt_useful_o                     (ud_vt_useful),
        .ud_vt_load_o                       (ud_vt_load)
    );
    
endmodule