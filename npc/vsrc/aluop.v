module ysyx_24110006_ALUOP(
  input [31:0] i_src1, 
  input [31:0] i_src2, 
  input [31:0] i_imm, 
  input [31:0] i_csr_rdata, 
  input [31:0] i_pc,
  input [6:0] i_op,
  input [2:0] i_func,
  output [31:0] o_alu_a, 
  output [31:0] o_alu_b,
  output o_alu_sub,
  output o_alu_sign,
  output [3:0] o_alu_t,
  output o_alu_sra
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
wire CSR = i_op == 7'b1110011;
wire FENCEI = i_op == 7'b0001111;
wire f000 = i_func == 3'b000;
wire f001 = i_func == 3'b001;
wire f010 = i_func == 3'b010;
wire f011 = i_func == 3'b011;
wire f100 = i_func == 3'b100;
wire f101 = i_func == 3'b101;
wire f110 = i_func == 3'b110;
wire f111 = i_func == 3'b111;

assign o_alu_a = JAL || JALR || AUIPC ? i_pc : LUI ? 0 : i_src1;
wire [31:0]b0 = I || L || AUIPC || S  || LUI ? i_imm : JAL || JALR ? 32'b100 :
        CSR && f001 ? 32'b0 : CSR && f010 ? i_csr_rdata : i_src2;
assign o_alu_b = o_alu_sub ? ~b0 : b0;
assign o_alu_t = I||R ? {1'b0, i_func} : B ? {1'b1, i_func} : CSR && f010 ? 4'b0110 : 0;
assign o_alu_sign = R && f010 || B && (f100 || f101);
assign o_alu_sub = (I || R) && (f011 || f010) || B || R && f000 && i_imm[5];
assign o_alu_sra = R && i_imm[5] || I && i_imm[10];

endmodule


