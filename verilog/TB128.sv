//----------------------------------------------------------------------
//	TB: FftTop Testbench
// Verification Written by Navid Shamszadeh (original Verilog testbench only did simulation, no verification)
//----------------------------------------------------------------------
`timescale	1ns/1ns

import dft128_pkg::*;

module TB #(
    parameter int N = 128
);


localparam int NN = log2(N);   //  Count Bit Width of FFT Point

//	log2 constant function
function automatic integer log2;
    input integer x;
    integer value;
    begin
        value = x-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end
endfunction

//	Internal Regs and Nets
logic		clock;
logic		reset;
logic		di_en;
logic	[15:0]	di_re;
logic	[15:0]	di_im;
logic		do_en;
logic   [15:0]	do_re;
logic   [15:0]	do_im;

logic	[15:0]	imem[0:2*N-1];
logic   [15:0]	omem[0:2*N-1];

complex_128_t reference_in, reference_out;

//----------------------------------------------------------------------
//	Clock and Reset
//----------------------------------------------------------------------
always begin
    clock = 0; #10;
    clock = 1; #10;
end

initial begin
    reset = 0; #20;
    reset = 1; #100;
    reset = 0;
end

//----------------------------------------------------------------------
//	Functional Blocks
//----------------------------------------------------------------------

//	Input Control Initialize
initial begin
    wait (reset == 1);
    di_en = 0;
end

//	Output Data Capture
initial begin : OCAP
    integer		n;
    forever begin
        n = 0;
        while (do_en !== 1) @(negedge clock);
        while ((do_en == 1) && (n < N)) begin
            omem[2*n  ] = do_re;
            omem[2*n+1] = do_im;
            n = n + 1;
            @(negedge clock);
        end
    end
end

//----------------------------------------------------------------------
//	Tasks
//----------------------------------------------------------------------

task automatic GenerateRandomInputData(input bit real_only);
    real  r, im;
    real r_dec, im_dec;
    integer file;

    file = $fopen("input_random.txt", "w");
    if (!file) begin
        $display("Error! Could not open input_random.txt.");
        $finish;
    end
    for (int i = 0; i < N; i++) begin
        // generate random number between -1 and 1
        r = $rtoi(($urandom_range(0, 65535) / real'(32768) - 1.0) * (2.0**15));
        if (real_only) begin
            im = 0.0;
        end else begin
            im = $rtoi(($urandom_range(0, 65535) / real'(32768) - 1.0) * (2.0**15));
        end
        r_dec = r / real'(2**15);
        im_dec = im / real'(2**15);
        $fdisplay(file, "%h  %h  // %d  %f  %f", r, im, i, r_dec, im_dec);
        reference_in[i].re = r_dec;
        reference_in[i].im = im_dec;
    end
    $fclose(file);
    $display("Random input data generated in input_random.txt.");
endtask

task automatic LoadInputData;
    input[80*8:1] filename;
begin
    $readmemh(filename, imem);
end
endtask

task automatic GenerateInputWave();
    integer	n;
    di_en <= 1;
    for (n = 0; n < N; n = n + 1) begin
        di_re <= imem[2*n];
        di_im <= imem[2*n+1];
        @(posedge clock);
    end
    di_en <= 0;
    di_re <= 'bx;
    di_im <= 'bx;

endtask

task automatic SaveOutputData;
    input[80*8:1]	filename;
    integer			fp, n, m, i;
begin
    fp = $fopen(filename);
    m = 0;
    for (n = 0; n < N; n = n + 1) begin
        for (i = 0; i < NN; i = i + 1) m[NN-1-i] = n[i];
        $fdisplay(fp, "%h  %h  // %d", omem[2*m], omem[2*m+1], n[NN-1:0]);
    end
    $fclose(fp);
end
endtask

task automatic compute_reference_dft();
    begin
        reference_out = reference_dft(reference_in, 1.0 / real'(N));
    end
endtask

function abs(input real x);
    begin
        if (x < 0.0) abs = -x;
        else         abs = x;
    end
endfunction

task automatic compare_results();
    integer errors;
    //real tolerance_threshold = 10 * 2^-15;
    real tolerance_threshold = 4e-3;
    real err_re, err_im;
    real out_re_real, out_im_real;
    begin
        errors = 0;
        for (int n = 0; n < N; n = n + 1) begin
            out_re_real = real'($signed(omem[2*n])) / real'(2**15);
            out_im_real = real'($signed(omem[2*n+1])) / real'(2**15);
            err_re = abs(out_re_real - reference_out[n].re);
            err_im = abs(out_im_real - reference_out[n].im);
            if ((err_re > tolerance_threshold) || (err_im > tolerance_threshold)) begin
                $display("[MISMATCH] Index %0d: DUT Output = (%f, %f), Reference = (%f, %f), Errors = (%f, %f)",
                    n, out_re_real, out_im_real, reference_out[n].re, reference_out[n].im,
                    err_re, err_im);
                errors = errors + 1;
            end
        end
        if (errors == 0) begin
            $display("[PASSED] All output data match the reference.");
        end else begin
            $display("[FAILED] Total mismatches: %0d", errors);
        end
    end
endtask

//----------------------------------------------------------------------
//	Module Instances
//----------------------------------------------------------------------
FFT FFT (
    .clock	(clock	),	//	i
    .reset	(reset	),	//	i
    .di_en	(di_en	),	//	i
    .di_re	(di_re	),	//	i
    .di_im	(di_im	),	//	i
    .do_en	(do_en	),	//	o
    .do_re	(do_re	),	//	o
    .do_im	(do_im	)	//	o
);

//----------------------------------------------------------------------
//	Include Stimuli
//----------------------------------------------------------------------
`include "stim.sv"

endmodule
