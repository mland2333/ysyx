module ysyx_24110006_ALU(
  input [31:0] i_a,
  input [31:0] i_b,
  input i_sub,
  input i_sign,
  input [3:0] i_alu_t,
  input i_alu_sra,
  output reg [31:0] o_r,
  output o_cmp,
  output o_zero,
  output [31:0] o_add_r
);
  localparam ADD = 4'b0000;
  localparam SLL = 4'b0001;
  localparam SLT = 4'b0010;
  localparam SLTU = 4'b0011;
  localparam XOR = 4'b0100;
  localparam SRI = 4'b0101;
  localparam OR = 4'b0110;
  localparam AND = 4'b0111;

  localparam BEQ = 4'b1000;
  localparam BNE = 4'b1001;
  localparam BLT = 4'b1100;
  localparam BGE = 4'b1101;
  localparam BLTU = 4'b1110;
  localparam BGEU = 4'b1111;

  wire signed [31:0] a, b;
  assign a = i_a;
  assign b = i_b;

  wire cout;
  wire [4:0] shift_num = i_b[4:0];
  wire[31:0] add_r;
  wire cmp;
  assign cmp = i_sign ? (i_a[31]&i_b[31] | add_r[31]&(i_a[31]^i_b[31])) : ~cout;
  assign {cout, add_r} = i_a + i_b + {31'b0, i_sub};
  wire [31:0] sr_r  = i_alu_sra ? a >>> shift_num : a >> shift_num;
  /* wire [31:0] results[8]; */
  /* wire [31:0] sll_r = 0; */
  /* wire [31:0] cmp_r = 0; */
  /* wire [31:0] xor_r = a ^ i_b; */
  /* wire [31:0] sra_r = a >>> shift_num; */
  /* wire [31:0] srl_r = a >> shift_num; */
  /* wire [31:0] or_r  = a | b; */
  /* wire [31:0] and_r = a & i_b; */
  /* assign results[0] = add_r; */
  /* assign results[1] = a << shift_num; */
  /* assign results[2] = 0; */
  /* assign results[3] = 0; */
  /* assign results[4] = a ^ i_b; */
  /* assign results[5] = sr_r; */
  /* assign results[6] = a | i_b; */
  /* assign results[7] = a & i_b; */
  always@*begin
    case(i_alu_t[2:0])
      3'b000: o_r = add_r;
      3'b001: o_r = i_a << shift_num;
      3'b010: o_r = {31'b0, cmp};
      3'b011: o_r = {31'b0, cmp};
      3'b100: o_r = i_a ^ i_b;
      3'b101: o_r = sr_r;
      3'b110: o_r = i_a | i_b;
      3'b111: o_r = i_a & i_b;
    endcase
  end
  /* assign o_r = results[i_alu_t[2:0]]; */
  assign o_add_r = add_r;
  assign o_cmp = cmp;
  assign o_zero = ~(|add_r);
endmodule
