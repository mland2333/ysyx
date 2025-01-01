module ysyx_24110006_ALU(
  input [31:0] i_a,
  input [31:0] i_b,
  input i_sub,
  input i_sign,
  input [3:0] i_alu_t,
  input i_alu_sra,
  output [31:0] o_r,
  output o_branch
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

  wire CF, OF, ZF;
  wire [31:0] results[8];
  wire [4:0] shift_num = i_b[4:0];
  wire[31:0] add_result, shift_result, logic_result;
  wire cmp;
  assign cmp = i_sign ? OF ^ add_result[31] : ~CF;
  assign ZF = ~(|add_result);
  assign OF = a[31] == b[31] && a[31] != add_result[31];
  assign {CF, add_result} = a + b + {31'b0, i_sub};
  assign results[0] = add_result;
  assign results[1] = a << shift_num;
  assign results[2] = {31'b0, cmp};
  assign results[3] = {31'b0, cmp};
  assign results[4] = a ^ i_b;
  assign results[5] = i_alu_sra ? a >>> shift_num : a >> shift_num;
  assign results[6] = a | i_b;
  assign results[7] = a & i_b;
  
  assign o_r = results[i_alu_t[2:0]];
  assign o_branch = (i_alu_t==BEQ)&&ZF||(i_alu_t==BNE)&&~ZF||(i_alu_t==BLT||i_alu_t==BLTU)&&cmp||(i_alu_t==BGE||i_alu_t==BGEU)&&~cmp;

endmodule
