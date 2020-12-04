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
                  output logic[7:0] an,    // Display location 0-7
                  inout tmp_scl,
                  inout tmp_sda,

                  input acl_miso,
                  output acl_mosi,
                  output acl_sclk,
                  output acl_csn
    );
    
    parameter ONE_HZ_PERIOD = 65_000_000;
    parameter DEBOUNCE_COUNT = 1000000;
    
    logic timer_start, counting, expired, one_hz_enable;
    logic [11:0] count, tens, ones;
	logic [3:0] minutes;
	logic [10:0] hcount;    // pixel on current line
    logic [9:0] vcount;     // line number
    logic hsync, vsync;
    logic [11:0] pixel;
    logic [11:0] pixel_out1, pixel_out2; //pixel_out minigame_1
    logic [11:0] rgb;
    logic [3:0] minigame; //which minigame is being played/displayed
    logic up, down, left, right;
    
    
    
    
    
    
    //create 65 MHz clock for 1024 x 768 VGA graphics
    clk_wiz_lab3 clkdivider(.clk_in1(clk_100mhz), .clk_out1(clk_65mhz));
    
    
    
    
 /////////Debounce Inputs/////////////////////
	
	
	debounce #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) db1 (.reset_in(sw[15]), .clock_in(clk_65mhz), .noisy_in(btnc),.clean_out(timer_start));
	debounce #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) db2 (.reset_in(sw[15]), .clock_in(clk_65mhz), .noisy_in(btnu),.clean_out(up));
	debounce #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) db3 (.reset_in(sw[15]), .clock_in(clk_65mhz), .noisy_in(btnd),.clean_out(down));
	debounce #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) db4 (.reset_in(sw[15]), .clock_in(clk_65mhz), .noisy_in(btnl),.clean_out(left));
	debounce #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) db5 (.reset_in(sw[15]), .clock_in(clk_65mhz), .noisy_in(btnr),.clean_out(right));
	
	
	
	///////////////////timer demo, value is in seconds////////////////////
	
	
	timer #(.ONE_HZ_PERIOD(ONE_HZ_PERIOD)) t1 (.clock(clk_65mhz), .start_timer(timer_start),  .value(12'd150), .counting(counting), 
	 .expired_pulse(expired), .one_hz(one_hz_enable), .count_out(count), .ones(ones), .tens(tens), .minutes(minutes));
	 
	 
	 
	 
	 
	 //pseudorandom number generator, clock the ouput in order to select a random number
	 wire data_rand;
	 logic[15:0] rand_out;
	 random_num random (.clock(clk_65mhz),.data(data_rand), .random_number(rand_out));
	 
	 //temperature sensor data
	 wire [12:0] temp_o;
     reg [12:0] temp_valid;
    
     always @(posedge clk_65mhz)
         temp_valid <= rdy_o ?  temp_o : temp_valid;  // each bit is 0.0625 deg centigrade
    
     TempSensorCtl temp_sense(
         .TMP_SCL        (tmp_scl),
         .TMP_SDA        (tmp_sda),
         .TEMP_O         (temp_o),  // 13bit msb = sign
         .RDY_O          (rdy_o),   // data valid
         .ERR_O          (err_o),
         .CLK_I          (clk_65mhz),
         .SRST_I         (1'b0)
        );
        
        
     // ila_0 myila (.clk(clk_65mhz), .probe0(temp_valid)); 
     
     //Minigames
	 
	 minigame_1 mgame1 (.vclock_in(clk_65mhz), .reset_in(sw[15]), .hcount_in(hcount), .vcount_in(vcount), 
	 .pixel_out(pixel_out1), .vsync_in(vsync), .temp_in(temp_valid), .btnu(up), .btnd(down), .btnl(left), .btnr(right), .sw(sw[3:0]), .random(rand_out[1:0]));
	 
	 logic [11:0] count_mg2;
	 logic [3:0] mg2_state;
	 
	 minigame_2 mgame2 (.vclock_in(clk_65mhz), .reset_in(sw[14]), .hcount_in(hcount), .vcount_in(vcount), 
	 .pixel_out(pixel_out2), .vsync_in(vsync),  .btnu(up), .btnd(down), .btnl(left), 
	 .btnr(right),  .random(rand_out[1:0]), .led_r(led16_r), .led_b(led16_b), .led_g(led16_g), .timer_count(count_mg2), .state(mg2_state));
	 assign minigame = 3'b010; //choose which minigame is playing
	 
	 //Handle Graphics
	 xvga xvga1(.vclock_in(clk_65mhz),.hcount_out(hcount),.vcount_out(vcount),
          .hsync_out(hsync),.vsync_out(vsync),.blank_out(blank));
     
     logic border = (hcount==0 | hcount==1023 | vcount==0 | vcount==767 |
                   hcount == 512 | vcount == 384);
     logic b,hs,vs;
     
     //Graphics based on the minigame being played
     
     logic prev_onehz;
     
    always_ff @(posedge clk_65mhz) begin
         hs <= hsync;
         vs <= vsync;
         b <= blank;
         prev_onehz <= one_hz_enable;
         if(one_hz_enable & !prev_onehz)begin 
            led = rand_out;
         end
    
    
          case(minigame)
            3'b000      :   rgb <= {{4{hcount[8]}}, {4{hcount[7]}}, {4{hcount[6]}}} ;
            3'b001      :   rgb <= pixel_out1;
            3'b010      :   rgb <= pixel_out2;
            default     :   rgb <= rgb <= {12{border}};
        
          endcase
 
    end
    
    assign vga_r = ~b ? rgb[11:8]: 0;
    assign vga_g = ~b ? rgb[7:4] : 0;
    assign vga_b = ~b ? rgb[3:0] : 0;

    assign vga_hs = ~hs;
    assign vga_vs = ~vs;

	   //  instantiate 7-segment display; display (8) 4-bit hex
    logic [31:0] data;      
    logic [6:0] segments;
    assign {cg, cf, ce, cd, cc, cb, ca} = segments[6:0];
    //assign data[3:0] = ones[3:0];
    //assign data[7:4] = tens[3:0];
    assign data[3:0] = mg2_state;
    assign data[11:4] = count_mg2[7:0];
    assign data[31:12] = {3'b0,temp_valid, 4'h0};
    
    display_8hex display_mod (.clk_in(clk_65mhz), .data_in(data),
	.seg_out({cg, cf, ce, cd, cc, cb, ca}), .strobe_out(an));

	accel::e_orientation orientation;
	
	accelerometer accelerometer_builtin(
        .clk_in(clk_65mhz),
        .reset_in(reset),
        .acl_miso,
        .acl_mosi,
        .acl_sclk,
        .acl_csn,
        
        .orientation
    );
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

////////////////////////// XVGA Module //////////////////////

module xvga(input vclock_in,
            output logic [10:0] hcount_out,    // pixel number on current line
            output logic [9:0] vcount_out,     // line number
            output logic vsync_out, hsync_out,
            output logic blank_out);

   parameter DISPLAY_WIDTH  = 1024;      // display width
   parameter DISPLAY_HEIGHT = 768;       // number of lines

   parameter  H_FP = 24;                 // horizontal front porch
   parameter  H_SYNC_PULSE = 136;        // horizontal sync
   parameter  H_BP = 160;                // horizontal back porch

   parameter  V_FP = 3;                  // vertical front porch
   parameter  V_SYNC_PULSE = 6;          // vertical sync 
   parameter  V_BP = 29;                 // vertical back porch

   // horizontal: 1344 pixels total
   // display 1024 pixels per line
   logic hblank,vblank;
   logic hsyncon,hsyncoff,hreset,hblankon;
   assign hblankon = (hcount_out == (DISPLAY_WIDTH -1));    
   assign hsyncon = (hcount_out == (DISPLAY_WIDTH + H_FP - 1));  //1047
   assign hsyncoff = (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE - 1));  // 1183
   assign hreset = (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE + H_BP - 1));  //1343

   // vertical: 806 lines total
   // display 768 lines
   logic vsyncon,vsyncoff,vreset,vblankon;
   assign vblankon = hreset & (vcount_out == (DISPLAY_HEIGHT - 1));   // 767 
   assign vsyncon = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP - 1));  // 771
   assign vsyncoff = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE - 1));  // 777
   assign vreset = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE + V_BP - 1)); // 805

   // sync and blanking
   logic next_hblank,next_vblank;
   assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
   assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
   always_ff @(posedge vclock_in) begin
      hcount_out <= hreset ? 0 : hcount_out + 1;
      hblank <= next_hblank;
      hsync_out <= hsyncon ? 0 : hsyncoff ? 1 : hsync_out;  // active low

      vcount_out <= hreset ? (vreset ? 0 : vcount_out + 1) : vcount_out;
      vblank <= next_vblank;
      vsync_out <= vsyncon ? 0 : vsyncoff ? 1 : vsync_out;  // active low

      blank_out <= next_vblank | (next_hblank & ~hreset);
   end
endmodule

/////////////////////////////////////////////////////////////////////
//////////////// Minigame 1-FINGERPRINT SCAN ////////////////////////
/////////////////////////////////////////////////////////////////////


module minigame_1( input vclock_in,
                   input reset_in,
                   input [10:0] hcount_in,
                   input [9:0] vcount_in,
                   input [1:0] random,
                   input [3:0] sw,
                   input btnu, btnl, btnd, btnr,
                   //input hsync_in,
                   input vsync_in,
                   input [12:0] temp_in,
                   //input blank_in,
                   
                   output logic [11:0] pixel_out
                   
                   );
                   parameter START = 3'b000;
                   parameter FIRST_SQUARE = 3'b001;
                   parameter SECOND_SQUARE = 3'b010;
                   parameter THIRD_SQUARE = 3'b011;
                   parameter DECODE = 3'b100;
                   parameter DONE = 3'b101;
                   
                   
                   logic [11:0] pixel_ll, pixel_lr, pixel_lc, pixel_f;
                   logic[11:0] color_sq1, col_start_sq1;
                   logic[11:0] color_sq2, col_start_sq2;
                   logic[11:0] color_sq3, col_start_sq3;
                   logic [11:0] final_col;
                   logic [2:0] state;
                   logic [12:0] start_temp;
                   logic[1:0] chosen_rand;
                   
                   blob #(.WIDTH(64), .HEIGHT(64)) square_1(.x_in(11'd138), .hcount_in(hcount_in), .y_in(10'd600), .vcount_in(vcount_in), .pixel_out(pixel_ll), .color(color_sq1));
                   blob #(.WIDTH(64), .HEIGHT(64)) square_2(.x_in(11'd479), .hcount_in(hcount_in), .y_in(10'd600), .vcount_in(vcount_in), .pixel_out(pixel_lc), .color(color_sq2));
                   blob #(.WIDTH(64), .HEIGHT(64)) square_3(.x_in(11'd820), .hcount_in(hcount_in), .y_in(10'd600), .vcount_in(vcount_in), .pixel_out(pixel_lr), .color(color_sq3));
                   fingerprint(.pixel_clk_in(vclock_in), .x_in(11'd386), .y_in(10'd351), .hcount_in(hcount_in), .vcount_in(vcount_in), .pixel_out(pixel_f));
                   
                   logic[11:0] diff1;
                   logic[11:0] diff2;
                   assign pixel_out = pixel_ll + pixel_lr + pixel_lc + pixel_f;
                   assign diff1 = temp_in - start_temp;
                   assign diff2 = start_temp - temp_in;
                   
                   Lut_mg1 lut1 (.clock(vclock_in), .rn(chosen_rand), .sq_1(col_start_sq1), .sq_2(col_start_sq2), .sq_3(col_start_sq3), .final_color(final_col));
                   
                   
                   
                   logic vsync_prev;
                   
                   always_ff @(posedge vclock_in) begin
                        vsync_prev <= vsync_in;
                   end
                   
                   always_ff @(posedge vclock_in) begin
                        if (reset_in) begin
                            state <= 3'b000;
                            start_temp <= temp_in;
                            chosen_rand <= random;
                        end 
                            
                        else if (vsync_prev & !vsync_in) begin
                        //diff_out <= temp_in[11:0] - start_temp
                        case(state)
                            START           :      begin color_sq1<= col_start_sq1; color_sq2 <= col_start_sq2; color_sq3 <= col_start_sq3; state <= FIRST_SQUARE; end
                            FIRST_SQUARE    :      begin if ((diff1 > 12'h00F || diff1==12'h00F) & !diff1[11]) begin
                                                                color_sq1 <= col_start_sq2;
                                                                state <= SECOND_SQUARE;
                                                                start_temp <= temp_in;
                                                          end else begin
                                                                color_sq1 <= col_start_sq1;
                                                                state <= FIRST_SQUARE;
                                                          end
                                                    end
                                                    
                             SECOND_SQUARE  :     begin if ((diff2 > 12'h00A || diff2==12'h00A) & !diff2[11]) begin
                                                                color_sq2 <= col_start_sq3;
                                                                state <= THIRD_SQUARE;
                                                                start_temp <= temp_in;
                                                          end else begin
                                                                color_sq2 <= col_start_sq2;
                                                                state <= SECOND_SQUARE;
                                                          end
                                                    end
                             THIRD_SQUARE   :     begin if ((diff1 > 12'h00F || diff1==12'h00F) & !diff1[11]) begin
                                                                color_sq3 <= final_col;
                                                                state <= DECODE;
                                                          end else begin
                                                                color_sq3 <= col_start_sq3;
                                                                state <= THIRD_SQUARE;
                                                          end
                                                    end
                             DECODE           :     begin case(chosen_rand) 
                                                                2'b00   :   begin state <= (sw[2]& btnu & btnr)? DONE: DECODE;  end
                                                                2'b01   :   begin state <= (sw[0]& btnu & btnd)? DONE: DECODE;  end
                                                                2'b10   :   begin state <= (sw[1]& btnl & btnr)? DONE: DECODE;  end
                                                                2'b11   :   begin state <= (sw[3]& btnl & btnd)? DONE: DECODE;  end
                                                                
                                                                
                                                           endcase
                                                    end
                             DONE             :     begin color_sq1 <= 12'h0F0; color_sq2 <= 12'h0F0; color_sq3 <= 12'h0F0; end
                                                    
                        endcase
                      end
                   end
                    
                   
endmodule


///////////////////////////////////////////////////////

/////////////////////////////////LUT for Minigame 1////////////////////////////
module Lut_mg1(         input clock,
                        input [1:0] rn,
                        output logic [11:0] sq_1,
                        output logic [11:0] sq_2,
                        output logic [11:0] sq_3,
                        output logic [11:0] final_color                      
);

    always_ff @(posedge clock) begin
        case(rn)
            2'b00       :   begin  sq_1 <= 12'h00F; sq_2<= 12'hF0F; sq_3 <= 12'hF00; final_color <= 12'hFF0; end
            2'b01       :   begin  sq_1 <= 12'hF0F; sq_2<= 12'hF00; sq_3 <= 12'hFF0; final_color <= 12'h0F0; end
            2'b10       :   begin  sq_1 <= 12'hF00; sq_2<= 12'hFF0; sq_3 <= 12'h0F0; final_color <= 12'h0FF; end
            2'b11       :   begin  sq_1 <= 12'hFF0; sq_2<= 12'h0F0; sq_3 <= 12'h0FF; final_color <= 12'h00F; end
        endcase
     end

endmodule


/////////////////////////////////////////////////////////////////////////////
///////////////////// MINIGAME 2- SIMON SAYS/////////////////////////////////
/////////////////////////////////////////////////////////////////////////////


module minigame_2( input vclock_in,
                   input reset_in,
                   input [10:0] hcount_in,
                   input [9:0] vcount_in,
                   input [1:0] random,
                   input btnu, btnl, btnd, btnr,
                   //input hsync_in,
                   input vsync_in,
                   //input blank_in,
                   
                   output logic [11:0] pixel_out,
                   output logic [11:0] timer_count,
                   output logic led_r,
                   output logic  led_g,
                   output logic  led_b,
                   output logic [3:0] state
                   
                   );
                   
                   parameter  INIT = 4'b0000;
                   parameter FLASH_1 = 4'b0001;
                   parameter SEQ_1 = 4'b0010;
                   parameter FLASH_2 = 4'b0011;
                   parameter SEQ_2 = 4'b0100;
                   parameter FLASH_3 = 4'b0101;
                   parameter SEQ_3 = 4'b0110;
                   parameter FLASH_4 = 4'b0111;
                   parameter SEQ_4 = 4'b1000;
                   parameter FAILED = 4'b1001;
                   parameter SUCCESS = 4'b1010;
                   parameter WAIT_FLASH1 = 4'b1011;
                   parameter WAIT_FLASH2 = 4'b1100;
                   parameter WAIT_FLASH3 = 4'b1101;
                   parameter WAIT_FLASH4 = 4'b1110;
                   
                   
//   assign checkerboard = hcount_in[8:6] + vcount_in[8:6];
                    picture_blob_emma kaboom (.pixel_clk_in(vclock_in),.x_in(0),.hcount_in(hcount_in), 
                    .y_in(200), .vcount_in(vcount_in), .pixel_out(pixel_out));
                   
                   //logic [3:0] state;
                   logic [1:0] chosen_rand;
     
                   logic timer_start;
                   //logic [11:0] timer_count;
                   logic [3:0] state_count;
                   logic expired;
                   logic [2:0] lut_out, light_1, light_2, light_3, light_4;
                   logic prev_btnu, prev_btnd, prev_btnl, prev_btnr;
                   
                   timer timer_mg2(.clock(vclock_in), .start_timer(timer_start), .value(12'd2), .count_out(timer_count), .expired_pulse(expired));
                   Lut_mg2 lutmg2 (.rn(chosen_rand), .led_col(lut_out));
                   logic vsync_prev;
                   
                   always_ff @(posedge vclock_in) begin
                        vsync_prev <= vsync_in;
                   end
                   
                   always_ff @(posedge vclock_in) begin
                        if (reset_in) begin
                            state <= 4'b0000;
                            chosen_rand <= random;
                            state_count <= 4'b0000;
                            
                        end 
                            
                        else if (vsync_prev & !vsync_in) begin
                            case(state)
                                INIT    :   begin chosen_rand <= random;
                                                  case(state_count) 
                                                        4'b0000  : begin light_1 <= lut_out; state_count <= state_count +1; state <= INIT; end
                                                        4'b0001  : begin light_2 <= lut_out; state_count <= state_count +1; state <= INIT; end
                                                        4'b0010  : begin light_3 <= lut_out; state_count <= state_count +1; state <= INIT;end
                                                        4'b0011  : begin light_4 <= lut_out; state_count <= 4'b0000; state <= FLASH_1;end
                                                   endcase   
                                            end
                                FLASH_1 :   begin state <= WAIT_FLASH1;
                                                  {led_r, led_g, led_b} <= light_1;
                                                  timer_start <= 1;
                                            end
                                WAIT_FLASH1  : begin timer_start <= 0;
                                                    state <= expired? ((state_count==4'b0000)? SEQ_1 : FLASH_2) : WAIT_FLASH1;
                                                    if(timer_count==12'b1) {led_r, led_g, led_b} <= 3'b000;
                                                end
                                SEQ_1   :   begin case(light_1) 
                                             3'b100   :   begin state <= (btnu)? ((state_count==0)? FLASH_1:SEQ_2): SEQ_1; if(btnu) state_count <= state_count + 1;  end
                                             3'b010   :   begin state <= (btnr)? ((state_count==0)? FLASH_1:SEQ_2): SEQ_1; if(btnr) state_count <= state_count +1;  end
                                             3'b001   :   begin state <= (btnd)? ((state_count==0)? FLASH_1:SEQ_2): SEQ_1; if(btnd) state_count <= state_count + 1;  end
                                             3'b101   :   begin state <= (btnl)? ((state_count==0)? FLASH_1:SEQ_2): SEQ_1; if(btnl) state_count <= state_count + 1;  end                   
                                            endcase end
                                FLASH_2 :   begin state <= WAIT_FLASH2;
                                                  {led_r, led_g, led_b} <= light_2;
                                                  timer_start <= 1;
                                            end
                                WAIT_FLASH2  : begin timer_start <= 0;
                                                    state <= expired? ((state_count==4'b0001 || state_count==4'b0010)? SEQ_2 : FLASH_3) : WAIT_FLASH2;
                                                    if(timer_count==12'b1) {led_r, led_g, led_b} <= 3'b000;
                                                end
                                SEQ_2   :   begin case(light_2) 
                                             3'b100   :   begin state <= (state_count==1)? SEQ_1 :((btnu & ! prev_btnu)? ((state_count==2)? FLASH_1:SEQ_3): SEQ_2); if(btnu & ! prev_btnu) state_count <= state_count + 1;  end
                                             3'b010   :   begin state <= (state_count==1)?SEQ_1:((btnr & ! prev_btnr)? ((state_count==2)? FLASH_1:SEQ_3): SEQ_2); if(btnr & ! prev_btnr) state_count <= state_count + 1;  end
                                             3'b001   :   begin state <= (state_count==1)?SEQ_1:((btnd & ! prev_btnd)? ((state_count==2)? FLASH_1:SEQ_3): SEQ_2); if(btnd & ! prev_btnd) state_count <= state_count + 1;  end
                                             3'b101   :   begin state <= (state_count==1)?SEQ_1:((btnl & ! prev_btnl)? ((state_count==2)? FLASH_1:SEQ_3): SEQ_2); if(btnl & ! prev_btnl) state_count <= state_count + 1;  end                   
                                            endcase end
                                FLASH_3 :   begin state <= WAIT_FLASH3;
                                                  {led_r, led_g, led_b} <= light_3;
                                                  timer_start <= 1;
                                            end
                                WAIT_FLASH3  : begin timer_start <= 0;
                                                    state <= expired? ((state_count==4'b0011|| state_count==4'b0101)? SEQ_3 : FLASH_4) : WAIT_FLASH3;
                                                    if(timer_count==12'b1) {led_r, led_g, led_b} <= 3'b000;
                                                end
                                SEQ_3   :   begin case(light_3) 
                                             3'b100   :   begin state <= (state_count==3)? SEQ_1 :((btnu & ! prev_btnu)? ((state_count==5)? FLASH_1:SEQ_4): SEQ_3); if(btnu & ! prev_btnu) state_count <= state_count + 1;  end
                                             3'b010   :   begin state <= (state_count==3)? SEQ_1 :((btnr & ! prev_btnr)? ((state_count==5)? FLASH_1:SEQ_4): SEQ_3); if(btnr & ! prev_btnr) state_count <= state_count + 1;  end
                                             3'b001   :   begin state <= (state_count==3)? SEQ_1 :((btnd & ! prev_btnd)? ((state_count==5)? FLASH_1:SEQ_4): SEQ_3); if(btnd & ! prev_btnd) state_count <= state_count + 1;  end
                                             3'b101   :   begin state <= (state_count==3)? SEQ_1 :((btnl & ! prev_btnl)? ((state_count==5)? FLASH_1:SEQ_4): SEQ_3); if(btnl & ! prev_btnl) state_count <= state_count + 1;  end                   
                                            endcase end
                                FLASH_4 :   begin state <= WAIT_FLASH4;
                                                  {led_r, led_g, led_b} <= light_4;
                                                  timer_start <= 1;
                                            end
                                WAIT_FLASH4  : begin timer_start <= 0;
                                                    state <= expired? SEQ_4 : WAIT_FLASH4;
                                                    if(timer_count==12'b1) {led_r, led_g, led_b} <= 3'b000;
                                                end
                                SEQ_4   :   begin case(light_4) 
                                             3'b100   :   begin state <= (state_count==6)?SEQ_1:((btnu & !prev_btnu)? SUCCESS: SEQ_4);   end
                                             3'b010   :   begin state <= (state_count==6)?SEQ_1:((btnr & !prev_btnr)? SUCCESS: SEQ_4);   end
                                             3'b001   :   begin state <= (state_count==6)?SEQ_1:((btnd & !prev_btnd)? SUCCESS: SEQ_4);   end
                                             3'b101   :   begin state <= (state_count==6)?SEQ_1:((btnl & !prev_btnl)? SUCCESS: SEQ_4);   end                   
                                            endcase end
                               SUCCESS  :   begin {led_r, led_g, led_b} <= 3'b111; end
                               
                             
                             
                             
                             endcase
                             prev_btnu <= btnu;
                             prev_btnd <= btnd;
                             prev_btnr <= btnr;
                             prev_btnl <= btnl;                 
                        
                        end
                  end
                                                    
endmodule

/////////////////////////////////LUT for Minigame 2////////////////////////////
module Lut_mg2(     
                        input [1:0] rn,
                        output logic [2:0] led_col                 
);

always_comb begin
        case(rn)
            2'b00       :   begin led_col = 3'b100 ; end
            2'b01       :   begin led_col = 3'b010 ; end
            2'b10       :  begin led_col = 3'b001 ; end
            2'b11       :   begin led_col = 3'b101 ; end
        endcase
end

endmodule

