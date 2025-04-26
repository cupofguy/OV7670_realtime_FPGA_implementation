`timescale 1ns / 1ps

module pixel_capture_tb();

  logic [7:0] D;
  logic pclk;
  logic vsync;
  logic href;

  logic [11:0] RGB;
  logic [9:0] wr_addr;
  logic wr_en;

  // Instantiate the DUT
  pixel_capture dut (
    .D(D),
    .pclk(pclk),
    .vsync(vsync),
    .href(href),
    .RGB(RGB),
    .wr_addr(wr_addr),
    .wr_en(wr_en)
  );

  // Clock generation
  initial pclk = 0;
  always #5 pclk = ~pclk; // 100 MHz clock

  initial begin
    // Initialize
    D <= 8'h00;
    vsync <= 1;
    href <= 0;

    repeat (2) @(posedge pclk);
    vsync <= 0; // Release reset

    // Start first pixel (first byte)
    href <= 1;
    repeat (1) @(posedge pclk);
    
    D <= 8'hBC; // Red nibble = 0xC
    repeat (1) @(posedge pclk);

    // Second byte
    D <= 8'hDA; // Green = 0xD, Blue = 0xA
    repeat (3) @(posedge pclk);

    // Next pixel
    D <= 8'h45; // Red = 0x5
    repeat (1) @(posedge pclk);
    D <= 8'h61; // Green = 0x6, Blue = 0x1
    repeat (1) @(posedge pclk);

    // Simulate end of row
    href <= 0;
    repeat (2) @(posedge pclk);

    // Restart another row (optional)
    href <= 1;
    D <= 8'h23;
    repeat (1) @(posedge pclk);
    D <= 8'h89;
    repeat (1) @(posedge pclk);
    href <= 0;

    repeat (10) @(posedge pclk);
    $finish;
  end

endmodule
