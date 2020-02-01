`timescale 1ns / 1ps

/*
 * IBM 3270 Coax Transceiver (Type A)
 * 
 * Author: Chris Simmons
 * Date:   12/15/2019
 */

module raw3270 (
    input clk,
    input rst,
    input [11:0] addr,
    input [31:0] write,
    input en,
    input [3:0] wen,
    output reg [31:0] read,
    
    input sclk12,
    input serialIn,
    output serialOut,
    output serialOutComplement,
    output serialOutDelayed,
    output txActive
    );

    wire [1:0] raddr;
    assign raddr = addr[3:2];

    wire [11:0] rxWord;
    wire [11:0] rxHead;
    wire rxWordAvailable;
    wire [4:0] rxOccupancy;
    wire rxState;
    wire rxActive;
  
    wire txPop;
    wire [9:0] txWord;
    wire txWordAvailable;
    wire [4:0] txOccupancy;
    
    reg [9:0] writeData;
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
    
    always @(posedge clk)
    begin
        
      if (raddr[1] && wen[0])
        begin
            reset <= write[0];
        end
        else
        begin
            reset <= 1'b0;
        end
        
    end
    
    always @(posedge clk)
    begin
        if ((raddr == 0) && wen[0])
            writeData <= write[9:0];
    end
    
    always @(posedge clk)
    begin
        
        if (rst)
            read <= 32'b0;
        else if (en)
        begin
            if (raddr == 0)
                read <= {22'b0, writeData};
            else if (raddr == 1)
                read <= {20'b0, rxHead};
            else if (raddr == 2)
                read <= {txActive, 3'b0, txOccupancy};
            else if (raddr == 3)
                read <= {rxActive, 3'b0, rxOccupancy};
        end
        
    end
  
  
  fifo #(10,5) TxFIFO(
        clk,
        rst || reset,
        0,
        en && |wen && (raddr == 0),
        txPop,
        write[9:0],
        txWord,
        txWordAvailable,
        txOccupancy
    );
    
    transmitter Transmitter(
        clk,
        rst || reset,
        sclk,
        txWordAvailable,
        txWord,
        txPop,
        serialOut,
        serialOutComplement,
        serialOutDelayed,
        txActive
    );
    
    receiver Receiver(
        clk,
        rst || reset,
        !txActive,
        serialIn,
        rxActive,
        rxWord,
        rxWordAvailable
    );
        
  fifo #(12,5) RxFIFO(
        clk,
        rst || reset,
        1'b0,
        rxWordAvailable,
        en && ~|wen && (raddr == 1),
        rxWord,
        rxHead,
        rxState,
        rxOccupancy
    );

endmodule