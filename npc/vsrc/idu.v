module ysyx_24110006_IDU(
  input [31:0] i_inst,
  output [6:0] o_op,
  output [2:0] o_func,
  output [4:0] o_reg_rs1,
  output [4:0] o_reg_rs2,
  output [4:0] o_reg_rd,
  output [31:0] o_imm
);

  assign o_op = i_inst[6:0];
  assign o_func = i_inst[14:12];
  assign o_reg_rd = i_inst[11:7];
  assign o_reg_rs1 = i_inst[19:15];
  assign o_reg_rs2 = i_inst[24:20];
  wire is_i = o_op == 7'b0010011 || o_op == 7'b1100111 || o_op == 7'b0000011 || o_op == 7'b1110011;
  wire is_u = o_op == 7'b0110111 || o_op == 7'b0010111;
  wire is_j = o_op == 7'b1101111;
  wire is_s = o_op == 7'b0100011;
  wire is_b = o_op == 7'b1100011;
  wire is_r = o_op == 7'b0110011;

  wire [31:0] immi = {{20{i_inst[31]}}, i_inst[31:20]};
  wire [31:0] immu = {i_inst[31:12], 12'b0};
  wire [31:0] immj = {{11{i_inst[31]}}, i_inst[31], i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0};
  wire [31:0] imms = {{20{i_inst[31]}}, i_inst[31:25], i_inst[11:7]};
  wire [31:0] immb = {{19{i_inst[31]}}, i_inst[31], i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0};
  wire [31:0] immr = {25'b0, i_inst[31:25]};

  assign o_imm = is_i ? immi : is_j ? immj : is_u ? immu : is_s ? imms : is_b ? immb : immr;

endmodule
