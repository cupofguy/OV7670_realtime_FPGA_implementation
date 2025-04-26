`timescale 1ns / 1ps

module i2c_testbench;

  // Clock and input signals
  logic Clk;
  logic reset_n;
  logic start;

  // I2C lines
  wire scl;
  tri1 sda; // pull-up simulation for open-drain I2C
  logic sda_drv;
  logic sda_en;

  // Assign sda control
  assign sda = sda_en ? sda_drv : 1'bz;

  // DUT instantiation
  camera_top dut (
    .Clk(Clk),
    .start(start),
    .reset_n(reset_n),
    .sda(sda),
    .scl(scl)
  );

  // Clock generation: 100 MHz
  initial Clk = 1;
  always #5 Clk = ~Clk;

  initial begin
    // Initialize
    reset_n = 0;
    start = 0;
    sda_drv = 1;
    sda_en = 0;

    $display("Starting I2C camera config testbench...");
    $dumpfile("i2c_testbench.vcd");
    $dumpvars(0, i2c_testbench);

    // Hold reset low for 10 clock cycles
    repeat (10) @(posedge Clk);
    reset_n = 1;

    // Wait 20 more clock cycles before starting config
    repeat (20) @(posedge Clk);
    start = 1;
    repeat (10) @(posedge Clk);
    start = 0;

    // Wait until done
    wait (dut.i2c_inst.done);
    $display("I2C configuration sequence completed.");

    // Final delay then stop
    repeat (10) @(posedge Clk);
    $finish;
  end

endmodule