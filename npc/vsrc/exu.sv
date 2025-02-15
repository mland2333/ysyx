`include "alu_config.sv"
`include "common_config.sv"
module ysyx_24110006_EXU(
  input i_clock,
  input i_reset,
  input [6:0] i_op,
  input [2:0] i_func,
  input [31:0] i_alu_a,
  input [31:0] i_alu_b,
  input [`ALU_TYPE-1:0] i_alu_t,
  input i_alu_sign,
  input i_alu_sub,
  input [4:0] i_reg_rd,
  input [1:0] i_csr_t,
  input [11:0] i_csr,
  input [31:0] i_reg_src1,
  input [31:0] i_reg_src2,
  input [31:0] i_imm,
  input [31:0] i_pc,
  input [31:0] i_csr_upc,

  output [31:0] o_result,
  output [31:0] o_upc,
  output o_result_t,
  output [1:0] o_csr_t,
  output o_reg_wen,
  output o_jump,
  output o_mem_ren,
  output o_mem_wen,
  output [3:0] o_mem_wmask,
  output [2:0] o_mem_read_t,
  output [31:0] o_mem_addr,
  output [31:0] o_mem_wdata,
  output [4:0] o_reg_rd,
  output [31:0] o_pc,
  output o_fencei,
  output [6:0] o_op,
  output [11:0] o_csr,
  output [`BRANCH_MID] o_branch_mid,
  input i_predict,
  output o_predict,
  output o_btb_update,
  if_pipeline_vr.in i_vr,
  if_pipeline_vr.out o_vr,
  input i_stall,
  input i_flush,
  output o_flush,
  input i_exception,
  output o_exception,
  input [3:0] i_mcause,
  output [3:0] o_mcause
);

reg [6:0] op;
reg [2:0] func;
reg [31:0] reg_src1;
reg [31:0] imm;
reg [31:0] pc;
reg [4:0] reg_rd;
reg [1:0] csr_t;
reg [31:0] mem_wdata;
wire update_reg;
reg [31:0] reg_src2;
logic r_valid;
assign r_valid = i_vr.valid & ~i_stall;
always@(posedge i_clock)begin
  if(i_reset) o_vr.valid <= 0;
  else if(r_valid && !i_flush) begin
    o_vr.valid <= 1;
  end
  else if(o_vr.valid && o_vr.ready) begin
    o_vr.valid <= 0;
  end
end
reg r_ready;
always@(posedge i_clock)begin
  if(i_reset) r_ready <= 1;
  else if(r_valid && o_vr.valid && (o_mem_wen || o_mem_ren)) r_ready <= 0;
  else if(o_vr.ready) r_ready <= 1;
  else if(r_valid) r_ready <= 0;
end
assign i_vr.ready = r_ready | o_vr.ready;
assign update_reg = r_valid && (r_ready || o_vr.ready) && !i_flush;
reg flush_valid;
always@(posedge i_clock)begin
  if(i_reset) flush_valid <= 0;
  else if(update_reg) flush_valid <= 1;
  else if(flush_valid) flush_valid <= 0;
end

assign o_flush = (JALR | csr_t[1] | JAL & ~predict) & flush_valid;

reg exception;
always@(posedge i_clock)begin
  if(update_reg)
    exception <= i_exception;
end
assign o_exception = exception;
reg [3:0] mcause;
always@(posedge i_clock)begin
  if(update_reg)
    mcause <= i_mcause;
end
assign o_mcause = mcause;


reg [11:0] csr;
always@(posedge i_clock)begin
  if(update_reg)
    csr <= i_csr;
end
assign o_csr = csr;

always@(posedge i_clock)begin
  if(update_reg)
    op <= i_op;
end
always@(posedge i_clock)begin
  if(update_reg)
    func <= i_func;
end
always@(posedge i_clock)begin
  if(update_reg)
    reg_src1 <= i_reg_src1;
end
always@(posedge i_clock)begin
  if(update_reg)
    imm <= i_imm;
end
always@(posedge i_clock)begin
  if(update_reg)
    pc <= i_pc;
end
always@(posedge i_clock)begin
  if(update_reg)
    reg_rd <= i_reg_rd;
end
always@(posedge i_clock)begin
  if(update_reg)
    csr_t <= i_csr_t;
end
always@(posedge i_clock)begin
  if(update_reg)
    reg_src2 <= i_reg_src2;
end
always@(posedge i_clock)begin
  if(update_reg)
    upc <= (i_op == 7'b1110011 && i_func == 0) ? i_csr_upc : (i_op == 7'b1100111 ? i_reg_src1 : i_pc);
end

always@(posedge i_clock)begin
  if(update_reg) alu_a <= i_alu_a;
end
always@(posedge i_clock)begin
  if(update_reg) alu_b <= i_alu_b;
end
always@(posedge i_clock)begin
  if(update_reg) alu_sub <= i_alu_sub;
end
always@(posedge i_clock)begin
  if(update_reg) alu_sign <= i_alu_sign;
end
always@(posedge i_clock)begin
  if(update_reg) alu_t <= i_alu_t;
end

reg predict;
always@(posedge i_clock)begin
  if(update_reg)
    predict <= i_predict;
end
assign o_predict = predict;
assign o_btb_update = !predict && JAL && flush_valid;

wire I = op[6:2] == 5'b00100;
wire R = op[6:2] == 5'b01100;
wire L = op[6:2] == 5'b00000;
wire S = op[6:2] == 5'b01000;
wire JAL = op[6:2] == 5'b11011;
wire JALR = op[6:2] == 5'b11001;
wire AUIPC = op[6:2] == 5'b00101;
wire LUI = op[6:2] == 5'b01101;
wire B = op[6:2] == 5'b11000;
wire CSR = op[6:2] == 5'b11100;
wire FENCE = op[6:2] == 5'b00011;

wire is_beq = B & f000;
wire is_bne = B & f001;
wire is_blt = B & (f100|f110);
wire is_bge = B & (f101|f111);

wire f000 = func == 3'b000;
wire f001 = func == 3'b001;
wire f010 = func == 3'b010;
wire f011 = func == 3'b011;
wire f100 = func == 3'b100;
wire f101 = func == 3'b101;
wire f110 = func == 3'b110;
wire f111 = func == 3'b111;

assign o_result_t = L;
assign o_mem_wen = S;
assign o_mem_ren = L;
assign o_mem_wmask = S ? (f000 ? 4'b0001 : f001 ? 4'b0011 : 4'b1111) : 0;
assign o_mem_read_t = L ? func : 0;
assign o_fencei = (FENCE && f001) && flush_valid;
assign o_reg_rd = reg_rd;
assign o_csr_t = csr_t;
assign o_pc = pc;
assign o_mem_wdata = reg_src2;
assign o_op = op;

reg [31:0] alu_a, alu_b;
reg alu_sub;
reg alu_sign;
reg [`ALU_TYPE-1:0] alu_t;
wire cmp, zero;
/* wire branch = is_beq & zero | is_bne & ~zero | is_blt & cmp | is_bge & ~cmp; */

ysyx_24110006_ALU malu(
  .i_a(alu_a),
  .i_b(alu_b),
  .i_sub(alu_sub),
  .i_sign(alu_sign),
  .i_alu_t(alu_t),
  .o_r(o_result),
  .o_cmp(cmp),
  /* .o_zero(zero), */
  .o_add_r(o_mem_addr)
);
assign o_branch_mid[`BRANCH] = B;
assign o_branch_mid[`BRANCH_BACK] = B & (imm[31]);
assign o_branch_mid[`ZERO] = reg_src1 == reg_src2;
assign o_branch_mid[`CMP] = cmp;
assign o_branch_mid[`BEQ] = is_beq;
assign o_branch_mid[`BNE] = is_bne;
assign o_branch_mid[`BLT] = is_blt;
assign o_branch_mid[`BGE] = is_bge;
reg [31:0] upc;

assign o_upc = upc + imm;
assign o_jump = JAL | JALR | csr_t[1];
assign o_reg_wen = !(S || B);
endmodule
