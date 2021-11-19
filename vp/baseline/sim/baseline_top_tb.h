// this is the auto generated testbench header

#ifndef BASELINE_TOP_TB_H
#define BASELINE_TOP_TB_H

#include "Vwrapper.h"
#include "Vbaseline_top.h"
#include "verilated.h"

#include <inttypes.h>

class Baseline_top_tb : public Vwrapper<Vbaseline_top> {
    public:
        Baseline_top_tb() : Vwrapper((char *)"baseline_top_tb") {

        }
        
        void final() {
            device->final();
        }
        
        // input signals
    
        void write_clk_i(uint64_t clk_i){
            device->clk_i = clk_i;
        }
        
        void write_rst_i(uint64_t rst_i){
            device->rst_i = rst_i;
        }
        
        void write_fw_pc_i(uint64_t fw_pc_i){
            device->fw_pc_i = fw_pc_i;
        }
        
        void write_fb_pc_i(uint64_t fb_pc_i){
            device->fb_pc_i = fb_pc_i;
        }
        
        void write_fb_result_i(uint64_t fb_result_i){
            device->fb_result_i = fb_result_i;
        }
        
        void write_fb_valid_i(uint64_t fb_valid_i){
            device->fb_valid_i = fb_valid_i;
        }
    
        // output signals
    
        uint64_t read_entry_valid_dbgo(){
            return device->entry_valid_dbgo;
        }
        
        uint64_t read_entry_val_dbgo(){
            return device->entry_val_dbgo;
        }
        
        uint64_t read_conf_dbgo(){
            return device->conf_dbgo;
        }
        
        uint64_t read_pred_o(){
            return device->pred_o;
        }
        
        uint64_t read_pred_valid_o(){
            return device->pred_valid_o;
        }
        
        uint64_t read_mispredict_o(){
            return device->mispredict_o;
        }
    
};

#endif
