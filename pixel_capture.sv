`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2025 05:16:28 PM
// Design Name: 
// Module Name: pixel_capture
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


module pixel_capture(
    input logic [7:0] D,
    input logic pclk,
    input logic vsync,
    input logic href,

    output logic [11:0] RGB,
    output logic [9:0] wr_addr,
    output logic wr_en
);

logic [7:0] byte1, byte2;
logic [3:0] red, green, blue;
logic [9:0] col_index; //tells us where we are horizontally, 0-639

// FSM states
enum logic [2:0] {
    IDLE,
    BYTE_1,
    BYTE_2,
    WRITE,
    COL_ADD,
    DONE
} pixel_state;

always_ff @ (posedge pclk) begin
    if (vsync) begin
        pixel_state <= IDLE;
        col_index <= 10'b0;
        wr_en <= 0;
    end else begin
        case(pixel_state)
            IDLE: begin
                wr_en <= 0;
                if(href) begin
                    pixel_state <= BYTE_1;
                    col_index <= 10'b0;
                end
            end

            BYTE_1: begin
                wr_en <= 0;
                if(href) begin
                    byte1 <= D;
                    pixel_state <= BYTE_2;
                end else begin
                    pixel_state <= IDLE;
                end
            end

            BYTE_2: begin
                wr_en <= 0;
                if(href) begin
                    byte2 <= D;
                    pixel_state <= WRITE;
                end else begin
                    pixel_state <= IDLE;
                end
            end

            WRITE: begin
                red <= byte1[3:0];
                green <= byte2[7:4];
                blue <= byte2[3:0];
                RGB <= {byte1[3:0], byte2[7:4], byte2[3:0]};
                wr_addr <= col_index;
                wr_en <= 1'b1;
                pixel_state <= COL_ADD;
            end

           COL_ADD: begin
                wr_en <= 0;
                if (col_index < 639) begin
                    col_index <= col_index + 1;
                    pixel_state <= BYTE_1;
                end else begin
                    pixel_state <= DONE;
                end
            end
            DONE: begin
                wr_en <= 0;
                if(!href) begin
                    col_index <= 10'b0;
                    pixel_state <= IDLE;
                end
            end
        endcase
    end
end

endmodule
