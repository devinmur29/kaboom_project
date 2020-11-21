`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2015 01:43:34 PM
// Design Name: 
// Module Name: AnalogXADC
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


module AnalogXADC(
    output reg [15:0] temp_data,
    input CLK65MHZ
    );
    
    



wire enable;  
wire ready;
wire [15:0] data_o; 
reg [6:0] Address_in;

initial Address_in = 7'h00; 
         
xadc_wiz_0  XLXI_7 (.daddr_in(Address_in), //addresses can be found in the artix 7 XADC user guide DRP register space
                      .dclk_in(CLK65MHZ), 
                      .den_in(enable), 
                      .di_in(0), 
                      .dwe_in(0), 
                      .busy_out(),                   
                      
                      .vn_in(), 
                      .vp_in(), 
                      .alarm_out(), 
                      .do_out(data_o), 
                      .eoc_out(enable),
                      .eos_out(),
                      .channel_out(),
                      .drdy_out(ready));
                      

      


      
 
 
endmodule
