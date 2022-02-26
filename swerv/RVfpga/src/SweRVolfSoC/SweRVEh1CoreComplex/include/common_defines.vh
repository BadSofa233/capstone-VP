// NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
// This is an automatically generated file by dchaver on mié feb 17 11:26:59 CET 2021
//
// cmd:    swerv -unset=assert_on -set=reset_vec=0x80000000 -set=fpga_optimize=1 
//
`define RV_LSU_NUM_NBLOAD 8
`define RV_LSU_STBUF_DEPTH 8
`define RV_DMA_BUF_DEPTH 4
`define RV_LSU_NUM_NBLOAD_WIDTH 3
`define RV_FPGA_OPTIMIZE 1
`define RV_DEC_INSTBUF_DEPTH 4
`define RV_NMI_VEC 'h11110000
`define DATAWIDTH 64
`define RV_LDERR_ROLLBACK 1
`define CLOCK_PERIOD 100
`define RV_BUILD_AXI4 1
`define CPU_TOP `RV_TOP.swerv
`define SDVT_AHB 1
`define RV_EXT_DATAWIDTH 64
`define TOP tb_top
`define RV_EXT_ADDRWIDTH 32
`define RV_TOP `TOP.rvtop
`define RV_STERR_ROLLBACK 0
`define RV_DATA_ACCESS_MASK7 'hffffffff
`define RV_DATA_ACCESS_ENABLE5 1'h0
`define RV_INST_ACCESS_MASK6 'hffffffff
`define RV_DATA_ACCESS_ADDR4 'h00000000
`define RV_DATA_ACCESS_MASK0 'hffffffff
`define RV_INST_ACCESS_ADDR0 'h00000000
`define RV_INST_ACCESS_ADDR2 'h00000000
`define RV_DATA_ACCESS_MASK5 'hffffffff
`define RV_DATA_ACCESS_ADDR3 'h00000000
`define RV_INST_ACCESS_ADDR3 'h00000000
`define RV_INST_ACCESS_ENABLE5 1'h0
`define RV_DATA_ACCESS_ADDR2 'h00000000
`define RV_DATA_ACCESS_ENABLE4 1'h0
`define RV_INST_ACCESS_ENABLE7 1'h0
`define RV_INST_ACCESS_ENABLE0 1'h0
`define RV_DATA_ACCESS_ENABLE3 1'h0
`define RV_INST_ACCESS_MASK5 'hffffffff
`define RV_INST_ACCESS_MASK7 'hffffffff
`define RV_INST_ACCESS_ENABLE6 1'h0
`define RV_DATA_ACCESS_ENABLE0 1'h0
`define RV_DATA_ACCESS_ADDR6 'h00000000
`define RV_INST_ACCESS_ADDR4 'h00000000
`define RV_INST_ACCESS_ENABLE4 1'h0
`define RV_DATA_ACCESS_MASK2 'hffffffff
`define RV_INST_ACCESS_ADDR1 'h00000000
`define RV_INST_ACCESS_ENABLE3 1'h0
`define RV_DATA_ACCESS_MASK6 'hffffffff
`define RV_DATA_ACCESS_ENABLE7 1'h0
`define RV_DATA_ACCESS_ENABLE2 1'h0
`define RV_INST_ACCESS_MASK3 'hffffffff
`define RV_DATA_ACCESS_ENABLE1 1'h0
`define RV_DATA_ACCESS_MASK4 'hffffffff
`define RV_INST_ACCESS_ADDR6 'h00000000
`define RV_DATA_ACCESS_MASK3 'hffffffff
`define RV_DATA_ACCESS_ADDR1 'h00000000
`define RV_INST_ACCESS_MASK2 'hffffffff
`define RV_INST_ACCESS_ADDR7 'h00000000
`define RV_INST_ACCESS_ADDR5 'h00000000
`define RV_INST_ACCESS_ENABLE1 1'h0
`define RV_DATA_ACCESS_ADDR7 'h00000000
`define RV_INST_ACCESS_MASK1 'hffffffff
`define RV_DATA_ACCESS_ADDR5 'h00000000
`define RV_INST_ACCESS_ENABLE2 1'h0
`define RV_DATA_ACCESS_ENABLE6 1'h0
`define RV_INST_ACCESS_MASK0 'hffffffff
`define RV_DATA_ACCESS_ADDR0 'h00000000
`define RV_INST_ACCESS_MASK4 'hffffffff
`define RV_DATA_ACCESS_MASK1 'hffffffff
`define RV_IFU_BUS_TAG 3
`define RV_LSU_BUS_TAG 4
`define RV_SB_BUS_TAG 1
`define RV_DMA_BUS_TAG 1
`define RV_TARGET default
`define RV_BHT_GHR_SIZE 5
`define RV_BHT_GHR_PAD2 fghr[4:3],2'b0
`define RV_BHT_GHR_PAD fghr[4],3'b0
`define RV_BHT_GHR_RANGE 4:0
`define RV_BHT_ARRAY_DEPTH 16
`define RV_BHT_SIZE 128
`define RV_BHT_ADDR_HI 7
`define RV_BHT_ADDR_LO 4
`define RV_BHT_HASH_STRING {ghr[3:2] ^ {ghr[3+1], {4-1-2{1'b0} } },hashin[5:4]^ghr[2-1:0]}
`define TEC_RV_ICG clockhdr
`define RV_ICACHE_SIZE 16
`define RV_ICACHE_DATA_CELL ram_256x34
`define RV_ICACHE_IC_INDEX 8
`define RV_ICACHE_TAG_CELL ram_64x21
`define RV_ICACHE_ENABLE 1
`define RV_ICACHE_IC_ROWS 256
`define RV_ICACHE_TAG_DEPTH 64
`define RV_ICACHE_TAG_HIGH 12
`define RV_ICACHE_TAG_LOW 6
`define RV_ICACHE_IC_DEPTH 8
`define RV_ICACHE_TADDR_HIGH 5
`define REGWIDTH 32
`define RV_NUMIREGS 32
`define RV_ICCM_DATA_CELL ram_16384x39
`define RV_ICCM_BITS 19
`define RV_ICCM_ROWS 16384
`define RV_ICCM_INDEX_BITS 14
`define RV_ICCM_NUM_BANKS 8
`define RV_ICCM_NUM_BANKS_8 
`define RV_ICCM_BANK_BITS 3
`define RV_ICCM_SIZE_512 
`define RV_ICCM_RESERVED 'h1000
`define RV_ICCM_SIZE 512
`define RV_ICCM_REGION 4'he
`define RV_ICCM_OFFSET 10'he000000
`define RV_ICCM_SADR 32'hee000000
`define RV_ICCM_EADR 32'hee07ffff
`define RV_PIC_MEIPT_OFFSET 'h3004
`define RV_PIC_BITS 15
`define RV_PIC_MEIPT_MASK 'h0
`define RV_PIC_SIZE 32
`define RV_PIC_REGION 4'hf
`define RV_PIC_MEIGWCLR_MASK 'h0
`define RV_PIC_MPICCFG_COUNT 1
`define RV_PIC_MEIGWCTRL_COUNT 8
`define RV_PIC_MEIE_OFFSET 'h2000
`define RV_PIC_MEIGWCLR_COUNT 8
`define RV_PIC_TOTAL_INT_PLUS1 9
`define RV_PIC_BASE_ADDR 32'hf00c0000
`define RV_PIC_MEIPL_COUNT 8
`define RV_PIC_MEIE_MASK 'h1
`define RV_PIC_MEIPL_OFFSET 'h0000
`define RV_PIC_MEIPT_COUNT 8
`define RV_PIC_MPICCFG_MASK 'h1
`define RV_PIC_MEIGWCTRL_OFFSET 'h4000
`define RV_PIC_MEIPL_MASK 'hf
`define RV_PIC_MEIE_COUNT 8
`define RV_PIC_MPICCFG_OFFSET 'h3000
`define RV_PIC_MEIP_COUNT 4
`define RV_PIC_MEIGWCLR_OFFSET 'h5000
`define RV_PIC_TOTAL_INT 8
`define RV_PIC_OFFSET 10'hc0000
`define RV_PIC_MEIGWCTRL_MASK 'h3
`define RV_PIC_INT_WORDS 1
`define RV_PIC_MEIP_OFFSET 'h1000
`define RV_PIC_MEIP_MASK 'h0
`define RV_BTB_ARRAY_DEPTH 4
`define RV_BTB_ADDR_LO 4
`define RV_BTB_SIZE 32
`define RV_BTB_INDEX2_LO 6
`define RV_BTB_INDEX3_LO 8
`define RV_BTB_INDEX2_HI 7
`define RV_BTB_INDEX1_HI 5
`define RV_BTB_BTAG_SIZE 9
`define RV_BTB_BTAG_FOLD 1
`define RV_BTB_INDEX3_HI 9
`define RV_BTB_ADDR_HI 5
`define RV_BTB_INDEX1_LO 4
`define RV_XLEN 32
`define RV_RESET_VEC 'h80000000
`define RV_EXTERNAL_DATA_1 'h00000000
`define RV_UNUSED_REGION5 'h50000000
`define RV_UNUSED_REGION4 'h40000000
`define RV_SERIALIO 'hd0580000
`define RV_UNUSED_REGION9 'h90000000
`define RV_UNUSED_REGION1 'h10000000
`define RV_UNUSED_REGION3 'h30000000
`define RV_UNUSED_REGION7 'h70000000
`define RV_UNUSED_REGION2 'h20000000
`define RV_UNUSED_REGION0 'h00000000
`define RV_EXTERNAL_DATA 'hc0580000
`define RV_EXTERNAL_PROG 'hb0000000
`define RV_UNUSED_REGION6 'h60000000
`define RV_DEBUG_SB_MEM 'hb0580000
`define RV_RET_STACK_SIZE 4
`define RV_DCCM_EADR 32'hf004ffff
`define RV_DCCM_FDATA_WIDTH 39
`define RV_LSU_SB_BITS 16
`define RV_DCCM_SIZE 64
`define RV_DCCM_ECC_WIDTH 7
`define RV_DCCM_SADR 32'hf0040000
`define RV_DCCM_BYTE_WIDTH 4
`define RV_DCCM_NUM_BANKS 8
`define RV_DCCM_SIZE_64 
`define RV_DCCM_NUM_BANKS_8 
`define RV_DCCM_OFFSET 28'h40000
`define RV_DCCM_WIDTH_BITS 2
`define RV_DCCM_ENABLE 1
`define RV_DCCM_DATA_CELL ram_2048x39
`define RV_DCCM_RESERVED 'h1000
`define RV_DCCM_ROWS 2048
`define RV_DCCM_BANK_BITS 3
`define RV_DCCM_DATA_WIDTH 32
`define RV_DCCM_INDEX_BITS 11
`define RV_DCCM_BITS 16
`define RV_DCCM_REGION 4'hf
