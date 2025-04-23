`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 06:57:01 PM
// Design Name: 
// Module Name: camera_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module camera_top(
    
        
      input logic Clk, 
        
      input logic start,
      
      input logic reset_n,
      
      inout logic sda,
      
      output logic scl
      
      

);


logic locked;
logic clk_24MHz;

logic RESET_N;

logic START;
logic done;
logic busy;

i2c i2c_inst (

    .clk(Clk),
    .rst_n(RESET_N),
    .start(START),
    .sda(sda),
    .scl(scl),
    .done(done),
    .busy(busy)

);



clk_wiz_0 clk_wiz (
        .clk_out1(clk_24MHz),
        .reset(RESET_N),
        .locked(locked),
        .clk_in1(Clk)
    );



sync_debounce reset (
		.clk  (Clk),

		.d    (reset_n),
		.q    (RESET_N) //intermiediate signals
	);
	
sync_debounce start1 (
		.clk  (Clk),

		.d    (start),
		.q    (START) //intermiediate signals
	);
	
endmodule
