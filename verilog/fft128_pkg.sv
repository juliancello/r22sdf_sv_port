// Reference DFT implementation for verification
// plus a few useful complex number functions
// Written by Navid Shamszadeh

package dft128_pkg;

localparam WIDTH = 16;
localparam N = 128;

// useful typedefs
typedef struct {
    real re;
    real im;
} complex_t;

// define array types for function returns
typedef complex_t complex_128_t[128];

// helper functions for complex numbers
// I ended not not using any of them
// but they might be useful in the future,
// probably not though...
function automatic real re(input complex_t x);
    return x.re;
endfunction

function automatic real im(input complex_t x);
    return x.im;
endfunction

function automatic complex_t complex_add(
    input complex_t x, y
);
    return '{re: re(x) + re(y), im: im(x) + im(y)};
endfunction

function automatic complex_t complex_mult(
    input complex_t x, y
);
    real real_part, imaginary_part;
    real arbr, arbi, aibr, aibi;
    // (a+jb)*(c+jd) => re = a*c - b*d, im = a*d + b*c
    arbr = re(x) * re(y);
    arbi = re(x) * im(y);
    aibr = im(x) * re(y);
    aibi = im(x) * im(y);
    real_part      = arbr - aibi;
    imaginary_part = arbi + aibr;
    return '{re: real_part, im: imaginary_part};
endfunction

// reference DFT bit-reverse function
// The DUT outputs data in bit-reversed order
// so we need to bit-reverse the indices for comparison
function automatic int bit_reverse_7(input int x);
    int y = 0;
    for (int i = 0; i < 7; i++)
        y = (y << 1) | ((x >> i) & 1);
    return y;
endfunction

// reference DFT implementation for verification
// no fancy FFT stuff, just straightforward DFT
function automatic complex_128_t reference_dft(
    input complex_128_t in,
    input real norm_factor // Note: DUT output is scaled by 1/N
);
    complex_t sum;
    complex_128_t out;
    real angle, c, s;
    int br;
    for (int k = 0; k < N; k++) begin
        sum.re = 0.0;
        sum.im = 0.0;
        for (int n = 0; n < N; n++) begin
            angle = -2.0 * $acos(-1.0) * k * n / N; // forward DFT
            c = $cos(angle);
            s = $sin(angle);
            // (a+jb)*(c+jd) => re = a*c - b*d, im = a*d + b*c
            sum.re += in[n].re * c - in[n].im * s;
            sum.im += in[n].re * s + in[n].im * c;
        end
        br = bit_reverse_7(k);
        out[br].re = sum.re * norm_factor;
        out[br].im = sum.im * norm_factor;
    end
    return out;
endfunction

endpackage
