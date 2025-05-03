module camera_rom
    (   input logic        i_clk,
        input logic        i_rstn,
        input logic  [7:0] i_addr,
        output reg [15:0] o_dout
    );
    
    // Registers for OV7670 for configuration of RGB 444 
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) o_dout <= 0; 
        else begin 
            case(i_addr)
          0: o_dout <= 16'h12_80; // Reset
          1: o_dout <= 16'hFF_F0; // Delay
          2: o_dout <= 16'h15_00; // COM10 = 0x00 (disable outputs)
          3: o_dout <= 16'hFF_FF;
           default: o_dout <= 16'hFF_FF;         //mark end of ROM
            endcase
        end
    end
endmodule