`timescale 1ns / 1ps
/*
 * IBM 3270 Coaxial Transmitter
 * 
 * NOTE: I butcher the term "bit" throughout this file.
 *       It actually refers to a half bit time
 */


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
    
    reg [9:0] fifo [0:31];		//Storage for the words to be transmitted
    reg [4:0] top;				//Number of words in storage
    
    reg [9:0] delayReg;			//For the 100ns delay output
    
    reg [1:0] txState;			//00: Idle, 01: Header, 10: Data, 11: Trailer
    reg [4:0] bitCount;         //Determines how far along in each state are we
    reg [4:0] wordCount;        //The number of the word currently being sent
    reg done;                   //High right after the last bit of the trailer
    reg prevDone;
    
    reg [9:0] currentWord;      //Frame data word being sent
    wire [11:0] packedWord;     //Word with sync and parity bits
    wire parityBit;
    
    assign parityBit = ^{1'b1, currentWord};                //Even parity
    assign packedWord = {1'b1, currentWord, parityBit};
    
    assign serialOut = (txState == 2'b00) ? 1'b1 :      // Or should it be 0?
                       (txState == 2'b01) ? header[bitCount] :
                       (txState == 2'b10) ? packedWord[11 - bitCount[4:1]]
                                            ~^ bitCount[0] :
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
        // Reset the queue on reset and when finished
        if (reset || (done && !prevDone))
        begin
            top <= 0;
        end
        //If write enabled but not full
        else if (wEn && top != 31)
        begin
            fifo[top] <= wordWrite;
            top <= top + 1;
        end
    end
    
    always @(posedge sclk or posedge reset)
    begin
        //Asyncronous reset
        if (reset)
        begin
            txState <= 2'b00;
            wordCount <= 0;
            bitCount <= 0;
            currentWord <= 0;
        end
        else if (txState == 2'b00)
        begin

            //If active go to sending the header
            if (active)
            begin
                txState <= 2'b01;
                bitCount <= 0;
            end
            
        end
        else if (txState == 2'b01)
        begin

            //If last bit of header go to data
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
            //If last bit of data word
            if (bitCount == 23)
            begin
                bitCount <= 0;
                //If there are more words available
                if (wordCount + 1 != top)
                begin
                    wordCount <= wordCount + 1;
                    currentWord <= fifo[wordCount + 1];
                end
                else
                begin
                    //Otherwise go to trailer
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
            //If last bit of trailer, go idle
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
