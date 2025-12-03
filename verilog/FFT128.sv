//----------------------------------------------------------------------
//  FFT: 128-Point FFT Using Radix-2^2 Single-Path Delay Feedback
//----------------------------------------------------------------------
module FFT #(
    parameter   WIDTH = 16
)(
    input logic               clock,  //  Master Clock
    input logic               reset,  //  Active High Asynchronous Reset
    input logic              di_en,  //  Input Data Enable
    input logic  [WIDTH-1:0] di_re,  //  Input Data (Real)
    input logic  [WIDTH-1:0] di_im,  //  Input Data (Imag)
    output logic             do_en,  //  Output Data Enable
    output logic [WIDTH-1:0] do_re,  //  Output Data (Real)
    output logic  [WIDTH-1:0] do_im   //  Output Data (Imag)
);
//----------------------------------------------------------------------
//  Data must be input consecutively in natural order.
//  The result is scaled to 1/N and output in bit-reversed order.
//  The output latency is 137 clock cycles.
//----------------------------------------------------------------------

logic            su1_do_en;
logic[WIDTH-1:0] su1_do_re;
logic[WIDTH-1:0] su1_do_im;
logic            su2_do_en;
logic[WIDTH-1:0] su2_do_re;
logic[WIDTH-1:0] su2_do_im;
logic            su3_do_en;
logic[WIDTH-1:0] su3_do_re;
logic[WIDTH-1:0] su3_do_im;

SdfUnit #(.N(128),.M(128),.WIDTH(WIDTH)) SU1 (
    .clock  (clock      ),  //  i
    .reset  (reset      ),  //  i
    .di_en  (di_en      ),  //  i
    .di_re  (di_re      ),  //  i
    .di_im  (di_im      ),  //  i
    .do_en  (su1_do_en  ),  //  o
    .do_re  (su1_do_re  ),  //  o
    .do_im  (su1_do_im  )   //  o
);

SdfUnit #(.N(128),.M(32),.WIDTH(WIDTH)) SU2 (
    .clock  (clock      ),  //  i
    .reset  (reset      ),  //  i
    .di_en  (su1_do_en  ),  //  i
    .di_re  (su1_do_re  ),  //  i
    .di_im  (su1_do_im  ),  //  i
    .do_en  (su2_do_en  ),  //  o
    .do_re  (su2_do_re  ),  //  o
    .do_im  (su2_do_im  )   //  o
);

SdfUnit #(.N(128),.M(8),.WIDTH(WIDTH)) SU3 (
    .clock  (clock      ),  //  i
    .reset  (reset      ),  //  i
    .di_en  (su2_do_en  ),  //  i
    .di_re  (su2_do_re  ),  //  i
    .di_im  (su2_do_im  ),  //  i
    .do_en  (su3_do_en  ),  //  o
    .do_re  (su3_do_re  ),  //  o
    .do_im  (su3_do_im  )   //  o
);

SdfUnit2 #(.WIDTH(WIDTH)) SU4 (
    .clock  (clock      ),  //  i
    .reset  (reset      ),  //  i
    .di_en  (su3_do_en  ),  //  i
    .di_re  (su3_do_re  ),  //  i
    .di_im  (su3_do_im  ),  //  i
    .do_en  (do_en      ),  //  o
    .do_re  (do_re      ),  //  o
    .do_im  (do_im      )   //  o
);

endmodule
