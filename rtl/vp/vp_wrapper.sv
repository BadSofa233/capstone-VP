// this is the wrapper for the value predictors
// Author:
// Nov 15 2021

module vp_wrapper #(
    parameter P_ALGORITHM = "VTAGE",    // algorithm to be instantiated
    parameter P_NUM_PRED = 2            // number of concurrent predictions
    // TODO: define more parameters for subblocks
) (
    // TODO: define input and output signals ...

);

// define logic and signals here
// logic a; // it's a signals
// logic b;

    generate 

        if(P_ALGORITHM == "VTAGE") begin
            vtage_top #(
                // TODO: input parameters to vtage here...
            ) vtage_top (
                // TODO: IO signals here, connect wrapper's IO to VP IO
                // .fw_pc_i(a),
                // .fw_gbh_i(b),
                // ...
            );
        end
        else if(P_ALGORITHM == "2D_STRIDE") begin
        
        end
        else if(P_ALGORITHM == "DFCM") begin
        
        end
        else if(P_ALGORITHM == "BASELINE") begin
            baseline_top #(
                // TODO: input parameters to vtage here...
            ) baseline_top (
                // TODO: IO signals here
                // .fw_pc_i(a),
                // .fw_gbh_i(b),
                // ...
            );
        end

    endgenerate

endmodule