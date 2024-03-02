
 import uvm_pkg::*;
 `include "uvm_macros.svh"

module tb_top;
  
  reg a, clk, rst_n, en;
  wire b;
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);
    forever begin
      clk = 0;
      #5ns;
      clk = 1;
      #5ns;
    end 
  end
  
  initial begin
    rst_n = 1;
    #30ns;
    a = 1;
    #10ns;
    en = 1;
    #20ns;
    rst_n = 0;
    #10us;
    rst_n = 1;
    #10us;
    a= 0;
    #20us;
    $finish;    
  end
  
  dut dut_i(.d(a) , .clk(clk), .q(b), .rst_n(rst_n), .en(en) );
  
endmodule
