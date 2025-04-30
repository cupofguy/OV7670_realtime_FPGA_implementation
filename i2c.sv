`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2025 02:02:03 PM
// Design Name: 
// Module Name: i2c
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


module i2c(

        input logic clk, // prob 100 MHz
        input logic rst_n,
        input logic start, //make this be like a button on fgpa that starts bootup seqeunce
        
        inout logic sda,        //serial data bi-directional
        
        output logic scl,           //serial clk
        output logic done, 
        output logic busy



    );
    
logic [7:0] ROM_index;
logic [15:0] ROM_word;

camera_config_ROM camera_config_inst(

    .i_clk(clk),
    .i_rstn(rst_n),
    .i_addr(ROM_index),
    .o_dout(ROM_word)
    
    );
    
// Internal state machine states
enum logic [3:0] {
    IDLE,
    LOAD_NEXT,
    START,
    SEND_DEVICE_ADDR,
    SEND_REG_ADDR,
    SEND_DATA,
    STOP,
    DONE
} state;

// I2C bit-level control
logic [7:0] byte_to_send;
logic [2:0] bit_index;
logic bit_phase; // 0 = setup SDA, 1 = raise SCL

// SDA open-drain logic
logic sda_out;
logic sda_drive_en;
assign sda = sda_drive_en ? sda_out : 1'bz;
logic [1:0] s_count;
logic [1:0] s_count1;

parameter integer CLK_DIV = 250;  // for 400 kHz SCL with 100 MHz clk

logic [8:0] tick_counter = 0;
logic scl_tick;
logic start_latched;


assign done_write = done;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tick_counter <= 0;
        scl_tick <= 0;
    end else begin
        if (tick_counter == CLK_DIV - 1) begin
            tick_counter <= 0;
            scl_tick <= 1;
        end else begin
            tick_counter <= tick_counter + 1;
            scl_tick <= 0;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_latched <= 1'b0;
    end
    else if (start) begin
        start_latched <= 1'b1;
     end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        done <= 0;
        busy <= 0;
        sda_drive_en <= 1;
        sda_out <= 1;
        scl <= 1;
        ROM_index <= 0;
        bit_index <= 0;
        s_count <= 0;
        s_count1 <= 0;
        bit_phase <= 0;
    end else begin
        case (state)
            IDLE: begin
               if (ROM_index >= 79) begin
                 done <= 1;
               end
               else begin
                done <= 0;
               end
                busy <= 0;
                sda_out <= 1;
                scl <= 1;
                if (start_latched) begin
                    state <= LOAD_NEXT;
                    busy <= 1;
                end
            end

            LOAD_NEXT: begin
                if (ROM_index >= 79) begin
                    state <= DONE;              
                end else begin
                    byte_to_send <= 8'h42;
                    s_count <= 0;
                    bit_index <= 0;
                    bit_phase <= 0;
                    state <= START;
                end
            end

            START: begin
                if(scl_tick) begin
                    if(s_count == 0) begin
                        sda_drive_en <= 1;
                        sda_out <= 1;
                        scl <= 1;
                        s_count <= 1;
                    end else if(s_count == 1) begin
                        sda_out <= 0;
                        s_count <= 2;
                    end else if(s_count == 2) begin
                        scl <= 0;
                        s_count <= 0;
                        state <= SEND_DEVICE_ADDR;
                    end
                end
            end

            SEND_DEVICE_ADDR: begin
                if(scl_tick) begin
                    if (!bit_phase) begin
                        sda_out <= byte_to_send[7 - bit_index];
                        sda_drive_en <= 1;
                        scl <= 0;
                        bit_phase <= 1;
                    end else begin
                        scl <= 1;
                        bit_phase <= 0;
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            sda_drive_en <= 0;
                            byte_to_send <= ROM_word[15:8];
                            state <= SEND_REG_ADDR;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end
            end

            SEND_REG_ADDR: begin
                if(scl_tick) begin
                    if (!bit_phase) begin
                        sda_out <= byte_to_send[7 - bit_index];
                        sda_drive_en <= 1;
                        scl <= 0;
                        bit_phase <= 1;
                    end else begin
                        scl <= 1;
                        bit_phase <= 0;
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            sda_drive_en <= 0;
                            byte_to_send <= ROM_word[7:0];
                            state <= SEND_DATA;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end
            end

            SEND_DATA: begin
                if(scl_tick) begin
                    if (!bit_phase) begin
                        sda_out <= byte_to_send[7 - bit_index];
                        sda_drive_en <= 1;
                        scl <= 0;
                        bit_phase <= 1;
                    end else begin
                        scl <= 1;
                        bit_phase <= 0;
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            sda_drive_en <= 0;
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end
            end

            STOP: begin
                if(scl_tick) begin
                    if(s_count1 == 0) begin
                        sda_drive_en <= 1;
                        sda_out <= 0;
                        scl <= 0;
                        s_count1 <= 1;
                    end else if(s_count1 == 1) begin
                        scl <= 1;
                        s_count1 <= 2;
                    end else if(s_count1 == 2) begin
                        sda_out <= 1;
                        s_count1 <= 0;
                        ROM_index <= ROM_index + 1;
                        state <= LOAD_NEXT;
                    end
                end
            end

            DONE: begin
                busy <= 0;
                done <= 1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule
