module ysyx_24110006_LSU_ADAPTER (
    // LSU interface
    if_lsu_adapter.slave  i_lsu_adapter,
`ifdef CONFIG_DCACHE
    // Direct AXI interface (when USE_CACHE=0)
    if_lsu_dcache.master  o_lsu_dcache
`else
    if_lsu_adapter.master o_lsu_adapter
`endif
);
`ifdef CONFIG_DCACHE
  assign o_lsu_dcache.rq = i_lsu_adapter.rq;
  assign o_lsu_dcache.ren = i_lsu_adapter.ren;
  assign o_lsu_dcache.wen = i_lsu_adapter.wen;
  assign o_lsu_dcache.addr = i_lsu_adapter.addr;
  assign o_lsu_dcache.wdata = i_lsu_adapter.wdata;
  assign o_lsu_dcache.wmask = i_lsu_adapter.wmask;
  assign o_lsu_dcache.ready = i_lsu_adapter.ready;
  assign o_lsu_dcache.flush = i_lsu_adapter.fencei;
  assign i_lsu_adapter.rdata = o_lsu_dcache.rdata;
  assign i_lsu_adapter.valid = o_lsu_dcache.valid;
  assign i_lsu_adapter.ack = o_lsu_dcache.ack;
  assign i_lsu_adapter.fencei_fin = o_lsu_dcache.flush_fin;
`else
  assign o_lsu_adapter.rq = i_lsu_adapter.rq;
  assign o_lsu_adapter.wen = i_lsu_adapter.wen;
  assign o_lsu_adapter.ren = i_lsu_adapter.ren;
  assign o_lsu_adapter.addr = i_lsu_adapter.addr;
  assign o_lsu_adapter.wdata = i_lsu_adapter.wdata;
  assign o_lsu_adapter.wmask = i_lsu_adapter.wmask;
  assign o_lsu_adapter.read_t = i_lsu_adapter.read_t;
  assign o_lsu_adapter.ready = i_lsu_adapter.ready;
  assign i_lsu_adapter.rdata = o_lsu_adapter.rdata;
  assign i_lsu_adapter.valid = o_lsu_adapter.valid;
  assign i_lsu_adapter.ack = o_lsu_adapter.ack;
`endif
endmodule

