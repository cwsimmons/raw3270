`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2019 05:06:08 PM
// Design Name: 
// Module Name: transmitter
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


module transmitter (
	input clk,
	input reset,
	input sclk,   // 2 x 2.358 MHz
	input wEn,
	input [9:0] wordWrite,
	input start,
	output serialOut,
	output serialOutDelayed,
	output reg active);
	
	parameter [15:0] header = 16'b1110001010101010;
	parameter [5:0] trailer = 6'b111101;
	
	reg [9:0] fifo [0:31];
	reg [4:0] top;
	
	reg [9:0] delayReg;
	
	reg [1:0] txState;
	reg [4:0] bitCount;
	reg [4:0] wordCount;
	reg done;
	reg prevDone;
	
	reg [9:0] currentWord;
	wire [11:0] packedWord;
	wire parityBit;
	
	assign parityBit = ^{1'b1, currentWord};
	assign packedWord = {1'b1, currentWord, parityBit};
	
	assign serialOut = (txState == 2'b00) ? 1'b1 :
		               (txState == 2'b01) ? header[bitCount] :
      (txState == 2'b10) ? packedWord[11 - bitCount[4:1]] ~^ bitCount[0] :
					   (txState == 2'b11) ? trailer[bitCount] : 1'b0;
					   
	assign serialOutDelayed = delayReg[9];
	
	always @(posedge clk)
	begin
		if (reset)
			delayReg <= 10'b0;
		else
			delayReg <= {delayReg[8:0], serialOut};
	end
	
	always @(posedge sclk or posedge reset)
	begin
		if (reset)
			done <= 1'b0;
		else
			done <= (txState == 2'b11) && (bitCount == 5);
	end
	
	always @(posedge clk)
	begin
		if (reset)
			prevDone <= 1'b0;
		else
			prevDone <= done;
	end
	
	always @(posedge clk)
	begin
      if (reset)
        active <= 1'b0;
		else if (start)
			active <= 1'b1;
		else if (done && !prevDone)
			active <= 1'b0;
	end
	
	always @(posedge clk)
	begin
		if (reset || (done && !prevDone))
		begin
			top <= 0;
		end
		else if (wEn && top != 31)
		begin
			fifo[top] <= wordWrite;
			top <= top + 1;
		end
	end
	
	always @(posedge sclk or posedge reset)
	begin
	
		if (reset)
		begin
			txState <= 2'b00;
          	wordCount <= 0;
          	bitCount <= 0;
          	currentWord <= 0;
		end
		else if (txState == 2'b00)
		begin
		
			if (active)
			begin
				txState <= 2'b01;
				bitCount <= 0;
			end
			
		end
		else if (txState == 2'b01)
		begin
		
			if (bitCount == 15)
			begin
				bitCount <= 0;
				wordCount <= 0;
				txState <= 2'b10;
				currentWord <= fifo[0];
			end
			else
			begin
				bitCount <= bitCount + 1;
			end
			
		end
		else if (txState == 2'b10)
		begin
		
			if (bitCount == 23)
			begin
				bitCount <= 0;
				
				if (wordCount + 1 != top)
				begin
					wordCount <= wordCount + 1;
					currentWord <= fifo[wordCount + 1];
				end
				else
				begin
					txState <= 2'b11;
				end	
			end
			else
			begin
				bitCount <= bitCount + 1;
			end
		
		end
		else if (txState == 2'b11)
		begin
		
			if (bitCount == 5)
			begin
				txState <= 2'b00;
				bitCount <= 0;
			end
			else
			begin
				bitCount <= bitCount + 1;
			end
		
		end
	end
	
endmodule
