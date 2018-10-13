`default_nettype none

/* 
 * GMSK modulator
 *
 * We use the scheme explained in Linz1996 (doi://10.1109/82.481470). We
 * ingest data and use logic to generate addresses into a ROM with successive
 * samples of Gaussian-filtered sines. Symmetries are exploited to reduce ROM
 * size requirements, thus signs of ROM entries are fixed-up before being
 * output as I and Q samples. 
 *
 *
 * I am unsure whether this needs any kind of post-filtering, so please do not
 * emit RF with this!
*/

module gmsk_tx
(
    input wire clock,
    input wire symbol_strobe,
    input wire sample_strobe,
    input wire input_bit,

    /* verilator lint_off UNUSED */
    input wire clk_en,
    /* verilator lint_on UNUSED */

    output reg [(ROM_OUTPUT_BITS-1):0] inphase_out,
    output reg [(ROM_OUTPUT_BITS-1):0] quadrature_out
//    output reg inphase_strobe,
//    output reg quadrature_strobe
);

    // XXX make sure this works with GSM data rate and clock, clock dividers
    // of system, check numerology!

    // XXX be very careful about whether to do sign fixup by setting the top bit or
    // by doing a proper 2s complement negation. endpoints and edge cases need
    // to be verified as properly handled since we need zero discontinuities.
    //
    //
    // XXX DANGER XXX be careful about 2s complement asymmetry concerns whilst
    // negating the output of the ROM tables

    localparam ROM_INDEX_BITS  = 7;
    localparam ROM_SIZE = 2 ** ROM_INDEX_BITS;

    localparam ROM_OUTPUT_BITS = 8;

    reg [(ROM_OUTPUT_BITS-1):0] master_curve_1 [0:(ROM_SIZE-1)];
    initial $readmemh("../gen/gmsk_curve_1.hex",master_curve_1);

    reg [(ROM_OUTPUT_BITS-1):0] master_curve_2 [0:(ROM_SIZE-1)];
    initial $readmemh("../gen/gmsk_curve_2.hex",master_curve_2);

    reg [(ROM_OUTPUT_BITS-1):0] master_curve_3 [0:(ROM_SIZE-1)];
    initial $readmemh("../gen/gmsk_curve_3.hex",master_curve_3);

    reg [(ROM_OUTPUT_BITS-1):0] master_curve_7 [0:(ROM_SIZE-1)];
    initial $readmemh("../gen/gmsk_curve_7.hex",master_curve_7);

    reg [(ROM_INDEX_BITS-1):0] index_rising;
    reg [(ROM_INDEX_BITS-1):0] index_falling;

    reg [(ROM_OUTPUT_BITS-1):0] sample_reversed;
    reg [(ROM_OUTPUT_BITS-1):0] sample_forward;
    /* verilator lint_off UNUSED */

    reg [(ROM_OUTPUT_BITS-1):0] inphase_tmp;
    reg [(ROM_OUTPUT_BITS-1):0] quadrature_tmp;
    /* verilator lint_on UNUSED */


    reg [2:0] tristimulus;

//    reg [1:0] phase_quadrant_acc;

    reg debug_strobe;
    always @ (posedge clock) begin
        if (symbol_strobe == 1) begin /* XXX replace with pattern match*/
            debug_strobe <= ~debug_strobe;

            index_rising  <= 0;
            index_falling <= ROM_SIZE-1;
            tristimulus <= {tristimulus[1:0], input_bit};
        end // if (symbol_strobe == 1)
        if (sample_strobe == 1) begin
            index_rising <= index_rising + 1;
            index_falling <= index_falling - 1;

            case (tristimulus)
                3'b000: sample_forward <= master_curve_7[index_rising];
                3'b001: sample_forward <= master_curve_1[index_rising];
                3'b010: sample_forward <= master_curve_2[index_rising];
                3'b011: sample_forward <= master_curve_3[index_rising];
                3'b100: sample_forward <= master_curve_3[index_rising];
                3'b101: sample_forward <= master_curve_2[index_rising];
                3'b110: sample_forward <= master_curve_1[index_rising];
                3'b111: sample_forward <= master_curve_7[index_rising];
            endcase // tristimulus
            case (tristimulus)
                3'b000: sample_reversed <= master_curve_7[index_rising];
                3'b001: sample_reversed <= master_curve_3[index_rising];
                3'b010: sample_reversed <= master_curve_2[index_rising];
                3'b011: sample_reversed <= master_curve_1[index_rising];
                3'b100: sample_reversed <= master_curve_1[index_rising];
                3'b101: sample_reversed <= master_curve_2[index_rising];
                3'b110: sample_reversed <= master_curve_3[index_rising];
                3'b111: sample_reversed <= master_curve_7[index_rising];
            endcase // tristimulus
            inphase_out <= sample_forward;
            quadrature_out <= sample_reversed;
        end // if (sample_strobe == 1)

    end // always @ (posedge clock)




endmodule
