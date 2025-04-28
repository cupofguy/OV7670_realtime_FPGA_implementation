`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2025 02:40:25 PM
// Design Name: 
// Module Name: test_button
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


module test_button(

input logic Clk,

input logic button,

output logic LED0

    );
logic debounced;

assign LED0 = debounced;

sync_debounce bd (
		.clk  (Clk),

		.d    (button),
		.q    (debounced) //intermiediate signals
	);

endmodule
