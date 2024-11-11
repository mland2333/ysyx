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
wire[4:0] rs1, rs2, rd;
wire[31:0] imm, src1, src2;
wire[31:0] reg_src1, reg_src2;
wire reg_wen;
wire[31:0] result;
ysyx_20020207_PC mpc(
  .clock(clock),
  .reset(reset),
  .jump(jump),
  .upc(upc),
  .pc(pc)
);

ysyx_20020207_IFU mifu(
  .en(!reset),
  .pc(pc),
  .inst(inst)
);

always@ *
  if(inst == 32'h100073)
    quit();

ysyx_20020207_IDU midu(
  .inst(inst),
  .op(op),
  .func(func),
  .rs1(rs1),
  .rs2(rs2),
  .rd(rd),
  .imm(imm)
);

ysyx_20020207_RegisterFile mreg(
  .clock(clock),
  .waddr(rd),
  .wdata(result),
  .raddr1(rs1),
  .raddr2(rs2),
  .wen(reg_wen),
  .rdata1(reg_src1),
  .rdata2(reg_src2)
);

assign src1 = reg_src1;
assign src2 = imm;

ysyx_20020207_EXU mexu(
  .op(op),
  .func(func),
  .src1(src1),
  .src2(src2),
  .result(result),
  .reg_wen(reg_wen)
);

endmodule
