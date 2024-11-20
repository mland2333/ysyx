import "DPI-C" function void quit();
module top(
  input clock,
  input reset
);

wire jump;
wire trap;
wire branch;
wire[31:0] upc, pc;

wire[31:0] inst;
wire[6:0] op;
wire[2:0] func;
wire[4:0] reg_rs1, reg_rs2, reg_rd;
wire[31:0] imm;

wire[31:0] reg_src1, reg_src2, reg_wdata;
wire[31:0] csr_src;

wire reg_wen;
wire csr_wen;
wire[31:0] exu_result;
wire[31:0] csr_mcause = 32'd11;
wire[31:0] csr_upc;
wire[11:0] csr = imm[11:0];
wire[2:0] csr_t;
wire[31:0] csr_wdata;

wire mem_ren, mem_wen;
wire[3:0] mem_wmask;
wire[2:0] mem_read_t;
wire[31:0] mem_addr = exu_result;
wire[31:0] mem_wdata = reg_src2;
wire[31:0] mem_rdata;
wire result_t;

assign reg_wdata = result_t ? mem_rdata : exu_result;
assign csr_wdata = exu_result;

wire pc_valid, ifu_valid, idu_valid, exu_valid, lsu_valid;

reg[31:0] npc_upc;
always@(posedge clock)
  npc_upc <= upc;

ysyx_24110006_PC mpc(
  .i_clock(clock),
  .i_reset(reset),
  .i_jump(jump||branch||trap),
  .i_upc(upc),
  .o_pc(pc),
  .i_valid(lsu_valid),
  .o_valid(pc_valid)
);

ysyx_24110006_IFU mifu(
  .i_clock(clock),
  .i_reset(reset),
  .i_pc(pc),
  .o_inst(inst),
  .i_valid(pc_valid),
  .o_valid(ifu_valid)
);

always@ *
  if(inst == 32'h100073)
    quit();

ysyx_24110006_IDU midu(
  .i_clock(clock),
  .i_reset(reset),
  .i_inst(inst),
  .o_op(op),
  .o_func(func),
  .o_reg_rs1(reg_rs1),
  .o_reg_rs2(reg_rs2),
  .o_reg_rd(reg_rd),
  .o_imm(imm),
  .o_csr_t(csr_t),
  .i_valid(ifu_valid),
  .o_valid(idu_valid)
);

ysyx_24110006_RegisterFile mreg(
  .i_clock(clock),
  .i_waddr(reg_rd),
  .i_wdata(reg_wdata),
  .i_raddr1(reg_rs1),
  .i_raddr2(reg_rs2),
  .i_wen(reg_wen),
  .o_rdata1(reg_src1),
  .o_rdata2(reg_src2),
  .i_valid(lsu_valid)
);

ysyx_24110006_CSR mcsr(
  .i_clock(clock),
  .i_reset(reset),
  .i_wen(csr_wen),
  .i_csr_t(csr_t),
  .i_csr(csr),
  .i_pc(pc),
  .i_mcause(csr_mcause),
  .i_wdata(csr_wdata),
  .o_rdata(csr_src),
  .o_upc(csr_upc),
  .i_valid(exu_valid)
);

ysyx_24110006_EXU mexu(
  .i_clock(clock),
  .i_reset(reset),
  .i_op(op),
  .i_func(func),
  .i_reg_src1(reg_src1),
  .i_reg_src2(reg_src2),
  .i_csr_src(csr_src),
  .i_imm(imm),
  .i_pc(pc),
  .i_csr_upc(csr_upc),
  .o_result(exu_result),
  .o_upc(upc),
  .o_reg_wen(reg_wen),
  .o_csr_wen(csr_wen),
  .o_result_t(result_t),
  .o_jump(jump),
  .o_trap(trap),
  .o_branch(branch),
  .o_mem_ren(mem_ren),
  .o_mem_wen(mem_wen),
  .o_mem_wmask(mem_wmask),
  .o_mem_read_t(mem_read_t),
  .i_valid(idu_valid),
  .o_valid(exu_valid)
);


ysyx_24110006_LSU mlsu(
  .i_clock(clock),
  .i_reset(reset),
  .i_ren(mem_ren),
  .i_wen(mem_wen),
  .i_addr(mem_addr),
  .i_wdata(mem_wdata),
  .i_wmask(mem_wmask),
  .i_read_t(mem_read_t),
  .o_rdata(mem_rdata),
  .i_valid(exu_valid),
  .o_valid(lsu_valid)
);

endmodule
