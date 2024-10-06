module top(
  input clk,
  input a,
  input b,
  output f
);
  assign f = a ^ b;
endmodule
