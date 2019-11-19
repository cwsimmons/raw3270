`timescale 1ns / 1ps

/*
 * IBM 3270 Coaxial Serial Transceiver
 * 
 * Designed for use with the Xilinx AXI BRAM Controller
 */


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

    wire [1:0] addr;                    // The actual address for my registers
    assign addr = haddr[3:2];           // Since the AXI interface uses byte addressing
                                        //   we drop the two lowest bits of
                                        //   the address

    wire [11:0] rxWord;                 // Data from the receiver to the FIFO
    wire wordAvailable;                 // Signals the fifo to write
    wire [11:0] head;                   // Oldest word in the FIFO

    reg [9:0] writeData;                // Keeps track of the last word written to TX
                                        //   just so we can read it back if
                                        //   we want
    
    wire [5:0] occupancy;               // Number of words in the FIFO
    wire state;                         // Does the FIFO have data?
    reg start;                          // Start flag
    reg reset;                          // Software reset
    
    reg sclk;                           // Clock corresponding to half a bit time
    reg [1:0] divider;                  // Counter for clock division
    
    // Divide sclk12 by 6 to get sclk
    always @(posedge sclk12 or posedge rst)
    begin
       if (rst)
       begin
           sclk <= 0;
           divider <= 0;
       end
       else if (divider == 2)
       begin
           // Every third posedge on sclk12  should mark a transition on sclk
           sclk <= ~sclk;
           divider <= 0;
       end
       else
           divider <= divider + 1;
    
    end
    
    // Status Register
    wire [31:0] status;
    assign status = {21'b0, occupancy, state, txActive, start, reset};
    
    always @(posedge clk)
    begin
        // Decode for 0x2/0x3 
        if (addr[1] && wen[0])
        begin
            start <= write[1];
            reset <= write[0];
        end
        else
        begin
            // These only ever need to be active for a single
            // cycle so clear them unless they're being set
            start <= 1'b0;
            reset <= 1'b0;
        end
        
    end
    
    always @(posedge clk)
    begin
        if ((addr == 2'b00) && wen[0])
            writeData <= write[9:0];
    end
    
    // Handles read transactions
    // the read latency is 1
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
