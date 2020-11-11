`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2020 08:25:02 PM
// Design Name: 
// Module Name: top_level
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


module top_level( input clk_100mhz,
                  input[15:0] sw,
                  input btnc, btnu, btnl, btnr, btnd,
                  output logic[3:0] vga_r,
                  output logic[3:0] vga_b,
                  output logic[3:0] vga_g,
                  output logic vga_hs,
                  output logic vga_vs,
                  output logic led16_b, led16_g, led16_r,
                  output logic led17_b, led17_g, led17_r,
                  output logic [15:0] led,
                  output logic ca, cb, cc, cd, ce, cf, cg, dp,  // segments a-g, dp
                  output logic[7:0] an    // Display location 0-7
             
    );
    
    parameter ONE_HZ_PERIOD = 65_000_000;
    parameter DEBOUNCE_COUNT = 1000000;
    
    logic timer_start, counting, expired, one_hz_enable, count;
	logic [3:0] minutes, tens, ones;
    
    
    //create 65 MHz clock for 1024 x 768 VGA graphics
    clk_wiz_0 clkdivider (.clk_in1(clk_100mhz), .clk_out1(clk_65mhz));
    
    
    //  instantiate 7-segment display; display (8) 4-bit hex
    logic [31:0] data;      
    logic [6:0] segments;
    assign {cg, cf, ce, cd, cc, cb, ca} = segments[6:0];
    assign data[3:0] = ones;
    assign data[7:4] = tens;
    assign data[11:8] = minutes;
    
    display_8hex display_mod (.clk_in(clk_65mhz), .data_in(data),
	.seg_out({cg, cf, ce, cd, cc, cb, ca}), .strobe_out(an));
	
	
	debounce #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) db1 (.reset_in(sw[15]), .clock_in(clk_65mhz), .noisy_in(btnc),.clean_out(timer_start));
	timer #(.ONE_HZ_PERIOD(ONE_HZ_PERIOD)) t1 (.clock(clk_65mhz), .start_timer(timer_start),  .value(12'd150), .counting(counting), 
	 .expired_pulse(expired), .one_hz(one_hz_enable), .count_out(count), .ones(ones), .tens(tens), .minutes(minutes));
	 
	
	
    
    
    
    
endmodule


///////////////8 hex Display///////////////////////
module display_8hex(
    input clk_in,                 // system clock
    input [31:0] data_in,         // 8 hex numbers, msb first
    output logic [6:0] seg_out,     // seven segment display output
    output logic [7:0] strobe_out   // digit strobe
    );

    localparam bits = 13;
     
    logic [bits:0] counter = 0;  // clear on power up
     
    logic [6:0] segments[15:0]; // 16 7 bit memorys
    assign segments[0]  = 7'b100_0000;  // inverted logic
    assign segments[1]  = 7'b111_1001;  // gfedcba
    assign segments[2]  = 7'b010_0100;
    assign segments[3]  = 7'b011_0000;
    assign segments[4]  = 7'b001_1001;
    assign segments[5]  = 7'b001_0010;
    assign segments[6]  = 7'b000_0010;
    assign segments[7]  = 7'b111_1000;
    assign segments[8]  = 7'b000_0000;
    assign segments[9]  = 7'b001_1000;
    assign segments[10] = 7'b000_1000;
    assign segments[11] = 7'b000_0011;
    assign segments[12] = 7'b010_0111;
    assign segments[13] = 7'b010_0001;
    assign segments[14] = 7'b000_0110;
    assign segments[15] = 7'b000_1110;
     
    always_ff @(posedge clk_in) begin
      // Here I am using a counter and select 3 bits which provides
      // a reasonable refresh rate starting the left most digit
      // and moving left.
      counter <= counter + 1;
      case (counter[bits:bits-2])
          3'b000: begin  // use the MSB 4 bits
                  seg_out <= segments[data_in[31:28]];
                  strobe_out <= 8'b0111_1111 ;
                 end

          3'b001: begin
                  seg_out <= segments[data_in[27:24]];
                  strobe_out <= 8'b1011_1111 ;
                 end

          3'b010: begin
                   seg_out <= segments[data_in[23:20]];
                   strobe_out <= 8'b1101_1111 ;
                  end
          3'b011: begin
                  seg_out <= segments[data_in[19:16]];
                  strobe_out <= 8'b1110_1111;        
                 end
          3'b100: begin
                  seg_out <= segments[data_in[15:12]];
                  strobe_out <= 8'b1111_0111;
                 end

          3'b101: begin
                  seg_out <= segments[data_in[11:8]];
                  strobe_out <= 8'b1111_1011;
                 end

          3'b110: begin
                   seg_out <= segments[data_in[7:4]];
                   strobe_out <= 8'b1111_1101;
                  end
          3'b111: begin
                  seg_out <= segments[data_in[3:0]];
                  strobe_out <= 8'b1111_1110;
                 end

       endcase
      end

endmodule


