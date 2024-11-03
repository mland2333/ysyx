module ysyx_20020207_IDU(
  input [31:0] inst,
  output [6:0] op,
  output [2:0] func,
  output [4:0] rs1,
  output [4:0] rs2,
  output [4:0] rd,
  output [31:0] imm
);

  assign op = inst[6:0];
  assign func = inst[14:12];
  assign rd = inst[11:7];
  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign imm = {{20{inst[31]}}, inst[31:20]};

endmodule
