`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2020 01:33:37 AM
// Design Name: 
// Module Name: lose_graphics
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


module lose_graphics (
   input vclock_in,        // 65MHz clock
   input reset_in,         // 1 to initialize module
   input [10:0] hcount_in, // horizontal index of current pixel (0..1023)
   input [9:0]  vcount_in, // vertical index of current pixel (0..767)
   input hsync_in,         // XVGA horizontal sync signal (active low)
   input vsync_in,         // XVGA vertical sync signal (active low)
   input blank_in,         // XVGA blanking (1 means output black pixel)
   input confirm,
   
   output logic confirmed,
   output logic phsync_out,       // pong game's horizontal sync
   output logic pvsync_out,       // pong game's vertical sync
   output logic pblank_out,       // pong game's blanking
   output logic [11:0] pixel_out  // pong game's pixel  // r=11:8, g=7:4, b=3:0
   );

   assign phsync_out = hsync_in;
   assign pvsync_out = vsync_in;
   assign pblank_out = blank_in;
   assign confirmed = confirm;
   
   logic color_switch;
   logic [31:0] counter;
   always_ff @(posedge vclock_in)begin
        if (reset_in) begin
            color_switch <= 0;
            counter <= 0;
        end else begin                
            if (counter > 40000000)begin
                color_switch <= ~color_switch;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end
   
   logic [11:0] lose_pixel;
   lose_blob lb (.pixel_clk_in(vclock_in),.x_in(240),.hcount_in(hcount_in), 
           .y_in(110), .vcount_in(vcount_in), .pixel_out(lose_pixel));
           
   logic [11:0] try_pixel1;
   try_blob_graphics tb (.pixel_clk_in(vclock_in),.x_in(337),.hcount_in(hcount_in), 
           .y_in(420), .vcount_in(vcount_in), .pixel_out(try_pixel1));
   
   logic [11:0] blink1_pixel;
   blob #(.WIDTH(40),.HEIGHT(57),.COLOR(12'b0100_1111_0000))   // yellow!
          paddle1(.x_in(697),.y_in(425),.hcount_in(hcount_in),.vcount_in(vcount_in),
          .pixel_out(blink1_pixel));
   
   always_comb begin
        if (color_switch == 0) begin
            pixel_out = blink1_pixel | lose_pixel | try_pixel1;
        end else begin
            pixel_out = lose_pixel | try_pixel1;
        end
   end
   
   
     
endmodule