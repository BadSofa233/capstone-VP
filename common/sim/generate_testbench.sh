#usr/bin/bash

sig_in=$(grep input.*_i "$1"/../src/"$2".sv|grep -Po [_a-z]*_i)
sig_out=$(grep output.*_.*o "$1"/../src/"$2".sv|grep -Po [_a-z]*_[a-z]*o)

printf "\
// this is the auto generated testbench header\n\

#ifndef "${2^^}"_TB_H
#define "${2^^}"_TB_H

#include \"Vwrapper.h\"
#include \"V"$2".h\"
#include \"verilated.h\"\n
#include <inttypes.h>

class "${2^}"_tb : public Vwrapper<V"$2"> {
    public:
        "${2^}"_tb() : Vwrapper((char *)\""$2"_tb\") {

        }
        
        void final() {
            device->final();
        }
        
        // input signals
" > "$1""$2"_tb.h

for sig in $sig_in; do
    printf "\
    
        void write_"$sig"(uint64_t "$sig"){
            device->"$sig" = "$sig";
        }
    " >> "$1""$2"_tb.h
done

printf "\

        // output signals
" >> "$1""$2"_tb.h

for sig in $sig_out; do
    printf "\
    
        uint64_t read_"$sig"(){
            return device->"$sig";
        }
    " >> "$1""$2"_tb.h
done

printf "\

};

#endif
" >> "$1""$2"_tb.h


