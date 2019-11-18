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


module raw3270 (
	input clk,
	input rst,
	input [11:0] haddr,
	input [31:0] write,
	input en,
	input [3:0] wen,
	output reg [31:0] read,
	
	input sclk12,
	input serialIn,
	output serialOut,
	output serialOutDelayed,
	output txActive
	);
	
	wire [1:0] addr;
	assign addr = haddr[3:2];
	
	wire [11:0] rxWord;
	wire wordAvailable;
	wire [11:0] head;
	
	reg [9:0] writeData;
	
	wire [5:0] occupancy;
	wire state;
	reg start;
	reg reset;
	
	reg sclk;
	reg [1:0] divider;
	
	always @(posedge sclk12 or posedge rst)
	begin
	   if (rst)
	   begin
	       sclk <= 0;
	       divider <= 0;
	   end
	   else if (divider == 2)
	   begin
	       sclk <= ~sclk;
	       divider <= 0;
	   end
	   else
	       divider <= divider + 1;
	
	end

	wire [31:0] status;
	assign status = {21'b0, occupancy, state, txActive, start, reset};
	
	always @(posedge clk)
	begin
		
		if (addr[1] && wen[0])
		begin
			start <= write[1];
			reset <= write[0];
		end
		else
		begin
			start <= 1'b0;
			reset <= 1'b0;
		end
		
	end
	
	always @(posedge clk)
	begin
		if ((addr == 2'b00) && wen[0])
			writeData <= write[9:0];
	end
	
	always @(posedge clk)
	begin
		
		if (rst)
			read <= 32'b0;
		else if (en)
		begin
			if (addr == 2'b00)
				read <= {22'b0, writeData};
			else if (addr == 2'b01)
				read <= {20'b0, head};
			else if (addr[1])
				read <= status;
		end
		
	end
	
	transmitter Transmitter(
		clk,
		rst || reset,
		sclk,
		en && |wen && (addr == 2'b00),
		write[9:0],
		start,
		serialOut,
		serialOutDelayed,
		txActive);
	
	receiver Receiver(
		clk,
		rst || reset,
		serialIn,
		rxWord,
		wordAvailable);
		
	fifo Fifo(
		clk,
		rst || reset,
		1'b0,
		wordAvailable,
		en && ~|wen && (addr == 2'b01),
		rxWord,
		head,
		state,
		occupancy);

endmodule
