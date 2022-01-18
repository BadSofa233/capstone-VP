// This is the testbench for multiport memory.
// It is able to handle 2 read requests and 2 write requests to all separate addresses by multipumping or banking.
// Author: Yuhan Li
// Jan 17, 2022

`timescale 1ns / 1ps

module multiport_ram_tb ();

    localparam P_MEM_DEPTH = 16;
    localparam P_MEM_WIDTH = 32;
    localparam LP_INDEX_WIDTH = $clog2(P_MEM_DEPTH);

    logic                                           clk;
    logic                                           clk_mp;
    
    logic [LP_INDEX_WIDTH-1:0]                      rda_addr;       // read port A address
    logic [LP_INDEX_WIDTH-1:0]                      rdb_addr;       // read port B address
    
    // read output interface signals
    logic [P_MEM_WIDTH-1:0]                         rda_data_sim;   // read port A data
    logic [P_MEM_WIDTH-1:0]                         rdb_data_sim;   // read port B data
    logic [P_MEM_WIDTH-1:0]                         rda_data_dut;   // read port A data
    logic [P_MEM_WIDTH-1:0]                         rdb_data_dut;   // read port B data

    // write input interface signals
    logic [LP_INDEX_WIDTH-1:0]                      wra_addr;       // write port A address
    logic [P_MEM_WIDTH-1:0]                         wra_data;       // write port A data
    logic                                           wra_valid;      // write port A enable
    logic [LP_INDEX_WIDTH-1:0]                      wrb_addr;       // write port B address
    logic [P_MEM_WIDTH-1:0]                         wrb_data;       // write port B data
    logic                                           wrb_valid;      // write port B enable

    // sim signals
    logic [P_MEM_WIDTH-1:0]     mem[P_MEM_DEPTH-1:0];
    logic [LP_INDEX_WIDTH-1:0]  raddr;
    logic [LP_INDEX_WIDTH-1:0]  waddr;
    logic [P_MEM_WIDTH-1:0]     wdata;
    logic                       fwda2a;
    logic                       fwdb2a;
    logic                       fwda2b;
    logic                       fwdb2b;
    
    // testbench signals
    integer                     seed = $random();
    logic                       match;

    initial begin
        clk = 0;
        clk_mp = 1;
        for(integer i = 0; i < P_MEM_DEPTH; i = i + 1) begin
            mem[i] = 0;
        end
        $display("Seed %d", seed);
    end
    
    always #10 clk = ~clk;
    always #5  clk_mp = ~clk_mp;
    
    // generate random addresses
    always @(posedge clk) begin
        raddr <= $urandom(seed+$time+1);
        waddr <= $urandom(seed+$time+2);
        wdata <= $urandom(seed+$time+3);
    end
    
    always @(posedge clk) begin
        rda_addr <= raddr;
        rdb_addr <= ~raddr;
    end
    
    // generate write drivers
    always @(posedge clk) begin
        wra_addr <= waddr;
        wrb_addr <= ~waddr;
        wra_data <= waddr;
        wrb_data <= ~waddr;
        wra_valid <= $urandom(seed+$time+4);
        wrb_valid <= $urandom(seed+$time+5);
    end
    
    // sim mem
    
    // foward enables
    assign fwda2a = wra_valid && wra_addr == rda_addr;
    assign fwdb2a = wrb_valid && wrb_addr == rda_addr;
    assign fwda2b = wra_valid && wra_addr == rdb_addr;
    assign fwdb2b = wrb_valid && wrb_addr == rdb_addr;

    // port A
    always @(posedge clk) begin
        if(wra_valid) begin
            mem[wra_addr] <= wra_data;
        end
        // forward write data
        if(fwda2a) begin
            rda_data_sim <= wra_data;
        end
        else if(fwdb2a) begin
            rda_data_sim <= wrb_data;
        end
        else begin
            rda_data_sim <= mem[rda_addr];
        end
    end
    // port B
    always @(posedge clk) begin
        if(wrb_valid) begin
            mem[wrb_addr] <= wrb_data;
        end
        // forward write data
        if(fwda2b) begin
            rdb_data_sim <= wra_data;
        end
        else if(fwdb2b) begin
            rdb_data_sim <= wrb_data;
        end
        else begin
            rdb_data_sim <= mem[rdb_addr];
        end
    end
    
    // dut
    multiport_ram #(
        .P_MEM_DEPTH        (P_MEM_DEPTH),
        .P_MEM_WIDTH        (P_MEM_WIDTH),
        .P_SIM              (0),
        .P_METHOD           ("MULTIPUMPED")
    ) dut (
        .clk_i              (clk),
        .clk_mp_i           (clk_mp),
        .rda_addr_i         (rda_addr),
        .rdb_addr_i         (rdb_addr),
        .rda_data_o         (rda_data_dut),
        .rdb_data_o         (rdb_data_dut),
        .wra_addr_i         (wra_addr),
        .wra_data_i         (wra_data),
        .wra_valid_i        (wra_valid),
        .wrb_addr_i         (wrb_addr),
        .wrb_data_i         (wrb_data),
        .wrb_valid_i        (wrb_valid)
    );
    
    // compare
    
    assign match = (rda_data_dut == rda_data_sim) && (rdb_data_dut == rdb_data_sim);
    initial begin
        if(rda_data_dut != rda_data_sim) begin
            $error("ERROR: rda_data_o mismatch, dut 0x%X sim 0x%X", rda_data_dut, rda_data_sim);
        end
        if(rdb_data_dut != rdb_data_sim) begin
            $error("ERROR: rdb_data_o mismatch, dut 0x%X sim 0x%X", rda_data_dut, rda_data_sim);
        end
    end

endmodule