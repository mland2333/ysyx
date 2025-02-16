/* import "DPI-C" function int inst_fetch(input int addr); */
`include "common_config.v"
module ysyx_24110006_IFU(
  input i_clock,
  input i_reset,
`ifndef CONFIG_ICACHE_PIPELINE
  input [31:0] i_pc,
`else
  input [31:0] i_upc,
  input i_busy,
`endif
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
`ifdef CONFIG_ICACHE
  `ifdef CONFIG_PIPELINE
    input i_ready,
    output o_ready,
    input i_flush,
  `endif
`endif
  output [31:0] o_axi_araddr,
  output o_axi_arvalid,
  input i_axi_arready,
  output [3:0] o_axi_arid,
  output [7:0] o_axi_arlen,
  output [2:0] o_axi_arsize,
  output [1:0] o_axi_arburst,

  input [31:0] i_axi_rdata,
  input i_axi_rvalid,
  output o_axi_rready,
  input [1:0] i_axi_rresp,
  input [3:0] i_axi_rid,
  input i_axi_rlast
);

ysyx_24110006_ICACHE micache(
  .i_clock(i_clock),
  .i_reset(i_reset),
  .o_inst(o_inst),
`ifndef CONFIG_ICACHE_PIPELINE
  .i_pc(i_pc),
`else
  .i_upc(i_upc),
  .i_busy(i_busy),
`endif
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
`ifdef CONFIG_PIPELINE
  .i_ready(i_ready),
  .o_ready(o_ready),
  .i_flush(i_flush),
`endif
  .o_axi_araddr(o_axi_araddr),
  .o_axi_arvalid(o_axi_arvalid),
  .i_axi_arready(i_axi_arready),
  .o_axi_arid(o_axi_arid),
  .o_axi_arlen(o_axi_arlen),
  .o_axi_arsize(o_axi_arsize),
  .o_axi_arburst(o_axi_arburst),
  .i_axi_rdata(i_axi_rdata),
  .i_axi_rvalid(i_axi_rvalid),
  .o_axi_rready(o_axi_rready),
  .i_axi_rresp(i_axi_rresp),
  .i_axi_rlast(i_axi_rlast),
  .i_axi_rid(i_axi_rid)
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
