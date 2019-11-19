`timescale 1ns / 1ps

/*
 * IBM 3270 Coaxial Decoder
 * 
 * NOTE: I butcher the term "bit" throughout this file.
 *       It actually refers to a half bit time
 */

module receiver (
    input clk,
    input reset,
    input serialIn,
    output reg [11:0] rxWord,
    output reg wordAvailable);
    
    parameter [15:0] header = 16'b0101010101000111;
    
    reg prevSerialIn;		// Keep track of previous serial state
                            //   so that we can detect transitions
    reg [15:0] counter;     // Counter for the length between transitions
    reg newBit;				// The state of the previous bit run
    reg complementaryBit;   // When decoding a frame we keep track of the first half
                            //   of the bit cell and make sure it is the complement
                            //   of the second half
    reg [1:0] runLength;    // The determined length of a bit run in half bit times
                            //   The longest we're ever interested in is three
    
    reg state;		        // 0: Waiting for the header, 1: Receiving a frame
    reg [4:0] progress;		// Keeps track of how many half bits we've received
    reg [14:0] shiftReg;	// RX Word being built up
    
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
            state <= 1'b0;
            progress <= 0;
        end
        // If the input changed states...
        else if (prevSerialIn != serialIn)
        begin
        
            // Make note of the original bit state
            newBit <= prevSerialIn;
            
            // Determine the length of this bit run
            if (counter > 50)
                runLength <= 3;
            else if (counter > 32)
                runLength <= 2;
            else if (counter > 14)
                runLength <= 1;
            else
                runLength <= 0;
                
            // Reset the count
            counter <= 0;
            
        end
        else
        begin
            // Increment the counter but don't overflow
            if (~&counter)
                counter <= counter + 1;
            // If there are bits needing processing
            if (runLength)
            begin
                // Process a single bit
                runLength <= runLength - 1;
                
                // When looking for the header...
                if (state == 1'b0)
                begin
                    // Shift the new bit in
                    shiftReg <= {shiftReg[13:0], newBit};
                    // If this new bit completes the header...
                    if ({shiftReg[13:0], newBit} == header)
                    begin
                        // Go to state 1
                        state <= 1'b1;
                        progress <= 0;
                    end
                    
                end
                // When recording frame data...
                else if (state == 1'b1)
                begin
                    // If we're processing the second half of a bit cell...
                    if (progress[0])
                    begin
                        // Check to make sure there is a transition, if not...
                        if (newBit == complementaryBit)
                            // Go back to looking for the header
                            state <= 1'b0;
                        else
                        begin
                            // It's a good bit so we record it
                            shiftReg <= {shiftReg[13:0], newBit};
                            // If this was the last bit of a word...
                            if (progress == 23)
                            begin
                                // Make the new word available
                                rxWord <= {shiftReg[10:0], newBit};
                                // And start on a new one
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
    
    // If we just completed a word...
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