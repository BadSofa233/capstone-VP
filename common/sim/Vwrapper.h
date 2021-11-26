// this is a wrapper class header for the verilated DUT
// Author: Yuhan Li
// Nov 18, 2021

#ifndef VERILATED_DUT_WRAPPER_H
#define VERILATED_DUT_WRAPPER_H

#ifndef DUT_DUMP_TRACE
#define DUT_DUMP_TRACE 0
#endif

#include "verilated.h"
#include "verilated_vcd_c.h"
#include <string>
#include <iostream>

template<class Device>
class Vwrapper {
    protected:
        Device *            device;
    private:
        bool                dump_trace;
        VerilatedVcdC *     dut_trace;
        const std::string   device_name;
        int                 cycle;
    
    public:
        Vwrapper(const char * name) : device_name(name) {
            device = new Device;
            Verilated::traceEverOn(true);
            dump_trace = DUT_DUMP_TRACE;
            // if(dump_trace) {
#if DUT_DUMP_TRACE == 1
            std::cout << "Dump is turned on\n";
            dut_trace = nullptr;
            open_trace();
#endif
            // }
            cycle = 0;
        }
        
        virtual ~Vwrapper() {
            close_trace();
            delete device;
        }
        
        // assert one cycle of reset to device
        virtual void reset_1() {
            device->rst_i = 1;
            tick();
            device->rst_i = 0;
            tick();
        }
        
        // toggle the clock twice
        virtual void tick() {
            cycle++;
            eval(10*cycle-2, false);
            device->clk_i = 1;
            eval(10*cycle, false);
            device->clk_i = 0;
            eval(10*cycle+5, true);
        }
        
        // evaluate the block at current state
        virtual void eval() {
            device->eval();
        }
        
        virtual void eval(int timestamp, bool flush) {
            device->eval();
#if DUT_DUMP_TRACE == 1
            // if(dump_trace) {
            dut_trace->dump(timestamp);
            if(flush) {
                dut_trace->flush();
            }
            // }
#endif
        }
        
        // start waveform tracing
        virtual void open_trace() {
#if DUT_DUMP_TRACE == 1
            if(dut_trace == nullptr) {
                dut_trace = new VerilatedVcdC;
                device->trace(dut_trace, 99);
                dut_trace->open((device_name + "_trace.vcd").c_str());
                std::cout << "trace opened\n";
            }
#endif
        }
        
        // close waveform tracing
        virtual void close_trace() {
#if DUT_DUMP_TRACE == 1
            if(dut_trace != nullptr) {
                dut_trace->close();
                dut_trace = nullptr;
            }
#endif
        }

};

#endif