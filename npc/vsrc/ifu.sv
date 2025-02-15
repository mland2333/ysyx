/* import "DPI-C" function int inst_fetch(input int addr); */
`include "common_config.sv"
module ysyx_24110006_IFU(
  input i_clock,
  input i_reset,
  input [31:0] i_upc,
  input i_busy,
  output reg [31:0] o_inst,
  output [31:0] o_pc,
  input i_fencei,

  output o_exception,
  output [3:0] o_mcause,
  input [31:0] i_pc,
  output o_predict,
  input i_predict_err,
  input i_btb_update,
  input i_flush,
  if_pipeline_vr.out o_vr,
  if_axi_read.master o_axi
);

ysyx_24110006_ICACHE micache(
  .i_clock(i_clock),
  .i_reset(i_reset),
  .o_inst(o_inst),
  .i_upc(i_upc),
  .i_busy(i_busy),
  .o_pc(o_pc),
  .i_fencei(i_fencei),
  .o_exception(o_exception),
  .o_mcause(o_mcause),
  .i_pc(i_pc),
  .o_predict(o_predict),
  .i_predict_err(i_predict_err),
  .i_btb_update(i_btb_update),
  .i_flush(i_flush),
  .o_vr(o_vr),
  .o_axi(o_axi)
);

endmodule
