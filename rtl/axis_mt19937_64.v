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
 * AXI4-Stream MT19937-64 Mersenne Twister
 */
module axis_mt19937_64
(
    input  wire         clk,
    input  wire         rst,

    /*
     * AXI output
     */
    output wire [63:0]  output_axis_tdata,
    output wire         output_axis_tvalid,
    input  wire         output_axis_tready,

    /*
     * Status
     */
    output wire         busy,

    /*
     * Configuration
     */
    input  wire [63:0]  seed_val,
    input  wire         seed_start
);

// state register
localparam [1:0]
    STATE_IDLE = 2'd0,
    STATE_SEED = 2'd1;

reg [1:0] state_reg = STATE_IDLE, state_next;

reg [63:0] mt [311:0];
reg [63:0] mt_save_reg = 0, mt_save_next;
reg [9:0] mti_reg = 313, mti_next;

reg [63:0] y1, y2, y3, y4, y5;

reg [9:0] mt_wr_ptr;
reg [63:0] mt_wr_data;
reg mt_wr_en;

reg [9:0] mt_rd_a_ptr_reg = 0, mt_rd_a_ptr_next;
reg [63:0] mt_rd_a_data = 0;

reg [9:0] mt_rd_b_ptr_reg = 0, mt_rd_b_ptr_next;
reg [63:0] mt_rd_b_data = 0;

reg [63:0] product_reg = 0, product_next;
reg [63:0] factor1_reg = 0, factor1_next;
reg [63:0] factor2_reg = 0, factor2_next;
reg [5:0] mul_cnt_reg = 0, mul_cnt_next;

reg [63:0] output_axis_tdata_reg = 0, output_axis_tdata_next;
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

    y1 = 64'bz;
    y2 = 64'bz;
    y3 = 64'bz;
    y4 = 64'bz;
    y5 = 64'bz;

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
                factor1_next = mt_save_next ^ (mt_save_next >> 62);
                factor2_next = 64'd6364136223846793005;
                mul_cnt_next = 63;
                mt_wr_data = mt_save_next;
                mt_wr_ptr = 0;
                mt_wr_en = 1;
                mti_next = 1;
                state_next = STATE_SEED;
            end else if (output_axis_tready) begin
                if (mti_reg == 313) begin
                    mt_save_next = 64'd5489;
                    product_next = 0;
                    factor1_next = mt_save_next ^ (mt_save_next >> 62);
                    factor2_next = 64'd6364136223846793005;
                    mul_cnt_next = 63;
                    mt_wr_data = mt_save_next;
                    mt_wr_ptr = 0;
                    mt_wr_en = 1;
                    mti_next = 1;
                    state_next = STATE_SEED;
                end else begin
                    if (mti_reg < 311)
                        mti_next = mti_reg + 1;
                    else
                        mti_next = 0;

                    if (mt_rd_a_ptr_reg < 311)
                        mt_rd_a_ptr_next = mt_rd_a_ptr_reg + 1;
                    else
                        mt_rd_a_ptr_next = 0;

                    if (mt_rd_b_ptr_reg < 311)
                        mt_rd_b_ptr_next = mt_rd_b_ptr_reg + 1;
                    else
                        mt_rd_b_ptr_next = 0;

                    mt_save_next = mt_rd_a_data;
                    y1 = {mt_save_reg[63:31], mt_rd_a_data[30:0]};
                    y2 = mt_rd_b_data ^ (y1 >> 1) ^ (y1[0] ? 64'hB5026F5AA96619E9 : 64'h0);
                    y3 = y2 ^ ((y2 >> 29) & 64'h5555555555555555) ;
                    y4 = y3 ^ ((y3 << 17) & 64'h71D67FFFEDA60000);
                    y5 = y4 ^ ((y4 << 37) & 64'hFFF7EEE000000000);
                    output_axis_tdata_next = y5 ^ (y5 >> 43);
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
                if (mti_reg < 312) begin
                    //mt_save_next = 64'd6364136223846793005 * (mt_save_reg ^ (mt_save_reg >> 62)) + mti_reg;
                    mt_save_next = product_reg + mti_reg;
                    product_next = 0;
                    factor1_next = mt_save_next ^ (mt_save_next >> 62);
                    factor2_next = 64'd6364136223846793005;
                    mul_cnt_next = 63;
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
                    mt_rd_b_ptr_next = 156;
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
        mti_reg <= 313;
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
