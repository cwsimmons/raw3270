`timescale 1ns / 1ps

/* 
 * Simple FIFO
 *
 * Author: Chris Simmons
 * Date:   12/15/2019
 */

module fifo (
    clk,
    reset,
    mode,
    wen,
    ren,
    write,
    read,
    state,
    occupancy
    );
    
    parameter WIDTH = 8;
    parameter DEPTH = 5;
    
    input clk;
    input reset;
    input mode;
    input wen;
    input ren;
    input [WIDTH - 1:0] write;
    output [WIDTH - 1:0] read;
    output state;
    output [DEPTH - 1:0] occupancy;
    
    reg [WIDTH - 1:0] mem [0: 2**DEPTH - 1];
    
    reg [DEPTH - 1:0] top;
    reg [DEPTH - 1:0] bottom;
    
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
                
                if (ren && state)
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