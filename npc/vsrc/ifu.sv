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

  input i_valid,
  output reg o_valid,
  output o_exception,
  output [3:0] o_mcause,
`ifdef CONFIG_BTB
  input [31:0] i_pc,
  output o_predict,
  input i_predict_err,
  input i_btb_update,
`endif
  input i_ready,
  output o_ready,
  input i_flush,
  AXIFULL_READ.master out
);

ysyx_24110006_ICACHE micache(
  .i_clock(i_clock),
  .i_reset(i_reset),
  .o_inst(o_inst),
  .i_upc(i_upc),
  .i_busy(i_busy),
  .o_pc(o_pc),
  .i_fencei(i_fencei),
  .i_valid(i_valid),
  .o_valid(o_valid),
  .o_exception(o_exception),
  .o_mcause(o_mcause),
`ifdef CONFIG_BTB
  .i_pc(i_pc),
  .o_predict(o_predict),
  .i_predict_err(i_predict_err),
  .i_btb_update(i_btb_update),
`endif
  .i_ready(i_ready),
  .o_ready(o_ready),
  .i_flush(i_flush),
  .out(out)
);

/* reg [31:0] pc; */
/* reg [31:0] inst; */
/**/
/* assign o_inst = inst; */
/**/
/* always@(posedge i_clock)begin */
/*   if(i_reset) o_valid <= 0; */
/*   else if(rvalid && !o_valid) begin */
/*     o_valid <= 1; */
/*   end */
/*   else if(o_valid)begin */
/*     o_valid <= 0; */
/*   end */
/* end */
/**/
/* always@(posedge i_clock)begin */
/*   if(i_reset) inst <= 0; */
/*   else if(rvalid && !o_valid) inst <= i_axi_rdata; */
/* end */
/**/
/* always@(posedge i_clock)begin */
/*   if(!i_reset && !o_valid && i_valid) */
/*     pc <= i_pc; */
/* end */
/* assign o_pc = pc; */
/* always@(posedge i_clock)begin */
/*   if(!i_reset && !o_valid && i_valid) */
/*     o_inst <= inst_fetch(i_pc); */
/* end */

/* reg arvalid; */
/* wire arready; */
/* wire rvalid; */
/* wire rready = 1; */
/* wire [1:0] rresp; */
/**/
/* assign o_axi_araddr = pc; */
/* assign o_axi_arvalid = arvalid; */
/* assign arready = i_axi_arready; */
/* assign o_axi_arid = 0; */
/* assign o_axi_arlen = 0; */
/* assign o_axi_arsize = 3'b010; */
/* assign o_axi_arburst = 0; */
/**/
/* assign rvalid = i_axi_rvalid; */
/* assign rresp = i_axi_rresp; */
/* assign o_axi_rready = rready; */
/**/
/**/
/* always@(posedge i_clock) begin */
/*   if(i_reset) arvalid <= 0; */
/*   else if(i_valid && !arvalid) arvalid <= 1; */
/*   else if(arvalid && arready) arvalid <= 0; */
/* end */
endmodule
