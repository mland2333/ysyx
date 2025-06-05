`include "common_config.sv"
module ysyx_24110006_BRU (
    input i_clock,
    input i_reset,
    input pipe::exu2bru_t from_exu,
    output pipe::wbu_t to_wbu,
    output pipe::csr_winfo_t to_csr,
    output pipe::csr_einfo_t csr_einfo,
    output [31:0] o_upc,
    output o_jump,
    output o_fencei,
    input i_flush,
    output o_branch,
    output o_quit,
    output o_csr_flush,
    /* input i_predict, */
    /* output o_predict, */
    /* output o_predict_err, */
    /* output o_btb_update, */
`ifdef CONFIG_SIM
    output o_sim_branch,
    input pipe::sim_t i_sim,
    output pipe::sim_t o_sim,
`endif
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr
);
  pipe::exu2bru_t exu_data;
  logic update_reg;
  always @(posedge i_clock) begin
    if (update_reg) exu_data <= from_exu;
  end

  always @(posedge i_clock) begin
    if (i_reset) o_vr.valid <= 0;
    else if (i_vr.valid && i_vr.ready && !i_flush) begin
      o_vr.valid <= 1;
    end else if (o_vr.valid) begin
      o_vr.valid <= 0;
    end
  end
  always @(posedge i_clock) begin
    i_vr.ready <= 1;
  end

  assign update_reg = !i_reset && i_vr.valid && i_vr.ready && !i_flush;

`ifdef CONFIG_SIM

  always @(posedge i_clock) begin
    if (update_reg) o_sim <= i_sim;
  end
  assign o_sim_branch = branch & o_vr.valid;
  always_ff @(posedge i_clock) begin
    if (update_reg) o_sim <= i_sim;
  end
`endif
  /* reg predict; */
  /* always @(posedge i_clock) begin */
  /*   if (update_reg) predict <= i_predict; */
  /* end */
  /* assign o_predict = predict; */
  /* assign o_predict_err = predict && !branch && branch_mid[`BRANCH]; */
  /* assign o_btb_update = !predict && branch_mid[`BRANCH_BACK] && branch_mid[`BRANCH]; */
  /* assign o_csr_t = o_vr.valid ? exu_data.csr_t : 0; */
  wire zero = exu_data.branch_mid[`ZERO];
  wire cmp = exu_data.branch_mid[`CMP];
  wire branch = exu_data.branch_mid[`BEQ] & zero | exu_data.branch_mid[`BNE] & ~zero | exu_data.branch_mid[`BLT] & cmp | exu_data.branch_mid[`BGE] & ~cmp;
  assign o_branch = branch & (exu_data.branch_mid[`BRANCH]) & o_vr.valid;
  assign o_jump = exu_data.jump && o_vr.valid;
  assign o_csr_flush = exu_data.csr_t[0] & o_vr.valid;
  assign o_fencei = exu_data.fencei & o_vr.valid;
  assign o_upc = exu_data.upc;
  assign o_quit = exu_data.quit && o_vr.valid;

  assign to_wbu.result = exu_data.result;
  assign to_wbu.reg_wen = exu_data.reg_wen;
  assign to_wbu.reg_rd = exu_data.reg_rd;
  assign to_wbu.pc = exu_data.pc;

  assign csr_einfo.pc = exu_data.pc;
  assign csr_einfo.exception = exu_data.exception;
  assign csr_einfo.mcause = exu_data.mcause;

  assign to_csr.csr_t = exu_data.csr_t;
  assign to_csr.csr_w = exu_data.csr;
  assign to_csr.wdata = exu_data.csr_wdata;

endmodule
