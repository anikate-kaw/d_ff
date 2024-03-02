

module dut(input d, input clk, output q , input en, input rst_n);

  d_ff ff_imp(.d(d) , .clk(clk), .q(q), .rst_n(rst_n), .en(en));

endmodule

module d_ff(input d, input clk, output q, input rst_n , input en);
  reg qb;
  
  always@(posedge clk or negedge rst_n) begin //asynchronous reset active low - posedge if reset active high
    if(rst_n == 0) begin
      qb <= 0;
    end else begin
      if(en == 1) begin
        qb <= d;
      end else begin
        qb <= 0;
      end
    end
  end
  
  assign q = qb;
endmodule
