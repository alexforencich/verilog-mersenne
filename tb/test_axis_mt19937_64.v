/*

Copyright (c) 2014-2016 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * Testbench axis_mt19937_64
 */
module test_axis_mt19937_64;

// Parameters


// Inputs
reg clk = 0;
reg rst = 0;
reg [7:0] current_test = 0;

reg [63:0] seed_val = 0;
reg seed_start = 0;
reg output_axis_tready = 0;

// Outputs
wire [63:0] output_axis_tdata;
wire output_axis_tvalid;
wire busy;

initial begin
    // myhdl integration
    $from_myhdl(
        clk,
        rst,
        current_test,
        seed_val,
        seed_start,
        output_axis_tready
    );
    $to_myhdl(
        output_axis_tdata,
        output_axis_tvalid,
        busy
    );

    // dump file
    $dumpfile("test_axis_mt19937_64.lxt");
    $dumpvars(0, test_axis_mt19937_64);
end

axis_mt19937_64
UUT (
    .clk(clk),
    .rst(rst),
    // AXI output
    .output_axis_tdata(output_axis_tdata),
    .output_axis_tvalid(output_axis_tvalid),
    .output_axis_tready(output_axis_tready),
    // Configuration
    .seed_val(seed_val),
    .seed_start(seed_start),
    // Status
    .busy(busy)
);

endmodule
