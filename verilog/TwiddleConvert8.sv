//----------------------------------------------------------------------
//  TwiddleConvert8: Convert Twiddle Value to Reduce Table Size to 1/8
//----------------------------------------------------------------------
module TwiddleConvert8 #(
    parameter   LOG_N = 6,      //  Address Bit Length
    parameter   WIDTH = 16,     //  Data Bit Length
    parameter   TW_FF = 1,      //  Use Twiddle Output Register
    parameter   TC_FF = 1       //  Use Output Register
)(
    input               clock,      //  Master Clock
    input logic   [LOG_N-1:0] tw_addr,    //  Twiddle Number
    input logic  [WIDTH-1:0] tw_re,      //  Twiddle Value (Real)
    input logic  [WIDTH-1:0] tw_im,      //  Twiddle Value (Imag)
    output logic [LOG_N-1:0] tc_addr,    //  Converted Twiddle Number
    output logic [WIDTH-1:0] tc_re,      //  Converted Twiddle Value (Real)
    output logic [WIDTH-1:0] tc_im       //  Converted Twiddle Value (Imag)
);

//  Define Constants
localparam[WIDTH-1:0] COSMQ = (((32'h5A82799A<<1) >> (32-WIDTH)) + 1)>>1; // cos(-pi/4)
localparam[WIDTH-1:0] SINMH = 32'h80000000 >> (32-WIDTH); // sin(-pi/2)

//  Internal Nets
logic [LOG_N-1:0] ff_addr;
wire[LOG_N-1:0] sel_addr;
logic [WIDTH-1:0] mx_re;
logic [WIDTH-1:0] mx_im;
logic [WIDTH-1:0] ff_re;
logic [WIDTH-1:0] ff_im;

//  Convert Twiddle Number
assign  tc_addr[LOG_N-1:LOG_N-3] = 3'd0;
assign  tc_addr[LOG_N-4:0] = tw_addr[LOG_N-3] ? -tw_addr[LOG_N-4:0] : tw_addr[LOG_N-4:0];

//  Convert Twiddle Value
always_ff @(posedge clock) begin
    ff_addr <= tw_addr;
end
assign  sel_addr = TW_FF ? ff_addr : tw_addr;

always_comb begin
    if (sel_addr[LOG_N-4:0] == {LOG_N-3{1'b0}}) begin
        case (sel_addr[LOG_N-1:LOG_N-3])
        3'd0    : {mx_re, mx_im} <= {{WIDTH{1'b0}}, {WIDTH{1'b0}}};
        3'd1    : {mx_re, mx_im} <= { COSMQ       , -COSMQ       };
        3'd2    : {mx_re, mx_im} <= {{WIDTH{1'b0}},  SINMH       };
        3'd3    : {mx_re, mx_im} <= {-COSMQ       , -COSMQ       };
        default : {mx_re, mx_im} <= {{WIDTH{1'bx}}, {WIDTH{1'bx}}};
        endcase
    end else begin
        case (sel_addr[LOG_N-1:LOG_N-3])
        3'd0    : {mx_re, mx_im} <= { tw_re,  tw_im};
        3'd1    : {mx_re, mx_im} <= {-tw_im, -tw_re};
        3'd2    : {mx_re, mx_im} <= { tw_im, -tw_re};
        3'd3    : {mx_re, mx_im} <= {-tw_re,  tw_im};
        3'd4    : {mx_re, mx_im} <= {-tw_re, -tw_im};
        3'd5    : {mx_re, mx_im} <= { tw_im,  tw_re};
        default : {mx_re, mx_im} <= {{WIDTH{1'bx}}, {WIDTH{1'bx}}};
        endcase
    end
end
always_ff @(posedge clock) begin
    ff_re <= mx_re;
    ff_im <= mx_im;
end

assign  tc_re = TC_FF ? ff_re : mx_re;
assign  tc_im = TC_FF ? ff_im : mx_im;

endmodule
