# Verilog Mersenne Twister Readme

For more information and updates: http://alexforencich.com/wiki/en/verilog/mersenne/start

GitHub repository: https://github.com/alexforencich/verilog-mersenne

## Introduction

This is an implementation of the Mersenne Twister pseudorandom number
generator, written in Verilog with MyHDL testbenches.

## Documentation

The main code exists in the rtl subdirectory.  The 32 bit and 64 bit
implementations are contained entirely in the files axis_mt19937.v and
axis_mt19937_64.v, respectively.  The axis_mt19937 implements the 32-bit
mt19937ar algorithm while the axis_mt19937_64 module implements the 64-bit
mt19937-64 algorithm.  The only interface difference is the width of the AXI
stream interface.  After initialization, both cores can output data on every
clock cycle.

The AXI stream interface is a very standard parallel bus.  The data output is
carried by the tdata signal while the tvalid and tready signals perform the
handshaking.  The data on tdata is valid while tvalid is asserted, and it is
held until tready is asserted.  Data is only transferred when both tvalid and
tready are asserted.

Seeding the PRNG can be done simply by placing the seed value on the seed_val
input and then providing a single cycle pulse on seed_start.  The seed
operation takes a rather long time due to the fact that the seed routine uses
a serialized multiplication for minimum resource utilization.  The module will
assert the busy output while the seed operation is running, and additional
seed_start pulses will be ignored until the seed operation completes.  A seed
operation with the default seed of 5489 will start automatically on the first
read attempt on the AXI bus if a seed operation has not yet taken place.

### Source Files

    rtl/axis_mt19937.v     : 32 bit MT implementation, mt19937ar
    rtl/axis_mt19937_64.v  : 64 bit MT implementation, mt19937-64

### AXI Stream Interface Example

two byte transfer with sink pause after each byte

              __    __    __    __    __    __    __    __    __
    clk    __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                    _____ _________________
    tdata  XXXXXXXXX_D0__X_D1______________XXXXXXXXXXXXXXXXXXXXXXXX
                    _______________________
    tvalid ________/                       \_______________________
           ______________             _____             ___________
    tready               \___________/     \___________/


## Testing

Running the included testbenches requires MyHDL and Icarus Verilog.  Make sure
that myhdl.vpi is installed properly for cosimulation to work correctly.  The
testbenches can be run with a Python test runner like nose or py.test, or the
individual test scripts can be run with python directly.

### Testbench Files

    tb/axis_ep.py               : MyHDL AXI Stream endpoints
    tb/mt19937.py               : Reference Python implementation of mt19937ar
    tb/mt19937_64.py            : Reference Python implementation of mt19937-64
    tb/test_axis_mt19937.py     : MyHDL testbench for axis_mt19937 module
    tb/test_axis_mt19937.v      : Verilog toplevel file for axis_mt19937 cosimulation
    tb/test_axis_mt19937_64.py  : MyHDL testbench for axis_mt19937_64 module
    tb/test_axis_mt19937_64.v   : Verilog toplevel file for axis_mt19937_64 cosimulation
