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
      
      input logic [7:0] D,
      
      input logic pclk,
      
      input logic vsync_camera,
      
      input logic href,
      
      inout logic sda,
      
      output logic scl,
      
      output logic led_output,
      
      output logic xclk,
      
      output logic reset_out,
      
      output logic locked1, //temp
      
      output logic vde1, //temp
      
      
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p

);


logic locked;

assign locked1 = locked;

logic clk_24MHz;
logic clk_25MHz;
logic clk_125MHz;

logic RESET_N;

assign reset_out = ~RESET_N;

logic START;
logic done;
logic busy;

assign xclk = clk_24MHz;


i2c i2c_inst (

    .clk(Clk),
    .rst_n(~RESET_N),
    .start(START),
    .sda(sda),
    .scl(scl),
    .done(done),
    .busy(busy)

);

assign led_output = done;

clk_wiz_0 clk_wiz (
        .clk_out1(clk_24MHz),
        .clk_out2(clk_25MHz),
        .clk_out3(clk_125MHz),
        .reset(RESET_N),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    
logic vsync_controller;

logic [11:0] RGB_data;
logic [16:0] wr_address;
logic [16:0] read_address;
logic wr_enable;
logic [11:0] pixel_write_out;
logic [11:0] pixel_read_out;  

logic [9:0] drawX, drawY;
logic hsync, vde;
    
//assign vde1 = (vde && scaled_x<9'd320 && scaled_y<8'd240);

pixel_capture p1 (
    .D(D),
    .pclk(pclk), //coemes from camera
    .vsync(vsync_camera), 
    .href(href), //comes from camera

    .RGB(RGB_data),
    .wr_addr(wr_address),
    .wr_en(wr_enable)
);

logic [16:0] read_addr;
//logic [8:0] scaled_x;
//logic [8:0] scaled_y;


//assign scaled_x = drawX[9:1]; // divide drawX by 4
//assign scaled_y = drawY[9:1]; // divide drawY by 4

// Stage 1: down-sample & register X/Y by 2 ? 0..319 / 0..239
logic [8:0]  scaled_x_r;
logic [7:0]  scaled_y_r;
always_ff @(posedge clk_25MHz) begin
    scaled_x_r <= drawX >> 1;   // 640?320 columns
    scaled_y_r <= drawY >> 1;   // 480?240 rows
end

// Stage 2: compute read address = y320 + x, pipelined
logic [16:0] mulA, mulB, sumAB;
logic [16:0] read_addr_r;
always_ff @(posedge clk_25MHz) begin
    // 320 = 256 + 64
    mulA        <= {scaled_y_r,8'd0};  // y<<8 = y256
    mulB        <= {scaled_y_r,6'd0};  // y<<6 = y* 64
    sumAB       <= mulA + mulB;        // = y*320
    read_addr_r <= sumAB + scaled_x_r; // final address
end


// Stage 3: register the BRAM output, then clamp to 320×240 region

logic frame_active;

logic [11:0] pixel_buf, pixel_out;
always_ff @(posedge clk_25MHz) begin
    pixel_buf <= pixel_read_out;
    if (!(frame_active && vde && drawX < 320 && drawY < 240))
        pixel_out <= 12'h000;
    else
        pixel_out <= pixel_buf;
end




//logic [16:0] mulA, mulB, sumAB;

//// stage 1: partial products
//always_ff @(posedge clk_25MHz) begin
//  mulA <= {scaled_y,8'd0};  // <<8 ? y256
//  mulB <= {scaled_y,6'd0};  // <<6 ? y64
//end

//// stage 2: combine them
//always_ff @(posedge clk_25MHz) begin
//  sumAB <= mulA + mulB;     // = y(256+64)=y320
//end

//// stage 3: final address
//always_ff @(posedge clk_25MHz) begin
//  read_address <= sumAB + scaled_x;
//end



//assign read_address = scaled_y * 320 + scaled_x;


//blk_mem_gen_0 bram (
////writing pixel data from camera and reading to HDMI
//    .addra(wr_address), //write address (rom index)
//    .clka(pclk),  //pclk (camera pixel clock)
//    .dina(RGB_data),  //
//    .douta(pixel_write_out), //
//    .ena(1'b1),  
//    .wea(wr_enable), //wr_en
    
   
//    .addrb(read_address), 
//    .clkb(clk_25MHz), //pixel_clk for HDMI stuff
//    .dinb(12'b0), //
//    .doutb(pixel_read_out), 
//    .enb(1'b1),  
//    .web(1'b0) 
    
    
//    );
    
    blk_mem_gen_1 bram (
//writing pixel data from camera and reading to HDMI
    .addra(wr_address), //write address (rom index)
    .clka(pclk),  //pclk (camera pixel clock)
    .dina(RGB_data),  //
    .douta(pixel_write_out), //
    .ena(1'b1),  
    .wea(wr_enable), //wr_en
    
   
    .addrb(read_addr_r), 
    .clkb(clk_25MHz), //pixel_clk for HDMI stuff
    .dinb(12'b0), //
    .doutb(pixel_read_out), 
    .enb(1'b1),  
    .web(1'b0) 
    
    
    );
    
    
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(RESET_N),
        .hs(hsync),
        .vs(vsync_controller),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );   
    
    
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(RESET_N), //active low
        //Color and Sync Signals
        .red(pixel_out[11:8]),
        .green(pixel_out[7:4]),
        .blue(pixel_out[3:0]),
        .hsync(hsync),
        .vsync(vsync_controller),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

//logic reset_db;

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
