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
        output logic done, busy



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
    
    
 // Register list (example: small config array)
//logic [7:0] config_array [0:N-1][1:0];  // [register][0=addr,1=data]
// Clock dividers for scl (e.g. 100kHz from 100MHz clk)


// I2C bit-level control
logic [7:0] byte_to_send;
logic [2:0] bit_index;

// SDA open-drain logic
logic sda_out;
logic sda_drive_en;
assign sda = sda_drive_en ? sda_out : 1'bz;
logic sda_in = sda;
logic [1:0] s_count;      //counter for start sequence 
logic [1:0] s_count1;
logic [2:0] reg_s_count;    //counter for sending reg address


parameter integer CLK_DIV = 250;  // for 400 kHz SCL with 100 MHz clk

logic [8:0] tick_counter = 0;           //this block of code splits our 100 MHz clk into a 400 khz clock compatible with i2c protocol
logic scl_tick;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tick_counter <= 0;
        scl_tick <= 0;
    end else begin
        if (tick_counter == CLK_DIV - 1) begin
            tick_counter <= 0;
            scl_tick <= 1; // pulse for 1 clock cycle
        end else begin
            tick_counter <= tick_counter + 1;
            scl_tick <= 0;
        end
    end
end

// FSM pseudocode
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
    end else begin
        case (state)
            IDLE: begin
                done <= 0;
                busy <= 0;
                sda_out <= 1;
                scl <= 1;
            
                  if (start) begin            //if button to start process pressed, start process
                    state <= LOAD_NEXT;
                    busy <= 1;
                  end
            end

            LOAD_NEXT: begin
                if (ROM_index >= 75) begin        //once done going through all write data, end
                    state <= DONE;              
                end else begin
                    byte_to_send <= 8'h42; // Device address (write)
                    s_count <= 2'b00;       // reset internal counters
                    bit_index <= 0;    //
                    state <= START;
                end
            end

            START: begin
                // Pull SDA low while SCL is high
                //do_start_condition()
               if(scl_tick) begin
                if(s_count == 0)                //buffer state for stability, makes sure line is actually idle
                    begin
                        sda_drive_en <= 1;
                        sda_out <= 1;
                        scl <= 1;
                        s_count <= 1;
                    end
                else if(s_count == 1)           //begin start process, set sda low first
                    begin
                        sda_out <= 1'b0;
                        s_count <= 2'b10;
                    end
                else if(s_count == 2)       //continue start process by setting scl low as well, atp can go to next state
                    begin
                        scl <= 0;
                        s_count <= 2'b0;
                        state <= SEND_DEVICE_ADDR;
                    end
                
                
                end
            end

            SEND_DEVICE_ADDR: begin
                //send_byte(byte_to_send);
                //wait_for_ack();
//                byte_to_send <= config_array[index][0]; // reg addr
//                state <= SEND_REG_ADDR;
                  
                  if(scl_tick) begin
                        if (bit_index < 8) begin
                    
                        sda_out <= byte_to_send[7 - bit_index];       //send msb of data on sda bus
                        sda_drive_en <= 1'b1;             //drive line
                        bit_index <= bit_index + 1;     //increment counter
                        scl <= 0;
                        end
                        
                   
                        else begin
                        bit_index <= 0;
                        sda_drive_en <= 0;
                        byte_to_send = ROM_word[15:8];
                        state <= SEND_REG_ADDR;
                        
                        end
                    end
              end

            SEND_REG_ADDR: begin
                //send_byte(byte_to_send);
                //wait_for_ack();
//                byte_to_send <= config_array[index][0]; // reg addr
//                state <= SEND_REG_ADDR;
//                  byte_to_send <= config_array[index];      //set byte to send equal to the correct reg value
                  
                  if(scl_tick) begin
                        if (bit_index < 8) begin
                    
                        sda_out <= byte_to_send[7 - bit_index];       //send msb of data on sda bus
                        sda_drive_en <= 1'b1;             //drive line
                        bit_index <= bit_index + 1;     //increment counter
                        scl <= 0;
                        end
                        
                    else begin
                        bit_index <= 0;
                        sda_drive_en <= 0;
                        byte_to_send = ROM_word[7:0];
                        state <= SEND_DATA;
                        
                        end
                   end
              end

            SEND_DATA: begin  
            
            if(scl_tick) begin
                        if (bit_index < 8) begin
                    
                        sda_out <= byte_to_send[7 - bit_index];       //send msb of data on sda bus
                        sda_drive_en <= 1'b1;             //drive line
                        bit_index <= bit_index + 1;     //increment counter
                        scl <= 0;
                        end
                        
                    else begin
                        bit_index <= 0;
                        sda_drive_en <= 0;
                        state <= STOP;
                        end
                        
                   end
                   
                   end     

            STOP: begin
                if(scl_tick) begin
                     if(s_count1 == 0)                //buffer state for stability, makes sure line is actually idle
                          begin
                        sda_drive_en <= 1;
                        sda_out <= 0;
                        scl <= 0;
                        s_count1 <= 1;
                    end
                        else if(s_count1 == 1)           //begin start process, set sda low first
                    begin
                        scl <= 1;
                        s_count1 <= 2'b10;
                    end
                        else if(s_count1 == 2)       //continue start process by setting scl low as well, atp can go to next state
                    begin
                        sda_out <= 1;
                        s_count1 <= 2'b0;
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