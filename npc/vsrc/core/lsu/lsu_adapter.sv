module ysyx_24110006_LSU_ADAPTER (
    // LSU interface
    if_lsu_adapter.slave  i_lsu_adapter,
    // Direct AXI interface (when USE_CACHE=0)
    if_lsu_adapter.master o_lsu_adapter
);
    assign o_lsu_adapter.rq = i_lsu_adapter.rq;
    assign o_lsu_adapter.wen = i_lsu_adapter.wen;
    assign o_lsu_adapter.ren = i_lsu_adapter.ren;
    assign o_lsu_adapter.addr = i_lsu_adapter.addr;
    assign o_lsu_adapter.wdata = i_lsu_adapter.wdata;
    assign o_lsu_adapter.wmask = i_lsu_adapter.wmask;
    assign o_lsu_adapter.read_t = i_lsu_adapter.read_t;
    assign i_lsu_adapter.rdata = o_lsu_adapter.rdata;
    assign i_lsu_adapter.valid = o_lsu_adapter.valid;

endmodule

