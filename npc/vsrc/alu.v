`include "alu_config.v"
module ysyx_24110006_ALU(
  input [31:0] i_a,
  input [31:0] i_b,
  input i_sub,
  input i_sign,
  input [`ALU_TYPE-1:0] i_alu_t,
  output reg [31:0] o_r,
  output o_cmp,
  /* output o_zero, */
  /* output [1:0] o_branch_mid, */
  output [31:0] o_add_r
);

  wire signed [31:0] a, b;
  assign a = i_a;

  wire cout;
  wire [4:0] shift_num = i_b[4:0];
  wire[31:0] add_r;
  /* assign o_branch_mid[0] = i_sign; */
  /* assign o_branch_mid[1] = and_r[31]; */
  /* assign o_branch_mid[2] = xor_r[31]; */
  /* assign o_branch_mid[3] = ~cout; */
  wire cmp = i_sign ? (i_a[31]&i_b[31] | add_r[31]&(i_a[31]^i_b[31])) : ~cout;
  assign {cout, add_r} = i_a + i_b + {31'b0, i_sub};
  /* assign add_r = i_a + i_b; */
  wire [31:0] sll_r = i_a << shift_num;
  wire [31:0] slt_r = {31'b0, cmp};
  wire [31:0] xor_r = i_a ^ i_b;
  wire [31:0] srl_r = a >> shift_num;
  wire [31:0] sra_r = a >>> shift_num;
  wire [31:0] or_r  = i_a | i_b;
  wire [31:0] and_r = i_a & i_b;
  assign o_r = {32{i_alu_t[`ALU_ADD]}}&add_r |
               {32{i_alu_t[`ALU_SLL]}}&sll_r |
               {32{i_alu_t[`ALU_SLT]}}&slt_r |
               {32{i_alu_t[`ALU_XOR]}}&xor_r |
               {32{i_alu_t[`ALU_SRL]}}&srl_r |
               {32{i_alu_t[`ALU_SRA]}}&sra_r |
               {32{i_alu_t[`ALU_OR ]}}&or_r  |
               {32{i_alu_t[`ALU_AND]}}&and_r;

  assign o_add_r = add_r;
  assign o_cmp = cmp;
  /* assign o_zero = add_r == 0; */
endmodule
