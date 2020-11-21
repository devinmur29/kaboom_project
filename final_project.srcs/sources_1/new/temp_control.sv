`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2020 04:05:34 PM
// Design Name: 
// Module Name: temp_control
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


module temp_control(

    input CLK65MHZ,
    output logic [15:0] temp_data

    );
    
    wire enable;  
    wire ready;
    logic [15:0] data_out;
    logic [6:0] Address_in;

    assign Address_in = 7'h00;
         
xadc_wiz_0  XLXI_7 (.daddr_in(Address_in), //addresses can be found in the artix 7 XADC user guide DRP register space
                      .dclk_in(CLK65MHZ), 
                      .den_in(enable), 
                      .di_in(0), 
                      .dwe_in(0), 
                      .busy_out(),                   
                      
                      .vn_in(), 
                      .vp_in(), 
                      .alarm_out(), 
                      .do_out(data_out), 
                      .eoc_out(enable),
                      .eos_out(),
                      .channel_out(),
                      .drdy_out(ready));
always_ff @(posedge CLK65MHZ) begin
    if (ready==1) temp_data <= data_out;
    end
    
                      
endmodule
