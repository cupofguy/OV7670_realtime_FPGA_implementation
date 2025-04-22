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
        input logic reset_n,
        input logic start, //make this be like a button on fgpa that starts bootup seqeunce
        
        inout logic sda,        //serial data bi-directional
        
        output logic scl,           //serial clk
        output logic done, busy



    );
    
    
localparam int NUM_REGS = 24;

logic [7:0] config_array [0:NUM_REGS-1][1:0] = '{
    // Reset
    '{8'h12, 8'h80}, // COM7 - reset

    // Clock settings
    '{8'h11, 8'h01}, // CLKRC - prescaler / frame rate
    '{8'h6B, 8'h4A}, // PLL control

    // RGB565 output
    '{8'h12, 8'h14}, // COM7 - RGB output, QVGA
    '{8'h40, 8'hd0}, // COM15 - RGB565, full range
    '{8'h8C, 8'h02}, // RGB444 - disable RGB444, enable RGB565
    '{8'h3A, 8'h04}, // TSLB - set UV ordering, output format

    // Windowing for QVGA
    '{8'h17, 8'h16}, // HSTART
    '{8'h18, 8'h04}, // HSTOP
    '{8'h32, 8'ha4}, // HREF
    '{8'h19, 8'h02}, // VSTART
    '{8'h1A, 8'h7A}, // VSTOP
    '{8'h03, 8'h0A}, // VREF

    // Color matrix / gamma correction (basic)
    '{8'h4F, 8'h80},
    '{8'h50, 8'h80},
    '{8'h51, 8'h00},
    '{8'h52, 8'h22},
    '{8'h53, 8'h5E},
    '{8'h54, 8'h80},
    '{8'h58, 8'h9E},

    // Flip / mirror control
    '{8'h0C, 8'h00}, // COM3 - no flip/mirror

    // Auto white balance / gain control
    '{8'h13, 8'hE7}  // COM8 - AGC, AWB, AEC enabled
}; 
    
    // Internal state machine states
enum logic [3:0] {
    IDLE,
    LOAD_NEXT,
    START,
    SEND_DEVICE_ADDR,
    SEND_REG_ADDR,
    SEND_DATA,
    STOP,
    WAIT_,
    DONE
} state;
    
    
 // Register list (example: small config array)
//logic [7:0] config_array [0:N-1][1:0];  // [register][0=addr,1=data]
integer index = 0;

// Clock dividers for scl (e.g. 100kHz from 100MHz clk)
logic scl_tick;

// I2C bit-level control
logic [7:0] byte_to_send;
logic [2:0] bit_index;
logic ack_received;

// SDA open-drain logic
logic sda_out;
logic sda_drive_en;
assign sda = sda_drive_en ? sda_out : 1'bz;
logic sda_in = sda;
logic [1:0] s_count;      //counter for start sequence 
logic [2:0] reg_s_count;    //counter for sending reg address

// FSM pseudocode
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= IDLE;
        index <= 0;
        done <= 0;
        busy <= 0;
    end else begin
        case (state)
            IDLE: begin
                if (start) begin            //if button to start process pressed, start process
                    state <= LOAD_NEXT;
                    busy <= 1;
                end
            end

            LOAD_NEXT: begin
                if (index == NUM_REGS) begin        //once done going through all write data, end
                    state <= DONE;              
                end else begin
                    byte_to_send <= 8'h42; // Device address (write)
                    s_count <= 2'b00;       // reset internal counters
                    reg_s_count <= 3'b0;    //
                    state <= START;
                end
            end

            START: begin
                // Pull SDA low while SCL is high
                //do_start_condition();
                
                
                
                if(s_count == 0)                //buffer state for stability, makes sure line is actually idle
                    begin
                        sda_drive_en <= 1;
                        sda_out <= 1;
                        scl <= 1;
                        s_count <= 1;
                    end
                else if(s_count == 1)           //begin start process, set sda low first
                    begin
                        sda_drive_en <= 1'b0;
                        sda_in <= 1'b0;
                        s_count <= 2'b10;
                    end
                else if(s_count == 2)       //continue start process by setting scl low as well, atp can go to next state
                    begin
                        scl <= 0;
                        s_count <= 2'b0;
                        state <= SEND_DEVICE_ADDR;
                    end
                
                
                
            end

            SEND_DEVICE_ADDR: begin
                //send_byte(byte_to_send);
                //wait_for_ack();
//                byte_to_send <= config_array[index][0]; // reg addr
//                state <= SEND_REG_ADDR;
                  byte_to_send <= config_array[index][0];       //set byte to send equal to the correct reg value
                  
                  if(reg_s_count <= 3'b111)
                    begin
                    
                        sda_out <= byte_to_send[7];       //send msb of data on sda bus
                        sda_drive_en <= 1'b1;             //drive line
                        byte_to_send = byte_to_send << 1 ;  //left shift by one
                        reg_s_count <= reg_s_count + 1;     //increment counter
                    end
                 
                 
                 state <= SEND_REG_ADDR;
                  
                    
                    
            end

            SEND_REG_ADDR: begin
                send_byte(byte_to_send);
                wait_for_ack();
                byte_to_send <= config_array[index][1]; // reg data
                state <= SEND_DATA;
            end

            SEND_DATA: begin
                send_byte(byte_to_send);
                wait_for_ack();
                state <= STOP;
            end

            STOP: begin
                do_stop_condition();
                index <= index + 1;
                state <= WAIT_;
            end

            WAIT_: begin
                wait_some_cycles();
                state <= LOAD_NEXT;
            end

            DONE: begin
                busy <= 0;
                done <= 1;
            end
        endcase
    end
end
    
    
    
    
endmodule
