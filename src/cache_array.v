`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Vishwas Paliwal
// Engineer: Vishwas Paliwal
// 
// Create Date: 06/06/2026 09:59:37 AM
// Design Name: cache_array
// Module Name: cache_array
// Project Name: direct mapping cache controller
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

//for a 32 bit address, 1KB of cache memory, each cache line is 128 bits that is 4 words. it is byte addressable
//addres => [22-bit tag | 6-bit index | 4-bit offset]
module cache_array(input clk, 
                   input rst, 
                   input rd_wr, 
                   input wr_hit, 
                   input [31:0] addr, 
                   input [127:0] wr_data, //from memory
                   input [31:0] proc_wr_data, //from processor during cache write
                   input store_in, //tells the cache array to write in from the memory during the update state 
                   output hit, 
                   output dirty, 
                   output reg [127:0] rd_data
                   );

//splitting up the address into fields
wire [3:0] offset_in = addr[3:0];
wire [5:0] index_in = addr[9:4];
wire [21:0] tag_in = addr[31:10];
//setting up the various arrays
reg valid_arr [63:0];
reg dirty_arr [63:0];
reg [21:0] tag_arr [63:0];
reg [127:0] data_arr [63:0];
//assigning hit and dirty output to drive the FSM states
assign hit = valid_arr[index_in] & (tag_arr[index_in] == tag_in);
assign dirty = dirty_arr[index_in];

integer i; // variable for loop

always @(posedge clk or posedge rst)
    begin
        if (rst)
            for (i = 0; i < 64; i = i +1)
                begin
                    valid_arr[i] <= 1'b0;
                    dirty_arr[i] <= 1'b0;
                end
        else if (store_in)
            begin
                valid_arr[index_in] <= 1'b1;
                dirty_arr[index_in] <= 1'b0; //freshly out from memory so 0
                tag_arr[index_in] <= tag_in;
                data_arr[index_in] <= wr_data;
            end
        else if (wr_hit)
            begin
                data_arr[index_in][offset_in[3:2]*32 +: 32] <= proc_wr_data; //selecting one single word to write in 
                dirty_arr[index_in] <= 1'b1; //block is modified, so now its dirty.
            end             
    end

always @(*)
    begin
        if (hit)
            rd_data = data_arr[index_in];
        else
            rd_data = 128'b0;
    end
    
endmodule