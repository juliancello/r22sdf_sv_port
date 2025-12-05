
//----------------------------------------------------------------------
//  TwiddleConvert4: Convert Twiddle Value to Reduce Table Size to 1/4
// Modified by Frezewd Debebe
//----------------------------------------------------------------------
module TwiddleConvert4 #(
    parameter   int LOG_N = 6,      //  Address Bit Length
    parameter   int WIDTH = 16,     //  Data Bit Length
    parameter   bit TW_FF = 1,      //  Use Twiddle Output Register
    parameter   bit TC_FF = 1       //  Use Output Register
)(
    input   logic             clock,      //  Master Clock
    input   logic [LOG_N-1:0] tw_addr,    //  Twiddle Number
    input   logic [WIDTH-1:0] tw_re,      //  Twiddle Value (Real)
    input   logic [WIDTH-1:0] tw_im,      //  Twiddle Value (Imag)
    output  logic [LOG_N-1:0] tc_addr,    //  Converted Twiddle Number
    output  logic [WIDTH-1:0] tc_re,      //  Converted Twiddle Value (Real)
    output  logic [WIDTH-1:0] tc_im       //  Converted Twiddle Value (Imag)
);

//  Internal Nets
logic [LOG_N-1:0] ff_addr;
logic [LOG_N-1:0] sel_addr;
logic [WIDTH-1:0] mx_re;
logic [WIDTH-1:0] mx_im;
logic [WIDTH-1:0] ff_re;
logic [WIDTH-1:0] ff_im;

//  Convert Twiddle Number
assign  tc_addr[LOG_N-1:LOG_N-2] = 2'd0;
assign  tc_addr[LOG_N-3:0] = tw_addr[LOG_N-3:0];

//  Convert Twiddle Value
always_ff @(posedge clock) begin
    ff_addr <= tw_addr;
end
assign  sel_addr = TW_FF ? ff_addr : tw_addr;

always_comb begin
    if (sel_addr[LOG_N-3:0] == {LOG_N-2{1'b0}}) begin
        case (sel_addr[LOG_N-1:LOG_N-2])
        2'd0    : {mx_re, mx_im} = {{WIDTH{1'b0}}, {WIDTH{1'b0}}};
        2'd1    : {mx_re, mx_im} = {{WIDTH{1'b0}}, {1'b1,{WIDTH-1{1'b0}}}};
        default : {mx_re, mx_im} = {{WIDTH{1'bx}}, {WIDTH{1'bx}}};
        endcase
    end else begin
        case (sel_addr[LOG_N-1:LOG_N-2])
        2'd0    : {mx_re, mx_im} = { tw_re,  tw_im};
        2'd1    : {mx_re, mx_im} = { tw_im, -tw_re};
        2'd2    : {mx_re, mx_im} = {-tw_re, -tw_im};
        default : {mx_re, mx_im} = {{WIDTH{1'bx}}, {WIDTH{1'bx}}};
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
