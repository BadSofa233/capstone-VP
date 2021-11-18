// this is the RTL for a vtage predictor back, which holds P_NUM_ENTRIES number of entries
// this block controls the bus of the predictor
// Author: Yuhan Li
// Nov 14, 2021

module vtage_bank #(

) (

);

    generate
        for(genvar i = 0; i < P_NUM_ENTRIES; i = i + 1) begin : gen_vtage_entry
            vtage_entry #(
                
            ) vtage_entry (
            
            );
        end
    endgenerate

endmodule