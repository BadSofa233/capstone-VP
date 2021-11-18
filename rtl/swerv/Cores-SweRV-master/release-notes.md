# SweRV RISC-V Core<sup>TM</sup> 1.9 from Western Digital
## Release Notes

* Removed unused scan_mode input from dmi_wrapper (PR#89)
* Enhanced DMA/Side-Effect-load interlock to conditionally allow Side-Effect loads to be non-blocking
    * See PRM for new enable bit in MFDC[13]
* Bug fixes for NMI, MPC, PMU corner cases, MPC ack timing fixes
* Trigger chaining compliance fixes for 0.13.2 missing cases
* Fixed qualification in DCCM access fault equation
* Updated reset hookup for AHB gasket
* Demo TB updates: 
   * added AXI LSU/DMA bridge and ICCM preload by CPU test,
   * dhrystone test,
   * exec.log shows instruction mnemonics



# SweRV RISC-V Core<sup>TM</sup> 1.8 from Western Digital
## Release Notes

* Enhanced Debug module to support access to system bus via access memory abstract commands (see PRM chapter 9)
* Enhanced mpmc firmware halt CSR to add atomic MSTATUS.MIE enable to mpmc CSR (see PRM section 5.5.1)
* Fixed 3 debug module issues reported by Codasip
* Fixed bug with IO load speculation
* Fixed issue with PIC ld/st access following a pipe freeze
* Improvements to demo testbench

# SweRV RISC-V Core<sup>TM</sup> 1.7 from Western Digital
## Release Notes

* RV_FPGA_OPTIMIZE is now default build option. 
    * Use  -fpga_optimize=0 to build for lower power (ASIC) flows.
* Fixed a couple of cases of clock enable qualification for power reduction
* Fixes for 4 debug compliance issues reported by Codasip
* Fixed some remaining clock gating issues for RV_FPGA_OPTIMIZE to improve fpga speed



# SweRV RISC-V Core<sup>TM</sup> 1.6 from Western Digital
## Release Notes

* Added internal timers support. Please see Chapter 4 of the RISC-V SweRV EH1<sup>TM</sup> Programmers Reference Manual.
* Fixed an openOCD compliance case with abstract command error codes.


# SweRV RISC-V Core<sup>TM</sup> 1.5 from Western Digital
## Release Notes


This is a bug-fix and performance-improvement release.  No new functionality
is added to the SweRV core.


##### 1. Bug fixes:

* Hart incorrectly cleared dmcontrol.dmactive on reset (reported by
  Codasip). *Note that a separate system power-on-reset signal `dbg_rst_l`
  was added to differentiate power-on-reset vs core reset. 
  They can be tied together is there is a single reset on chip.*
* Hart never asserted the dmstatus.allrunning signal on reset which
  caused a timeout in OpenOCD (reported by Codasip).
* Debug module failed to auto-increment register on system-bus access
  of size 64-bit (reported by Codasip).
* The core_rst_n signal was incorrectly connected (reported by Codasip).
* Module/instance renamed for tool compatibility.
* The program counter was getting corrupted when the load/store unit
  indicated both a single-bit and a double-bit error in the same
  cycle.
* The MSTATUS register was not being updated as expected when both a
  non-maskable-interrupt and an MSTATUS-write happened in the same
  cycle.
* Write to SBDATA0 was not starting a system-bus write access when
  sbreadonaddr/sbreadondata is set.
* Minstret was incorrectly counting ecall/ebreak instructions.
* The dec_tlu_mpc_halted_only signal was not set for MPC halt after
  reset.
* The MEPC register was not being updated when a firmware-halt request
  was followed by a timer interrupt.
* The MINSTRETH control register was being incremented when
  performance counters were disabled.
* Bus driver contained combinational logic from multiple clock
  domains that sometimes caused a glitch.
* System bus reads were always being made with 64-bit size for the
  AXI bus which is incorrect for IO access.
* DCCM single-bit errors were counted for instructions that did not
  commit.
* ICCM single bit errors were double-counted.
* Load/store unit was not detecting access faults when DCCM and PIC
  memories are next to each other.
* Single-bit ECC errors on data load were not always corrected in
  the DCCM.
* Single-bit ECC errors were not always corrected in the DCCM for DMA
  accesses.
* Single-bit errors detected while reading ICCM through DMA were not
  being corrected in memory.


##### 2. Improvements:

* Improved performance by removing redundant term in decode stall
  logic.
* Reduced power used by the ICCM memory arrays.


##### 3. Testbench Improvements:

* AXI4 and AHB-Lite support.
* Updated bus memory to be persistent and handle larger programs.
* Makefile supports ability to run with source or pre-generated hex
  files.
* Makefile supports targets for CoreMarks benchmark (issue #25).
* Questa support in Makefile (Issue #19).



# SweRV RISC-V Core<sup>TM</sup> 1.4 from Western Digital
## Release Notes
Move declarations to top of Verilog file to fix fpga compile issues.


# SweRV RISC-V Core<sup>TM</sup> 1.3 from Western Digital
## Release Notes
1. Make the FPGA optimization code work with the latest version of Verilator.[Pull request #13](https://github.com/chipsalliance/Cores-SweRV/pull/12)
1. Move JTAG TAP to swerv_wrapper module. [Pull request #10](https://github.com/chipsalliance/Cores-SweRV/pull/10)

# SweRV RISC-V Core<sup>TM</sup> 1.2 from Western Digital
## Release Notes
1. SWERV core RISCV compatibility improvements
    * The ebreak and ecall instructions are no longer counted in the MINSRET
      control and status register.
    * Write to SBDATA0 does not start SB write access when both
      sbreadonaddr/sbreadondata are zero. This fixes issue number
      5 on github.

1. FPGA support: Add fpga_optimize option to swerv.config which
   eliminates over 90% of clock-gating enabling faster FPGA
   simulation.
   
1. Usability: Untabified all the verilog files.  This fixes issue number 3 on github.

# SweRV RISC-V Core<sup>TM</sup> 1.1 from Western Digital
## Release Notes
1. SWERV core RISCV compatibility improvements

    * Illegal instructions no longer increment minstret
    * Debug single-step command no longer executes multiple instructions
    * For instructions, MTVAL register holds the address that actually
      triggered an access fault
    * DICAD1 debug CSR ECC read size enhancements

1. SWERV core performance enhancements

    * Improved instruction fetch unit external memory access performance
    * Instruction fetcher no longer stalls due to DMA ICCM requests
    * Improved performance of streaming stores
    * Improved performance of divide instruction
    * Improved I/O Timing 
    * Non-idempotent Ld/St changed to non-posted in MFDC
    * DMA QoS Configurable in MFDC

1. SWERV core miscellaneous changes

    * Non-word access to PIC memory generates access-error
    * Improved streaming performance with unified read/write buffer
    * Non-idempotent load enhancements
    * Debug, single-step, and trigger enhancements
    * DMA, IFU, and LSU interaction enhancements
    * Bus error handling improvements
    * DMA h-ready addition
    * DMA slave error response enhancements

1. Added memory protection windows
    
    * Now able to define up to eight instruction fetch windows and up to eight
      data load/store windows. See the programmer reference manual for more
      details.
