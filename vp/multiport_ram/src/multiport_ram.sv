// This is the IP for multiport memory.
// It is able to handle 2 read requests and 2 write requests to all separate addresses by multipumping or banking.
// In banked method, the memory will be devided into 4 banks
// Author: Yuhan Li
// Jan 17, 2022

`ifndef P_MEM_DEPTH
`define P_MEM_DEPTH 2048
`endif

`ifndef P_MEM_WIDTH
`define P_MEM_WIDTH 32
`endif

`ifndef P_METHOD
`define P_METHOD "MULTIPUMPED"
`endif

`ifndef P_NUM_BANK
`define P_NUM_BANK 2048
`endif

`ifndef P_SIM
`define P_SIM 1
`endif

module multiport_ram #(
    parameter P_MEM_DEPTH           = `P_MEM_DEPTH,     // memory depth, accepted: any exponentials of 2
    parameter P_MEM_WIDTH           = `P_MEM_WIDTH,     // memory width, accepted: 8, 16, or 32
    parameter P_METHOD              = `P_METHOD,        // multiport method, accepted: "MULTIPUMPED" or "BANKED"
    parameter P_NUM_BANK            = `P_NUM_BANK,      // number of banks, only used when P_METHOD == "BANKED", accepted: 4
    parameter P_SIM                 = `P_SIM,           // sim or synthesis, accepted: 0 (dual-clock synthesis model), 1 (single-clock behavioral model)
    localparam LP_INDEX_WIDTH       = $clog2(P_MEM_DEPTH)
) (
    // TB_GEN_DEF CLOCK clk_i
    input   logic                                           clk_i,          // main clock
    input   logic                                           clk_mp_i,       // multipumping clock
    
    // read input interface signals
    // TB_GEN_DEF INTERFACE rda DIR I CTRL NONE
    input   logic [LP_INDEX_WIDTH-1:0]                      rda_addr_i,     // read port A address
    // TB_GEN_DEF INTERFACE rdb DIR I CTRL NONE
    input   logic [LP_INDEX_WIDTH-1:0]                      rdb_addr_i,     // read port B address
    
    // read output interface signals
    // TB_GEN_DEF INTERFACE rda DIR O CTRL NONE
    output  logic [P_MEM_WIDTH-1:0]                         rda_data_o,     // read port A data
    // TB_GEN_DEF INTERFACE rdb DIR O CTRL NONE
    output  logic [P_MEM_WIDTH-1:0]                         rdb_data_o,     // read port B data

    // write input interface signals
    // TB_GEN_DEF INTERFACE wra DIR I CTRL VALID
    input   logic [LP_INDEX_WIDTH-1:0]                      wra_addr_i,     // write port A address
    input   logic [P_MEM_WIDTH-1:0]                         wra_data_i,     // write port A data
    input   logic                                           wra_valid_i,    // write port A enable
    // TB_GEN_DEF INTERFACE wrb DIR I CTRL VALID
    input   logic [LP_INDEX_WIDTH-1:0]                      wrb_addr_i,     // write port B address
    input   logic [P_MEM_WIDTH-1:0]                         wrb_data_i,     // write port B data
    input   logic                                           wrb_valid_i     // write port B enable
);

    generate
    
        if(P_SIM == 1) begin // not synthesizable logic, for Verilator simulation only
            // sim signals
            logic [P_MEM_WIDTH-1:0]     mem[P_MEM_DEPTH-1:0];
            logic                       fwda2a;
            logic                       fwdb2a;
            logic                       fwda2b;
            logic                       fwdb2b;
            logic                       tieoff; // used to tieoff the unused input clk_mp_i so Verilator doesn't complain
            
            assign tieoff = clk_mp_i;
            
            initial begin
                for(integer i = 0; i < P_MEM_DEPTH; i = i + 1) begin
                    mem[i] <= 0;
                end
            end
            
            // foward enables
            assign fwda2a = wra_valid_i && wra_addr_i == rda_addr_i;
            assign fwdb2a = wrb_valid_i && wrb_addr_i == rda_addr_i;
            assign fwda2b = wra_valid_i && wra_addr_i == rdb_addr_i;
            assign fwdb2b = wrb_valid_i && wrb_addr_i == rdb_addr_i;

            // port A
            always @(posedge clk_i) begin
                if(wra_valid_i) begin
                    mem[wra_addr_i] <= wra_data_i;
                end
                // forward write data
                if(fwda2a) begin
                    rda_data_o <= wra_data_i;
                end
                else if(fwdb2a) begin
                    rda_data_o <= wrb_data_i;
                end
                else begin
                    rda_data_o <= mem[rda_addr_i];
                end
            end
            // port B
            always @(posedge clk_i) begin
                if(wrb_valid_i) begin
                    mem[wrb_addr_i] <= wrb_data_i;
                end
                // forward write data
                if(fwda2b) begin
                    rdb_data_o <= wra_data_i;
                end
                else if(fwdb2b) begin
                    rdb_data_o <= wrb_data_i;
                end
                else begin
                    rdb_data_o <= mem[rdb_addr_i];
                end
            end
        end
        
        else if(P_METHOD == "MULTIPUMPED") begin
        
            logic [P_MEM_WIDTH-1:0] mem[P_MEM_DEPTH-1:0];
            initial begin
                for(integer i = 0; i < P_MEM_DEPTH; i = i + 1) begin
                    mem[i] <= 0;
                end
            end
            
            // logic for multipumping
            logic                       write_not_read_en;
            logic                       write_not_read_sel;
            logic [LP_INDEX_WIDTH-1:0]  addr_a;
            logic [LP_INDEX_WIDTH-1:0]  addr_b;
            logic [P_MEM_WIDTH-1:0]     rda_data_buf0;
            logic [P_MEM_WIDTH-1:0]     rdb_data_buf0;
            logic [P_MEM_WIDTH-1:0]     rda_data_buf1;
            logic [P_MEM_WIDTH-1:0]     rdb_data_buf1;
            
            // time multiplexing between read and write
            assign write_not_read_en = ~clk_i;
            assign write_not_read_sel = clk_i;
            assign addr_a = write_not_read_sel ? wra_addr_i : rda_addr_i;
            assign addr_b = write_not_read_sel ? wrb_addr_i : rdb_addr_i;
            
            // port A
            always @(posedge clk_mp_i) begin
                if (wra_valid_i & write_not_read_en) begin // only write when it's the write time slice
                    mem[addr_a] <= wra_data_i;
                end
                rda_data_buf0 <= mem[addr_a];
            end
            // port B
            always @(posedge clk_mp_i) begin
                if (wrb_valid_i & write_not_read_en) begin // only write when it's the write time slice
                    mem[addr_b] <= wrb_data_i;
                end
                rdb_data_buf0 <= mem[addr_b];
            end
            
            // stretch the read output data
            // first store data for the next clk_mp_i cycle
            always @(posedge clk_mp_i) begin
                if(write_not_read_en) begin
                    rda_data_buf1 <= rda_data_buf0;
                    rdb_data_buf1 <= rdb_data_buf0;
                end
            end
            // when it's the write time slice, use stored read data
            assign rda_data_o = write_not_read_en ? rda_data_buf1 : rda_data_buf0;
            assign rdb_data_o = write_not_read_en ? rdb_data_buf1 : rdb_data_buf0;
            
        end
        
        else if(P_METHOD == "BANKED") begin // TODO
        
        end
        
    endgenerate
    
endmodule