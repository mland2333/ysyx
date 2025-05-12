`include "common_config.sv"
module ysyx_24110006_BRU (
    input i_clock,
    input i_reset,

    input [1:0] i_csr_t,

    input [31:0] i_result,
    output [1:0] o_csr_t,
    output [31:0] o_result,
    input [4:0] i_reg_rd,
    output [4:0] o_reg_rd,
    input i_reg_wen,
    output o_reg_wen,
    input [31:0] i_pc,
    output [31:0] o_pc,
    input [31:0] i_upc,
    output [31:0] o_upc,
    input i_jump,
    output o_jump,

    input [`BRANCH_MID] i_branch_mid,
    input [11:0] i_csr,
    output [11:0] o_csr,
    input i_exception,
    output o_exception,
    input [3:0] i_mcause,
    output [3:0] o_mcause,
    input i_flush,

    output o_branch,
    input i_predict,
    output o_predict,
    output o_predict_err,
    output o_btb_update,
`ifdef CONFIG_SIM
    input [6:0] i_op,
    output [6:0] o_op,
    output o_sim_branch,
`endif
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr
);

  reg ren;
  reg wen;
  reg [31:0] result;
  reg [4:0] reg_rd;
  reg result_t;
  reg reg_wen;
  reg [1:0] csr_t;
  wire update_reg;

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
  reg exception;
  always @(posedge i_clock) begin
    if (update_reg) exception <= i_exception;
  end
  assign o_exception = exception;
  reg [3:0] mcause;
  always @(posedge i_clock) begin
    if (update_reg) mcause <= i_mcause;
  end
  assign o_mcause = mcause;

  reg [31:0] upc;
  always @(posedge i_clock) begin
    if (update_reg) upc <= i_upc;
  end
  assign o_upc = upc;
`ifdef CONFIG_SIM

  reg [6:0] op;
  always @(posedge i_clock) begin
    if (update_reg) op <= i_op;
  end
  assign o_op = op;
  assign o_sim_branch = branch;
`endif

  reg jump;
  always @(posedge i_clock) begin
    if (update_reg) jump <= i_jump;
  end
  assign o_jump = jump;
  reg [31:0] pc;
  always @(posedge i_clock) begin
    if (update_reg) pc <= i_pc;
  end
  assign o_pc = pc;

  reg [11:0] csr;
  always @(posedge i_clock) begin
    if (update_reg) csr <= i_csr;
  end
  assign o_csr = csr;
  reg [`BRANCH_MID] branch_mid;
  always @(posedge i_clock) begin
    if (update_reg) branch_mid <= i_branch_mid;
  end
  reg predict;
  always @(posedge i_clock) begin
    if (update_reg) predict <= i_predict;
  end
  assign o_predict = predict;
  assign o_predict_err = predict && !branch;
  assign o_btb_update = !predict && branch_mid[`BRANCH_BACK];
  always @(posedge i_clock) begin
    if (update_reg) begin
      reg_rd  <= i_reg_rd;
      result  <= i_result;
      reg_wen <= i_reg_wen;
      csr_t   <= i_csr_t;
    end
  end
  assign o_reg_wen = reg_wen;
  assign o_reg_rd  = reg_rd;
  assign o_csr_t   = csr_t;
  wire zero = branch_mid[`ZERO];
  wire cmp = branch_mid[`CMP];
  wire branch = branch_mid[`BEQ] & zero | branch_mid[`BNE] & ~zero | branch_mid[`BLT] & cmp | branch_mid[`BGE] & ~cmp;
  assign o_branch = (predict ^ branch) & (branch_mid[`BRANCH]);
  assign o_result = result;


endmodule
