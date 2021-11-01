#include "Vbaseline_top.h"
#include "verilated.h"

int main(int argc, char **argv, char **env) {
    
    Verilated::commandArgs(argc, argv);
    
    Vbaseline_top* DUT = new Vbaseline_top;
    
    while (!Verilated::gotFinish()) {
        DUT->eval(); 
    }
    
    return 0;
    
}