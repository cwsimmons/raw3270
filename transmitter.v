`timescale 1ns / 1ps

/*
 * IBM 3270 Coax Transmitter (Type A)
 * 
 * Author: Chris Simmons
 * Date:   12/15/2019
 */

module transmitter (
    input clk,
    input reset,
    input sclk,             // 2 x 2.358 MHz

    input dataAvailable,
    input [9:0] data,
    output reg ren,

    output serialOut,
    output serialOutComplement,
    output serialOutDelayed,
    output reg active
);
    
    parameter [16:0] header = 17'b11100010101010101;
    parameter [5:0] trailer = 6'b111101;
    
    reg [9:0] delayReg;
    
    reg [1:0] txState;
    reg [4:0] bitCount;
    

    reg pending;
    reg pendingAck;
    reg pendingAckPrev;
    reg [9:0] pendingWord;

    reg [9:0] currentWord;
    wire [11:0] packedWord;
    wire parityBit;
    
    assign parityBit = ^{1'b1, currentWord};
    assign packedWord = {1'b1, currentWord, parityBit};
    
    assign serialOut = (txState == 0) ? 1'b10:
                       (txState == 1) ? header[bitCount] :
                       (txState == 2) ? packedWord[11 - bitCount[4:1]] ~^ bitCount[0] :
                       (txState == 3) ? trailer[bitCount] : 1'b0;

    assign serialOutComplement = (txState) ? !serialOut : 0;
                       
    assign serialOutDelayed = delayReg[9];
    
    always @(posedge clk)
    begin
        if (reset)
            delayReg <= 10'b0;
        else
            delayReg <= {delayReg[8:0], serialOut};
    end

    always @(posedge clk)
    begin

        pendingAckPrev <= pendingAck;
        ren <= 0;
        if (reset)
            pending <= 0;
        if (dataAvailable && !pending)
        begin
            ren <= 1;
            pending <= 1;
            pendingWord <= data;
        end
        else if (pendingAck && !pendingAckPrev)
        begin
            pending <= 0;
        end

        if (txState)
            active <= 1;
        else
            active <= 0;

    end

    
    always @(posedge sclk or posedge reset)
    begin
    
        pendingAck <= 0;

        if (reset)
        begin

            txState <= 0;
              bitCount <= 0;
              currentWord <= 0;

        end
        else if (txState == 0)
        begin
        
            if (pending)
            begin
                txState <= 1;
                bitCount <= 0;
                pendingAck <= 1;
                currentWord <= pendingWord;
            end
            
        end
        else if (txState == 1)
        begin
        
            if (bitCount == 16)
            begin
                bitCount <= 0;
                txState <= 2;
            end
            else
            begin
                bitCount <= bitCount + 1;
            end
            
        end
        else if (txState == 2)
        begin
        
            if (bitCount == 23)
            begin
                bitCount <= 0;
                
                if (pending)
                begin
                    pendingAck <= 1;
                    currentWord <= pendingWord;
                end
                else
                begin
                    txState <= 3;
                end	
            end
            else
            begin
                bitCount <= bitCount + 1;
            end
        
        end
        else if (txState == 3)
        begin
        
            if (bitCount == 5)
            begin
                txState <= 0;
                bitCount <= 0;
            end
            else
            begin
                bitCount <= bitCount + 1;
            end
        
        end
    end
    
endmodule
