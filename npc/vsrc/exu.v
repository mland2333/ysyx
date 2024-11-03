module ysyx_20020207_EXU(
  input [6:0] op,
  input [2:0] func,
  input [31:0] src1,
  input [31:0] src2,
  output [31:0] result,
  output reg_wen
);

ysyx_20020207_ALU malu(
  .src1(src1),
  .src2(src2),
  .result(result)
);

assign reg_wen = 1;

endmodule
