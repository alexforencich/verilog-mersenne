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
 * AXI4-Stream MT19937 Mersenne Twister
 */
module axis_mt19937
(
    input  wire         clk,
    input  wire         rst,

    /*
     * AXI output
     */
    output wire [31:0]  output_axis_tdata,
    output wire         output_axis_tvalid,
    input  wire         output_axis_tready,

    /*
     * Status
     */
    output wire         busy,

    /*
     * Configuration
     */
    input  wire [31:0]  seed_val,
    input  wire         seed_start
);

// state register
localparam [1:0]
    STATE_IDLE = 2'd0,
    STATE_SEED = 2'd1;

reg [1:0] state_reg = STATE_IDLE, state_next;

reg [31:0] mt [623:0];
reg [31:0] mt_save_reg = 0, mt_save_next;
reg [9:0] mti_reg = 625, mti_next;

reg [31:0] y1, y2, y3, y4, y5;

reg [9:0] mt_wr_ptr;
reg [31:0] mt_wr_data;
reg mt_wr_en;

reg [9:0] mt_rd_a_ptr_reg = 0, mt_rd_a_ptr_next;
reg [31:0] mt_rd_a_data = 0;

reg [9:0] mt_rd_b_ptr_reg = 0, mt_rd_b_ptr_next;
reg [31:0] mt_rd_b_data = 0;

reg [31:0] product_reg = 0, product_next;
reg [31:0] factor1_reg = 0, factor1_next;
reg [31:0] factor2_reg = 0, factor2_next;
reg [4:0] mul_cnt_reg = 0, mul_cnt_next;

reg [31:0] output_axis_tdata_reg = 0, output_axis_tdata_next;
reg output_axis_tvalid_reg = 0, output_axis_tvalid_next;

reg busy_reg = 0;

assign output_axis_tdata = output_axis_tdata_reg;
assign output_axis_tvalid = output_axis_tvalid_reg;

assign busy = busy_reg;

always @* begin
    state_next = 2'bz;

    mt_save_next = mt_save_reg;
    mti_next = mti_reg;

    mt_wr_data = 0;
    mt_wr_ptr = 0;
    mt_wr_en = 0;

    y1 = 32'bz;
    y2 = 32'bz;
    y3 = 32'bz;
    y4 = 32'bz;
    y5 = 32'bz;

    mt_rd_a_ptr_next = mt_rd_a_ptr_reg;
    mt_rd_b_ptr_next = mt_rd_b_ptr_reg;

    product_next = product_reg;
    factor1_next = factor1_reg;
    factor2_next = factor2_reg;
    mul_cnt_next = mul_cnt_reg;

    output_axis_tdata_next = output_axis_tdata_reg;
    output_axis_tvalid_next = output_axis_tvalid_reg & ~output_axis_tready;

    case (state_reg)
        STATE_IDLE: begin
            // idle state
            if (seed_start) begin
                mt_save_next = seed_val;
                product_next = 0;
                factor1_next = mt_save_next ^ (mt_save_next >> 30);
                factor2_next = 32'd1812433253;
                mul_cnt_next = 31;
                mt_wr_data = mt_save_next;
                mt_wr_ptr = 0;
                mt_wr_en = 1;
                mti_next = 1;
                state_next = STATE_SEED;
            end else if (output_axis_tready) begin
                if (mti_reg == 625) begin
                    mt_save_next = 32'd5489;
                    product_next = 0;
                    factor1_next = mt_save_next ^ (mt_save_next >> 30);
                    factor2_next = 32'd1812433253;
                    mul_cnt_next = 31;
                    mt_wr_data = mt_save_next;
                    mt_wr_ptr = 0;
                    mt_wr_en = 1;
                    mti_next = 1;
                    state_next = STATE_SEED;
                end else begin
                    if (mti_reg < 623)
                        mti_next = mti_reg + 1;
                    else
                        mti_next = 0;

                    if (mt_rd_a_ptr_reg < 623)
                        mt_rd_a_ptr_next = mt_rd_a_ptr_reg + 1;
                    else
                        mt_rd_a_ptr_next = 0;

                    if (mt_rd_b_ptr_reg < 623)
                        mt_rd_b_ptr_next = mt_rd_b_ptr_reg + 1;
                    else
                        mt_rd_b_ptr_next = 0;

                    mt_save_next = mt_rd_a_data;
                    y1 = {mt_save_reg[31], mt_rd_a_data[30:0]};
                    y2 = mt_rd_b_data ^ (y1 >> 1) ^ (y1[0] ? 32'h9908b0df : 32'h0);
                    y3 = y2 ^ (y2 >> 11);
                    y4 = y3 ^ ((y3 << 7) & 32'h9d2c5680);
                    y5 = y4 ^ ((y4 << 15) & 32'hefc60000);
                    output_axis_tdata_next = y5 ^ (y5 >> 18);
                    output_axis_tvalid_next = 1;
                    mt_wr_data = y2;
                    mt_wr_ptr = mti_reg;
                    mt_wr_en = 1;
                    state_next = STATE_IDLE;
                end
            end else begin
                state_next = STATE_IDLE;
            end
        end
        STATE_SEED: begin
            if (mul_cnt_reg == 0) begin
                if (mti_reg < 624) begin
                    //mt_save_next = 32'd1812433253 * (mt_save_reg ^ (mt_save_reg >> 30)) + mti_reg;
                    mt_save_next = product_reg + mti_reg;
                    product_next = 0;
                    factor1_next = mt_save_next ^ (mt_save_next >> 30);
                    factor2_next = 32'd1812433253;
                    mul_cnt_next = 31;
                    mt_wr_data = mt_save_next;
                    mt_wr_ptr = mti_reg;
                    mt_wr_en = 1;
                    mti_next = mti_reg + 1;
                    mt_rd_a_ptr_next = 0;
                    state_next = STATE_SEED;
                end else begin
                    mti_next = 0;
                    mt_save_next = mt_rd_a_data;
                    mt_rd_a_ptr_next = 1;
                    mt_rd_b_ptr_next = 397;
                    state_next = STATE_IDLE;
                end
            end else begin
                mul_cnt_next = mul_cnt_reg - 1;
                factor1_next = factor1_reg << 1;
                factor2_next = factor2_reg >> 1;
                if (factor2_reg[0]) product_next = product_reg + factor1_reg;
                state_next = STATE_SEED;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= STATE_IDLE;
        mti_reg <= 625;
        mt_rd_a_ptr_reg <= 0;
        mt_rd_b_ptr_reg <= 0;
        product_reg <= 0;
        factor1_reg <= 0;
        factor2_reg <= 0;
        mul_cnt_reg <= 0;
        output_axis_tdata_reg <= 0;
        output_axis_tvalid_reg <= 0;
        busy_reg <= 0;
    end else begin
        state_reg <= state_next;

        mt_save_reg = mt_save_next;
        mti_reg <= mti_next;

        mt_rd_a_ptr_reg <= mt_rd_a_ptr_next;
        mt_rd_b_ptr_reg <= mt_rd_b_ptr_next;

        product_reg <= product_next;
        factor1_reg <= factor1_next;
        factor2_reg <= factor2_next;
        mul_cnt_reg <= mul_cnt_next;

        output_axis_tdata_reg <= output_axis_tdata_next;
        output_axis_tvalid_reg <= output_axis_tvalid_next;

        busy_reg <= state_next != STATE_IDLE;

        if (mt_wr_en) begin
            mt[mt_wr_ptr] <= mt_wr_data;
        end

        mt_rd_a_data <= mt[mt_rd_a_ptr_next];
        mt_rd_b_data <= mt[mt_rd_b_ptr_next];

    end
end

endmodule
