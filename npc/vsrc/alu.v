module ysyx_20020207_ALU(
  input [31:0] src1,
  input [31:0] src2,
  output [31:0] result
);

  assign result = src1 + src2;

endmodule
