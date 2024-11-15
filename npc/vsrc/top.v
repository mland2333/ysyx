import "DPI-C" function void quit();
module top(
  input clock,
  input reset
);

wire jump;
wire[31:0] upc, pc;

wire[31:0] inst;
wire[6:0] op;
wire[2:0] func;
wire[4:0] reg_rs1, reg_rs2, reg_rd;
wire[31:0] imm, src1, src2;
wire[31:0] reg_src1, reg_src2;
wire reg_wen;
wire[31:0] result;
ysyx_24110006_PC mpc(
  .i_clock(clock),
  .i_reset(reset),
  .i_jump(jump),
  .i_upc(upc),
  .o_pc(pc)
);

ysyx_24110006_IFU mifu(
  .i_en(!reset),
  .i_pc(pc),
  .o_inst(inst)
);

always@ *
  if(inst == 32'h100073)
    quit();

ysyx_24110006_IDU midu(
  .i_inst(inst),
  .o_op(op),
  .o_func(func),
  .o_reg_rs1(reg_rs1),
  .o_reg_rs2(reg_rs2),
  .o_reg_rd(reg_rd),
  .o_imm(imm)
);

ysyx_24110006_RegisterFile mreg(
  .i_clock(clock),
  .i_waddr(reg_rd),
  .i_wdata(result),
  .i_raddr1(reg_rs1),
  .i_raddr2(reg_rs2),
  .i_wen(reg_wen),
  .o_rdata1(reg_src1),
  .o_rdata2(reg_src2)
);

ysyx_24110006_EXU mexu(
  .i_op(op),
  .i_func(func),
  .i_reg_src1(reg_src1),
  .i_reg_src2(reg_src2),
  .i_imm(imm),
  .i_pc(pc),
  .o_result(result),
  .o_reg_wen(reg_wen),
  .o_jump(jump),
  .o_upc(upc)
);

endmodule
