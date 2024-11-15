module ysyx_24110006_ALU(
  input [31:0] i_a,
  input [31:0] i_b,
  output [31:0] o_r
);

  assign o_r = i_a + i_b;

endmodule
