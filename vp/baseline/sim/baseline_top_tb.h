// this is the auto generated testbench header

#ifndef BASELINE_TOP_TB_H
#define BASELINE_TOP_TB_H

#include "Vwrapper.h"
#include "Vbaseline_top.h"
#include "verilated.h"
#include "baseline_top_cmodel.h"

#include <inttypes.h>
#include <stdio.h>

class Baseline_top_tb : public Vwrapper<Vbaseline_top> {
    public:
        
        Baseline_top_cmodel * cmodel;
        
        Baseline_top_tb(Baseline_top_cmodel * cm) : 
            Vwrapper((char *)"baseline_top_tb") 
        {
            cmodel = cm;
        }
        
        void tick() override {
            Vwrapper::tick();
            cmodel->tick();
            compare_pred();

        }
        
        void final() {
            device->final();
        }
    
        void compare_pred() {
            
            if(device->pred_valid_o != cmodel->pred_valid_o) {
                printf("ERROR: pred_valid_o mismatch, CMODEL 0x%lX, RTL 0x%lX\n", cmodel->pred_valid_o, device->pred_valid_o);
                exit(1);
            }
            
            for(int sub_interface = 0; sub_interface < 2; sub_interface++) {
            
                if(cmodel->pred_valid_o >> sub_interface == 1) {
                    
                    if(device->pred_pc_o >> (31 * sub_interface) & (1 << 31 - 1) != cmodel->pred_pc_o >> (31 * sub_interface) & (1 << 31 - 1)) {
                        printf("ERROR: pred_pc_o mismatch, CMODEL 0x%lX, RTL 0x%lX\n", cmodel->pred_pc_o, device->pred_pc_o);
                        exit(1);
                    }
                        
                    if(device->pred_result_o >> (32 * sub_interface) & (1 << 32 - 1) != cmodel->pred_result_o >> (32 * sub_interface) & (1 << 32 - 1)) {
                        printf("ERROR: pred_result_o mismatch, CMODEL 0x%lX, RTL 0x%lX\n", cmodel->pred_result_o, device->pred_result_o);
                        exit(1);
                    }
                        
                    if(device->pred_conf_o >> (8 * sub_interface) & (1 << 8 - 1) != cmodel->pred_conf_o >> (8 * sub_interface) & (1 << 8 - 1)) {
                        printf("ERROR: pred_conf_o mismatch, CMODEL 0x%lX, RTL 0x%lX\n", cmodel->pred_conf_o, device->pred_conf_o);
                        exit(1);
                    }
                        
                }
            }
            
        }
    
        // input signals
    
        void write_clk_i(uint64_t clk_i){
            device->clk_i = clk_i;
            cmodel->clk_i = clk_i;
        }
        
        void write_clk_ram_i(uint64_t clk_ram_i){
            device->clk_ram_i = clk_ram_i;
            cmodel->clk_ram_i = clk_ram_i;
        }
        
        void write_rst_i(uint64_t rst_i){
            device->rst_i = rst_i;
            cmodel->rst_i = rst_i;
        }
        
        void write_fw_pc_i(uint64_t fw_pc_i){
            device->fw_pc_i = fw_pc_i;
            cmodel->fw_pc_i = fw_pc_i;
        }
        
        void write_fw_valid_i(uint64_t fw_valid_i){
            device->fw_valid_i = fw_valid_i;
            cmodel->fw_valid_i = fw_valid_i;
        }
        
        void write_fb_pc_i(uint64_t fb_pc_i){
            device->fb_pc_i = fb_pc_i;
            cmodel->fb_pc_i = fb_pc_i;
        }
        
        void write_fb_actual_i(uint64_t fb_actual_i){
            device->fb_actual_i = fb_actual_i;
            cmodel->fb_actual_i = fb_actual_i;
        }
        
        void write_fb_mispredict_i(uint64_t fb_mispredict_i){
            device->fb_mispredict_i = fb_mispredict_i;
            cmodel->fb_mispredict_i = fb_mispredict_i;
        }
        
        void write_fb_conf_i(uint64_t fb_conf_i){
            device->fb_conf_i = fb_conf_i;
            cmodel->fb_conf_i = fb_conf_i;
        }
        
        void write_fb_valid_i(uint64_t fb_valid_i){
            device->fb_valid_i = fb_valid_i;
            cmodel->fb_valid_i = fb_valid_i;
        }
    
        // output signals
    
        uint64_t read_pred_pc_o(bool cm){
            return cm ? cmodel->pred_pc_o : device->pred_pc_o;
        }
        
        uint64_t read_pred_result_o(bool cm){
            return cm ? cmodel->pred_result_o : device->pred_result_o;
        }
        
        uint64_t read_pred_conf_o(bool cm){
            return cm ? cmodel->pred_conf_o : device->pred_conf_o;
        }
        
        uint64_t read_pred_valid_o(bool cm){
            return cm ? cmodel->pred_valid_o : device->pred_valid_o;
        }
    
};

#endif
