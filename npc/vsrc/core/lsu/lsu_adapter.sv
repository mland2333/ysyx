module ysyx_24110006_LSU_ADAPTER (
    // LSU interface
    if_lsu_adapter.slave  i_lsu_adapter,
`ifdef CONFIG_DCACHE
    // Direct AXI interface (when USE_CACHE=0)
    if_lsu_dcache.master  o_lsu_dcache,
`endif
    if_lsu_adapter.master o_lsu_adapter
);
`ifdef CONFIG_DCACHE
  logic in_dcache;
`ifdef CONFIG_YSYXSOC
  assign in_dcache = i_lsu_adapter.addr[31]==1 || i_lsu_adapter.addr[29:28]==2'b11 || i_lsu_adapter.addr[31:24]==8'h0f;
`else
  assign in_dcache = i_lsu_adapter.addr[31:28]==4'b1000;
`endif
  assign o_lsu_dcache.rq = in_dcache ? i_lsu_adapter.rq : 0;
  assign o_lsu_dcache.ren = in_dcache ? i_lsu_adapter.ren : 0;
  assign o_lsu_dcache.wen = in_dcache ? i_lsu_adapter.wen : 0;
  assign o_lsu_dcache.addr = in_dcache ? i_lsu_adapter.addr : 0;
  assign o_lsu_dcache.wdata = in_dcache ? i_lsu_adapter.wdata : 0;
  assign o_lsu_dcache.wmask = in_dcache ? i_lsu_adapter.wmask : 0;
  assign o_lsu_dcache.ready = in_dcache ? i_lsu_adapter.ready : 0;

  assign o_lsu_adapter.rq = !in_dcache ? i_lsu_adapter.rq : 0;
  assign o_lsu_adapter.wen = !in_dcache ? i_lsu_adapter.wen : 0;
  assign o_lsu_adapter.ren = !in_dcache ? i_lsu_adapter.ren : 0;
  assign o_lsu_adapter.addr = !in_dcache ? i_lsu_adapter.addr : 0;
  assign o_lsu_adapter.wdata = !in_dcache ? i_lsu_adapter.wdata : 0;
  assign o_lsu_adapter.wmask = !in_dcache ? i_lsu_adapter.wmask : 0;
  assign o_lsu_adapter.read_t = !in_dcache ? i_lsu_adapter.read_t : 0;
  assign o_lsu_adapter.ready = !in_dcache ? i_lsu_adapter.ready : 0;

  assign i_lsu_adapter.rdata = in_dcache ? o_lsu_dcache.rdata : o_lsu_adapter.rdata;
  assign i_lsu_adapter.valid = in_dcache ? o_lsu_dcache.valid : o_lsu_adapter.valid;
  assign i_lsu_adapter.ack = in_dcache ? o_lsu_dcache.ack : o_lsu_adapter.ack;
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

