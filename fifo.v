`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2019 07:22:31 PM
// Design Name: 
// Module Name: raw3270
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

module fifo (
	input clk,
	input reset,
	input mode,
	input wen,
	input ren,
	input [11:0] write,
	output [11:0] read,
	output state,
	output [5:0] occupancy
	);
	
	reg [11:0] mem [0:31];
	
	reg [4:0] top;
	reg [4:0] bottom;
	
	assign occupancy = top - bottom;
	assign state = (top != bottom);
	assign read = mem[bottom];
	
	always @(posedge clk)
	begin
		
		if (reset)
		begin
			top <= 0;
			bottom <= 0;
		end
		else
		begin
			
			if (top != bottom - 1)
			begin
			
				if (wen)
				begin
					top <= top + 1;
					mem[top] <= write;
				end
				
				if (ren)
				begin
					bottom <= bottom + 1;
				end
			
			end
			else
			begin
				
				if (wen && mode)
				begin
					top <= top + 1;
					bottom <= bottom + 1;
					mem[top] <= write;
				end
				else if (ren)
				begin
					bottom <= bottom + 1;
				end
			
			end
			
		end
		
	end
	
endmodule