`include "alu_config.v"

module ysyx_24110006_SHIFT (
    input  signed [31:0] a,  // 输入数据
    input  [4:0]  shamt,    // 移位量 (0~31)
    input  [2:0]  op,     // 移位模式: 001=左移, 010=逻辑右移, 100=算术右移
    output [31:0] result  // 输出数据
);
    /* wire [31:0] stage1, stage2, stage3, stage4, stage5; */
    /* wire sign_extend; // 用于算术右移符号扩展 */
    /* assign sign_extend = mode[2] ? data_in[31] : 1'b0; */
    /* // 第1级：移位 16 位 */
    /* assign stage1 = shamt[4] ? (mode[0] ? (data_in << 16) :  */
    /*                             (mode[1] ? (data_in >> 16) :  */
    /*                             {{16{sign_extend}}, data_in[31:16]})) : data_in; */
    /* // 第2级：移位 8 位 */
    /* assign stage2 = shamt[3] ? (mode[0] ? (stage1 << 8) :  */
    /*                             (mode[1] ? (stage1 >> 8) :  */
    /*                             {{8{sign_extend}}, stage1[31:8]})) : stage1; */
    /* // 第3级：移位 4 位 */
    /* assign stage3 = shamt[2] ? (mode[0] ? (stage2 << 4) :  */
    /*                             (mode[1] ? (stage2 >> 4) :  */
    /*                             {{4{sign_extend}}, stage2[31:4]})) : stage2; */
    /* // 第4级：移位 2 位 */
    /* assign stage4 = shamt[1] ? (mode[0] ? (stage3 << 2) :  */
    /*                             (mode[1] ? (stage3 >> 2) :  */
    /*                             {{2{sign_extend}}, stage3[31:2]})) : stage3; */
    /* // 第5级：移位 1 位 */
    /* assign stage5 = shamt[0] ? (mode[0] ? (stage4 << 1) :  */
    /*                             (mode[1] ? (stage4 >> 1) :  */
    /*                             {{1{sign_extend}}, stage4[31:1]})) : stage4; */
    /* // 最终输出 */
    /* assign data_out = stage5; */
  wire [31:0] sll_r = a << shamt;
  wire [31:0] srl_r = a >> shamt;
  wire [31:0] sra_r = a >>> shamt;
  assign result = {32{op[0]}} & sll_r |
                  {32{op[1]}} & srl_r |
                  {32{op[2]}} & sra_r ;
endmodule

module ysyx_24110006_LOGIC (
    input [31:0] a,          // 输入 A
    input [31:0] b,          // 输入 B
    input [2:0] op,   // 操作选择: 00=AND, 01=OR, 10=XOR
    output [31:0] result          // 输出结果
);
    wire [31:0] and_r = a & b;
    wire [31:0] or_r  = a | b;
    wire [31:0] xor_r = a ^ b;
    assign result = {32{op[0]}} & xor_r |
                    {32{op[1]}} & or_r  |
                    {32{op[2]}} & and_r ;
endmodule


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
  wire cmp = i_sign ? (i_a[31]&i_b[31] | add_r[31]&(i_a[31]^i_b[31])) : ~cout;
  assign {cout, add_r} = i_a + i_b + {31'b0, i_sub};

  /* wire [2:0] shift_op = {i_alu_t[`ALU_SRA], i_alu_t[`ALU_SRL], i_alu_t[`ALU_SLL]}; */
  /* wire [2:0] logic_op = {i_alu_t[`ALU_XOR], i_alu_t[`ALU_OR ], i_alu_t[`ALU_AND]}; */
  /* wire [31:0] shift_r; */
  /* wire [31:0] logic_r; */
  /* wire [31:0] slt_r = {31'b0, cmp}; */
  /* ysyx_24110006_SHIFT mshifter( */
  /*   .a(i_a), */
  /*   .shamt(shift_num), */
  /*   .op(shift_op), */
  /*   .result(shift_r) */
  /* ); */
  /* ysyx_24110006_LOGIC mlogic( */
  /*   .a(i_a), */
  /*   .b(i_b), */
  /*   .op(logic_op), */
  /*   .result(logic_r) */
  /* ); */
  /* wire is_logic = i_alu_t[`ALU_XOR] | i_alu_t[`ALU_OR ] | i_alu_t[`ALU_AND]; */
  /* wire is_shift = i_alu_t[`ALU_SLL] | i_alu_t[`ALU_SRL] | i_alu_t[`ALU_SRA]; */
  /* wire is_add   = i_alu_t[`ALU_ADD]; */
  /* wire is_slt   = i_alu_t[`ALU_SLT]; */
  /**/
  /* assign o_r = {32{is_logic}} & logic_r | */
  /*              {32{is_shift}} & shift_r | */
  /*              {32{is_add  }} & add_r   | */
  /*              {32{is_slt  }} & slt_r   ; */
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
