`timescale 1ns / 1ps

/*
 * IBM 3270 Coax Receiver (Type A)
 * 
 * Author: Chris Simmons
 * Date:   12/15/2019
 */

module receiver (
    input clk,
    input reset,
    input enable,
    input serialIn,
    output active,
    output reg [11:0] rxWord,
    output reg wordAvailable);
    
    parameter [15:0] header = 16'b0101010101000111;
    
    reg [2:0] history;
    wire serialInFiltered;
    assign serialInFiltered = (history[2] && history[1]) ||
                              (history[2] && history[0]) ||
                              (history[1] && history[0]);
    
    assign active = state;

    reg prevSerialInFiltered;
    reg [15:0] counter;
    reg newBit;
    reg complementaryBit;
    reg [1:0] runLength;
    
    reg state;
    reg [4:0] progress;
    reg [14:0] shiftReg;
    
    always @(posedge clk)
    begin
        history <= {history[1:0], serialIn};
        if (reset)
            prevSerialInFiltered <= 1'b0;
        else
            prevSerialInFiltered <= serialInFiltered;
    end
    
    always @(posedge clk)
    begin
       
        wordAvailable <= 0;
        
        if (reset)
        begin
        
            counter <= 0;
            runLength <= 0;
            state <= 0;
            progress <= 0;
            
        end
        else if ((prevSerialInFiltered != serialInFiltered) && enable)
        begin
        
            //Make note of the bit state
            newBit <= prevSerialInFiltered;
            
            //Determine the length of this bit run
            if (counter > 53)
                runLength <= 3;
            else if (counter > 32)
                runLength <= 2;
            else if (counter > 10)
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
                
                if (state == 0)
                begin
                
                    shiftReg <= {shiftReg[14:0], newBit};
                    if ({shiftReg[14:0], newBit} == header)
                    begin
                        state <= 1;
                        progress <= 0;
                        
                    end
                    
                end
                else if (state == 1)
                begin
                    
                    if (progress[0])
                    begin
                        if (newBit == complementaryBit)
                            state <= 0;
                        else
                        begin
                            shiftReg <= {shiftReg[14:0], newBit};
                            if (progress == 23)
                            begin
                                rxWord <= {shiftReg[10:0], newBit};
                                wordAvailable <= 1;
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
    
endmodule