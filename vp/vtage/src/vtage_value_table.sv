// This is the value table for baseline_top and VTAGE
// Author: Songlin Li
// Date: Jan 18, 2022

`ifndef P_STORAGE_SIZE
`define P_STORAGE_SIZE 2048
`endif

`ifndef P_DATA_WIDTH
`define P_DATA_WIDTH 32
`endif

module vtage_value_table #( 
    
    parameter   P_STORAGE_SIZE  = `P_STORAGE_SIZE,
    parameter   P_DATA_WIDTH = `P_DATA_WIDTH,
    localparam  LP_ADDRESS_WIDTH = $clog2(P_STORAGE_SIZE)
) (
    // input
    // clock
    input   logic                                       clk_i,          // main clock
    input   logic                                       clk_ram_i,      // ram clock

    // read address
    input   logic [LP_ADDRESS_WIDTH-1:0]                rda_addr_i,     // read address a
    input   logic [LP_ADDRESS_WIDTH-1:0]                rdb_addr_i,     // read address b
    // write address
    input   logic [LP_ADDRESS_WIDTH-1:0]                wra_addr_i,     // write address a
    input   logic [LP_ADDRESS_WIDTH-1:0]                wrb_addr_i,     // write address b
    // write data
    input   logic [P_DATA_WIDTH-1:0]                    wra_data_i,     // write data a
    input   logic [P_DATA_WIDTH-1:0]                    wrb_data_i,     // write data b
    // write valid
    input   logic                                       wra_valid_i,    // write valid a
    input   logic                                       wrb_valid_i,    // write valid b
    
    // output
    // read data
    output  logic [P_DATA_WIDTH-1:0]                    rda_data_o,     // read data a
    output  logic [P_DATA_WIDTH-1:0]                    rdb_data_o      // read data b

);


multiport_ram #(
    .P_MEM_DEPTH        (P_STORAGE_SIZE),
    .P_MEM_WIDTH        (P_DATA_WIDTH),
    .P_SIM              (1),
    .P_METHOD           ("MULTIPUMPED")
)
multiport_tam (
    .clk_i              (clk_i),
    .clk_mp_i           (clk_ram_i),
    .rda_addr_i         (rda_addr_i),
    .rdb_addr_i         (rdb_addr_i),
    .rda_data_o         (rda_data_o),
    .rdb_data_o         (rdb_data_o),
    .wra_addr_i         (wra_addr_i),
    .wra_data_i         (wra_data_i),
    .wra_valid_i        (wra_valid_i),
    .wrb_addr_i         (wrb_addr_i),
    .wrb_data_i         (wrb_data_i),
    .wrb_valid_i        (wrb_valid_i)
);


endmodule 