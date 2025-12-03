//----------------------------------------------------------------------
//  DelayBuffer: Generate Constant Delay
//----------------------------------------------------------------------
module DelayBuffer
#(
    parameter   DEPTH = 32,
    parameter   WIDTH = 16
)(
    input clock,  //  Master Clock
    input logic  [WIDTH-1:0] di_re,  //  Data Input (Real)
    input logic  [WIDTH-1:0] di_im,  //  Data Input (Imag)
    output logic  [WIDTH-1:0] do_re,  //  Data Output (Real)
    output logic [WIDTH-1:0] do_im   //  Data Output (Imag)
);

logic [WIDTH-1:0] buf_re[0:DEPTH-1];
logic [WIDTH-1:0] buf_im[0:DEPTH-1];

//  Shift Buffer
always_ff @(posedge clock) begin
    for (int n = DEPTH-1; n > 0; n = n - 1) begin
        buf_re[n] <= buf_re[n-1];
        buf_im[n] <= buf_im[n-1];
    end
    buf_re[0] <= di_re;
    buf_im[0] <= di_im;
end

assign  do_re = buf_re[DEPTH-1];
assign  do_im = buf_im[DEPTH-1];

endmodule
