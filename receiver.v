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

module receiver (
	input clk,
	input reset,
	input serialIn,
	output reg [11:0] rxWord,
	output reg wordAvailable);
	
	parameter [15:0] header = 16'b0101010101000111;
	
	reg prevSerialIn;
	reg [15:0] counter;
	reg newBit;
	reg complementaryBit;
	reg [1:0] runLength;
	
	reg [1:0] state;
	reg [4:0] progress;
	reg [14:0] shiftReg;
	
	always @(posedge clk)
	begin
		if (reset)
			prevSerialIn <= 1'b0;
		else
			prevSerialIn <= serialIn;
	end
	
	always @(posedge clk)
	begin
		if (reset)
		begin
			counter <= 0;
			runLength <= 0;
			state <= 2'b00;
			progress <= 0;
		end
		else if (prevSerialIn != serialIn)
		begin
		
			//Make note of the bit state
			newBit <= prevSerialIn;
			
			//Determine the length of this bit run
			if (counter > 50)
				runLength <= 3;
			else if (counter > 32)
				runLength <= 2;
			else if (counter > 14)
				runLength <= 1;
			else
				runLength <= 0;
				
			//Reset the count
			counter <= 0;
			
		end
		else
		begin
			if (~&counter)
				counter <= counter + 1;
			if (runLength)
			begin
				//Process a bit
				runLength <= runLength - 1;
				
				if (state == 2'b00)
				begin
				
					shiftReg <= {shiftReg[13:0], newBit};
					if ({shiftReg[13:0], newBit} == header)
					begin
						state <= 2'b01;
						progress <= 0;
					end
					
				end
				else if (state == 2'b01)
				begin
					
					if (progress[0])
					begin
						if (newBit == complementaryBit)
							state <= 2'b00;
						else
						begin
							shiftReg <= {shiftReg[13:0], newBit};
							if (progress == 23)
							begin
								rxWord <= {shiftReg[10:0], newBit};
								progress <= 0;
							end
                            else
                              progress <= progress + 1;
						end
					end
                  else
                    progress <= progress + 1;
					
					complementaryBit <= newBit;
					
					
				end				
			end
		end
	end
	
	always @(posedge clk)
	begin
		if (!reset &&
			(prevSerialIn == serialIn) &&
			runLength &&
			(state == 2'b01) &&
			(newBit != complementaryBit) &&
			(progress == 23))
			wordAvailable <= 1'b1;
		else
			wordAvailable <= 1'b0;
	end
	
endmodule