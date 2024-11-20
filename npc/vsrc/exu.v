module ysyx_24110006_EXU(
  input [6:0] i_op,
  input [2:0] i_func,
  input [31:0] i_reg_src1,
  input [31:0] i_reg_src2,
  input [31:0] i_csr_src,
  input [31:0] i_imm,
  input [31:0] i_pc,
  input [31:0] i_csr_upc,
  output [31:0] o_result,
  output [31:0] o_upc,
  output o_result_t,
  output [2:0] o_csr_t,
  output o_reg_wen,
  output o_csr_wen,
  output o_jump,
  output o_trap,
  output o_branch,
  output o_mem_ren,
  output o_mem_wen,
  output [3:0] o_mem_wmask,
  output [2:0] o_mem_read_t
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

wire f000 = i_func == 3'b000;
wire f001 = i_func == 3'b001;
wire f010 = i_func == 3'b010;
wire f011 = i_func == 3'b011;
wire f100 = i_func == 3'b100;
wire f101 = i_func == 3'b101;
wire f110 = i_func == 3'b110;
wire f111 = i_func == 3'b111;

assign o_result_t = L;
assign o_mem_wen = S;
assign o_mem_ren = L;
assign o_mem_wmask = S ? (f000 ? 4'b0001 : f001 ? 4'b0011 : 4'b1111) : 0;
assign o_mem_read_t = L ? i_func : 0;

wire [31:0] alu_a, alu_b;
wire alu_sub;
wire alu_sign;
wire alu_sra;
wire [3:0] alu_t;
wire branch;
assign alu_a = JAL || JALR || AUIPC ? i_pc : LUI ? 0 : i_reg_src1;
assign alu_b = I || L || AUIPC || S  || LUI ? i_imm : JAL || JALR ? 32'b100 : CSR && f001 ? 32'b0 : CSR && f010 ? i_csr_src : i_reg_src2;
assign alu_t = I||R ? {1'b0, i_func} : B ? {1'b1, i_func} : CSR && f010 ? 4'b0110 : 0;
assign alu_sign = R && f010 || B && (f100 || f101);
assign alu_sub = (I || R) && (f011 || f010) || B || R && f000 && i_imm[5];
assign alu_sra = R && i_imm[5] || I && i_imm[10];

localparam MRET = 3'b000;
localparam CSRW = 3'b001;
localparam ECALL = 3'b011;
assign o_csr_t = f000 ? (i_imm[1] ? MRET : ECALL) : CSRW;

ysyx_24110006_ALU malu(
  .i_a(alu_a),
  .i_b(alu_b),
  .i_sub(alu_sub),
  .i_sign(alu_sign),
  .i_alu_t(alu_t),
  .i_alu_sra(alu_sra),
  .o_r(o_result),
  .o_branch(o_branch)
);
assign o_upc = CSR ? i_csr_upc : (JALR ? i_reg_src1 : i_pc) + i_imm;

assign o_jump = JAL || JALR;
assign o_trap = CSR && f000;
assign o_reg_wen = !(S || B);
assign o_csr_wen = CSR;

endmodule
