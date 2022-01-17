#usr/bin/bash

# ------------------------------------------------
# parsing
# ------------------------------------------------
# parse input signals
sig_in=$(grep -v "^ *//" "$1"/"$2".sv | grep input.*_i | grep -o [_a-z]*_i)
# parse output signals
sig_out=$(grep -v "^ *//" "$1"/"$2".sv | grep output.*_o | grep -o [_a-z]*_o)
# parse parameters, not needed now
params=$(grep -v "^ *//" "$1"/"$2".sv | grep parameter.*P_.*= | grep -o P[_0-9A-Z]*)
# parse input interfaces
inf_in=($(grep "TB_GEN_DEF INTERFACE [_0-9a-z]* DIR I" "$1"/"$2".sv | grep -o "[a-z][_0-9a-z]*"))
# parse output interfaces
inf_out=($(grep "TB_GEN_DEF INTERFACE [_0-9a-z]* DIR O" "$1"/"$2".sv | grep -o "[a-z][_0-9a-z]*"))
# parse input flow controls
ctrl_in=($(grep "TB_GEN_DEF INTERFACE .* DIR I" "$1"/"$2".sv | grep -wo "NONE\|VALID"))
# parse output flow controls
ctrl_out=($(grep "TB_GEN_DEF INTERFACE .* DIR O" "$1"/"$2".sv | grep -wo "NONE\|VALID"))
# parse clock
clock=$(grep "TB_GEN_DEF CLOCK [_0-9a-z]*" "$1"/"$2".sv | grep -o "[a-z][_0-9a-z]*")
# parse reset
reset=$(grep "TB_GEN_DEF RESET [_0-9a-z]*" "$1"/"$2".sv | grep -o "[a-z][_0-9a-z]*")

# ------------------------------------------------
# testbench generation
# ------------------------------------------------
printf "\
// this is the auto generated testbench header\n\

#ifndef "${2^^}"_TB_H
#define "${2^^}"_TB_H

#include \"Vwrapper.h\"
#include \"V"$2".h\"
#include \"verilated.h\"
#include \""$2"_cmodel.h\"

#include <inttypes.h>
#include <stdio.h>

class "${2^}"_tb : public Vwrapper<V"$2"> {
    public:
        
        "${2^}"_cmodel * cmodel;
        
        "${2^}"_tb("${2^}"_cmodel * cm) : 
            Vwrapper((char *)\""$2"_tb\") 
        {
            cmodel = cm;
        }
        
        void tick() override {
            Vwrapper::tick();
            cmodel->tick();
" > "$3"/"$2"_tb.h

for inf in "${inf_out[@]}"; do
    printf "\
            compare_"$inf"();
" >> "$3"/"$2"_tb.h
done

printf "\

        }
        
        void final() {
            device->final();
        }
" >> "$3"/"$2"_tb.h

for i in "${!inf_out[@]}"; do
    inf="${inf_out[i]}"
    ctrl="${ctrl_out[i]}"
    # only handles CTRL NONE or VALID!
    sigs=$(grep -v "^ *//" "$1"/"$2".sv | grep output.*_o | grep -o "$inf".*_o)
    
    printf "\
    
        void compare_"$inf"() {
    " >> "$3"/"$2"_tb.h
    
    if [ $ctrl = "VALID" ]
    then
        printf "\
        
            if(device->"$inf"_valid_o != cmodel->"$inf"_valid_o) {
                %s
                exit(1);
            }
            
            if(cmodel->"$inf"_valid_o == 1) {
        " "printf(\"ERROR: "$inf"_valid_o mismatch, CMODEL 0x%lX, RTL 0x%lX\n\", cmodel->"$inf"_valid_o, device->"$inf"_valid_o);" >> "$3"/"$2"_tb.h
    fi
    
    for sig in $sigs; do
        printf "\
        
            if(device->"$sig" != cmodel->"$sig") {
                %s
                exit(1);
            }
        " "printf(\"ERROR: "$sig" mismatch, CMODEL 0x%lX, RTL 0x%lX\n\", cmodel->"$sig", device->"$sig");" >> "$3"/"$2"_tb.h
    done
    
    if [ $ctrl = "VALID" ]
    then
        printf "\
        
            }
        " >> "$3"/"$2"_tb.h
    fi
    
    printf "\
    
        }
    " >> "$3"/"$2"_tb.h
    
done

printf "\

        // input signals
" >> "$3"/"$2"_tb.h

for sig in $sig_in; do
    printf "\
    
        void write_"$sig"(uint64_t "$sig"){
            device->"$sig" = "$sig";
            cmodel->"$sig" = "$sig";
        }
    " >> "$3"/"$2"_tb.h
done

printf "\

        // output signals
" >> "$3"/"$2"_tb.h

for sig in $sig_out; do
    printf "\
    
        uint64_t read_"$sig"(bool cm){
            return cm ? cmodel->"$sig" : device->"$sig";
        }
    " >> "$3"/"$2"_tb.h
done

printf "\

};

#endif
" >> "$3"/"$2"_tb.h
