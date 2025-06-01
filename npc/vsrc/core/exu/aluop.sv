`include "alu_config.sv"
module ysyx_24110006_ALUOP(
  input pipe::reg_rdata_t from_forward,
  input pipe::csr_rdata_t from_csr,
  input pipe::idu2aluop_t from_idu,
  output alu::op_t op
);

wire I = from_idu.op == 7'b0010011;
wire R = from_idu.op == 7'b0110011;
wire L = from_idu.op == 7'b0000011;
wire S = from_idu.op == 7'b0100011;
wire JAL = from_idu.op == 7'b1101111;
wire JALR = from_idu.op == 7'b1100111;
wire AUIPC = from_idu.op == 7'b0010111;
wire LUI = from_idu.op == 7'b0110111;
wire B = from_idu.op == 7'b1100011;
wire CSR = from_idu.op == 7'b1110011;
wire FENCEI = from_idu.op == 7'b0001111;
wire f000 = from_idu.func == 3'b000;
wire f001 = from_idu.func == 3'b001;
wire f010 = from_idu.func == 3'b010;
wire f011 = from_idu.func == 3'b011;
wire f100 = from_idu.func == 3'b100;
wire f101 = from_idu.func == 3'b101;
wire f110 = from_idu.func == 3'b110;
wire f111 = from_idu.func == 3'b111;

// 先计算sub信号，避免在op.b中使用op.sub
wire sub_signal = (I || R) && (f011 || f010) || B || R && f000 && from_idu.imm[5];

assign op.a = JAL || JALR || AUIPC ? from_idu.pc : LUI ? 0 : from_forward.r1;
wire [31:0]b0 = I || L || AUIPC || S  || LUI ? from_idu.imm : JAL || JALR ? 32'b100 :
        CSR && f001 ? 32'b0 : CSR && f010 ? from_csr.r1 : from_forward.r2;
assign op.b = sub_signal ? ~b0 : b0;
assign op.alu_t[`ALU_ADD] = (I|R)&f000|AUIPC|LUI|B|L|S|JAL|JALR|CSR&~f010;
assign op.alu_t[`ALU_SLL] = (I|R)&f001;
assign op.alu_t[`ALU_SLT] = (I|R)&(f010|f011);
assign op.alu_t[`ALU_XOR] = (I|R)&f100;
assign op.alu_t[`ALU_SRL] = (I&~from_idu.imm[10]|R&~from_idu.imm[5])&f101;
assign op.alu_t[`ALU_SRA] = (R&from_idu.imm[5]|I&from_idu.imm[10])&f101;
assign op.alu_t[`ALU_OR]  = (I|R)&f110|CSR&f010;
assign op.alu_t[`ALU_AND] = (I|R)&f111;

assign op.sign = R && f010 || B && (f100 || f101);
assign op.sub = sub_signal;

endmodule


