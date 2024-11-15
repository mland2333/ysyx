module ysyx_24110006_EXU(
  input [6:0] i_op,
  input [2:0] i_func,
  input [31:0] i_reg_src1,
  input [31:0] i_reg_src2,
  input [31:0] i_imm,
  input [31:0] i_pc,
  output [31:0] o_result,
  output o_reg_wen,
  output o_jump,
  output [31:0] o_upc
);


wire I = i_op == 7'b0010011;
wire R = i_op == 7'b0110011;
wire L = i_op == 7'b0000011;
wire S = i_op == 7'b0100011;
wire JAL = i_op == 7'b1101111;
wire JALR = i_op == 7'b1100111;
wire AUIPC = i_op == 7'b0010111;
wire LUI = i_op == 7'b0110111;
wire B = i_op == 7'b1100011;
wire f000 = i_func == 3'b000;
wire f001 = i_func == 3'b001;
wire f010 = i_func == 3'b010;
wire f011 = i_func == 3'b011;
wire f100 = i_func == 3'b100;
wire f101 = i_func == 3'b101;
wire f110 = i_func == 3'b110;
wire f111 = i_func == 3'b111;

wire [31:0] alu_a, alu_b;
assign alu_a = JAL || JALR || AUIPC ? i_pc : LUI ? 0 : i_reg_src1;
assign alu_b = I || L || AUIPC || S  || LUI ? i_imm : JAL || JALR ? 32'b100 : i_reg_src2;


ysyx_24110006_ALU malu(
  .i_a(alu_a),
  .i_b(alu_b),
  .o_r(o_result)
);

assign o_jump = JAL || JALR;
assign o_upc = (JAL ? i_pc : i_reg_src1) + i_imm;
assign o_reg_wen = !(S || B);

endmodule
