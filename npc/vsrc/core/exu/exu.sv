`include "alu_config.sv"
`include "common_config.sv"
module ysyx_24110006_EXU (
    input i_clock,
    input i_reset,
    input ooo::exu_info_t issue_inst,
    output rob::commit_info_t commit,
    output rename::commit_t rename_commit,
    output rf::winfo_t winfo,
    input i_flush,
    if_pipeline_vr.in i_vr
);
  ooo::exu_info_t exu_info;

  always_ff @(posedge i_clock) begin
    if (update_reg) exu_info <= issue_inst;
  end

  wire  update_reg;
  logic o_valid;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) o_valid <= 0;
    else if (i_vr.valid) o_valid <= 1;
    else if (o_valid) o_valid <= 0;
  end
  assign i_vr.ready = 1;
  assign update_reg = i_vr.valid && !i_flush;

  wire is_beq = exu_info.branch_info.beq;
  wire is_bne = exu_info.branch_info.bne;
  wire is_blt = exu_info.branch_info.blt;
  wire is_bge = exu_info.branch_info.bge;
  wire zero = exu_info.zero;
  alu::result_t alu_result;
  ysyx_24110006_ALU malu (
      .op(exu_info.alu_op),
      .result(alu_result)
  );
  logic branch, cmp;
  rob::result_t wb_result;
  assign cmp = alu_result.cmp;
  assign branch = is_beq & zero | is_bne & ~zero | is_blt & cmp | is_bge & ~cmp;

  /* assign wb_result.result = alu_result.r; */
  assign wb_result.upc = exu_info.upc + exu_info.imm;
  assign wb_result.btb_update = exu_info.branch_info.jal && !exu_info.bp_info.pred_taken ||
    branch && !exu_info.bp_info.pred_taken && exu_info.branch_info.branch_back;
  assign wb_result.flush = (branch || exu_info.branch_info.jal || exu_info.branch_info.jalr) ^
    exu_info.bp_info.pred_taken;
  assign wb_result.call = exu_info.branch_info.jalr && exu_info.vrd == 1;
  assign wb_result.ret = exu_info.branch_info.ret;
  assign commit.result = wb_result;
  assign commit.valid = o_valid;
  assign commit.index = exu_info.rob_index;
  assign winfo.valid = o_valid;
  assign winfo.wen = exu_info.reg_wen;
  assign winfo.rd = exu_info.rd;
  assign winfo.wdata = alu_result.r;
  assign rename_commit.prd = exu_info.rd;
  assign rename_commit.vrd = exu_info.vrd;
  assign rename_commit.valid = o_valid && exu_info.reg_wen;
`ifdef CONFIG_SIM
  assign wb_result.sim.difftest_skip = 0;
`endif

endmodule
