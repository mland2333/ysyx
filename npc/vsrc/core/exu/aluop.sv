`include "alu_config.sv"
module ysyx_24110006_ALUOP(
  input bypass::src_t src,
  input pipe::csr_rdata_t csr_rdata,
  input ooo::issue_int_t issue_info,
  output ooo::exu_info_t exu_info
);

wire I = issue_info.data.op == 7'b0010011;
wire R = issue_info.data.op == 7'b0110011;
wire L = issue_info.data.op == 7'b0000011;
wire S = issue_info.data.op == 7'b0100011;
wire JAL = issue_info.data.op == 7'b1101111;
wire JALR = issue_info.data.op == 7'b1100111;
wire AUIPC = issue_info.data.op == 7'b0010111;
wire LUI = issue_info.data.op == 7'b0110111;
wire B = issue_info.data.op == 7'b1100011;
wire CSR = issue_info.data.op == 7'b1110011;
wire FENCEI = issue_info.data.op == 7'b0001111;
wire f000 = issue_info.data.func == 3'b000;
wire f001 = issue_info.data.func == 3'b001;
wire f010 = issue_info.data.func == 3'b010;
wire f011 = issue_info.data.func == 3'b011;
wire f100 = issue_info.data.func == 3'b100;
wire f101 = issue_info.data.func == 3'b101;
wire f110 = issue_info.data.func == 3'b110;
wire f111 = issue_info.data.func == 3'b111;

// 先计算sub信号，避免在op.b中使用op.sub
wire sub_signal = (I || R) && (f011 || f010) || B || R && f000 && issue_info.data.imm[5];

assign exu_info.alu_op.a = JAL || JALR || AUIPC ? issue_info.data.pc : LUI ? 0 : src.r1;
wire [31:0]b0 = I || L || AUIPC || S  || LUI ? issue_info.data.imm : JAL || JALR ? 32'b100 :
        CSR && f001 ? 32'b0 : CSR && f010 ? csr_rdata.r1 : src.r2;
assign exu_info.alu_op.b = sub_signal ? ~b0 : b0;
assign exu_info.alu_op.alu_t[`ALU_ADD] = (I|R)&f000|AUIPC|LUI|B|L|S|JAL|JALR|CSR&~f010;
assign exu_info.alu_op.alu_t[`ALU_SLL] = (I|R)&f001;
assign exu_info.alu_op.alu_t[`ALU_SLT] = (I|R)&(f010|f011);
assign exu_info.alu_op.alu_t[`ALU_XOR] = (I|R)&f100;
assign exu_info.alu_op.alu_t[`ALU_SRL] = (I&~issue_info.data.imm[10]|R&~issue_info.data.imm[5])&f101;
assign exu_info.alu_op.alu_t[`ALU_SRA] = (R&issue_info.data.imm[5]|I&issue_info.data.imm[10])&f101;
assign exu_info.alu_op.alu_t[`ALU_OR]  = (I|R)&f110|CSR&f010;
assign exu_info.alu_op.alu_t[`ALU_AND] = (I|R)&f111;
assign exu_info.alu_op.sign = R && f010 || B && (f100 || f101);
assign exu_info.alu_op.sub = sub_signal;

assign exu_info.rob_index = issue_info.rob_index;
assign exu_info.imm = issue_info.data.imm;
assign exu_info.upc = (CSR && f000) ? csr_rdata.upc : (JALR ? src.r1 : issue_info.data.pc);

assign exu_info.branch_info.branch = B;
assign exu_info.branch_info.beq = B & f000;
assign exu_info.branch_info.bne = B & f001;
assign exu_info.branch_info.blt = B & (f100 | f110);
assign exu_info.branch_info.bge = B & (f101 | f111);
assign exu_info.branch_info.jump = JAL | JALR;
assign exu_info.zero = src.r1 == src.r2;
assign exu_info.reg_wen = issue_info.reg_wen;
assign exu_info.rd = issue_info.rd;
assign exu_info.vrd = issue_info.vrd;

endmodule


