module ysyx_24110006_LSU_ARIBITER (
    input i_clock,
    input i_reset,
    if_rq_load.in rq_load,
    if_rq_store.in rq_store,
    if_lsu_dcache.master rq_dcache,
    if_lsu_adapter.master rq_axi
);

  typedef enum logic [1:0] {
    idle,
    load,
    store
  } state_t;
  state_t state;
  logic rq, ren, wen, ready, valid, ack;
  logic [31:0] addr, wdata, rdata;
  logic [3:0] wmask;
  logic [2:0] read_t;
  always_ff @(posedge i_clock) begin
    if (i_reset) state <= idle;
    else begin
      case (state)
        idle: begin
          if (rq_load.rq) state <= load;
          else if (rq_store.rq) state <= store;
        end
        load: begin
          if (rq_load.valid) state <= idle;
        end
        store: begin
          if (rq_store.valid) state <= idle;
        end
        default: state <= idle;
      endcase
    end
  end
  assign rq = state == load ? rq_load.rq : state == store ? rq_store.rq : 0;
  assign ren = state == load ? 1 : 0;
  assign wen = state == store ? 1 : 0;
  assign ready = state == load ? rq_load.ready : state == store ? rq_store.ready : 0;
  assign addr = state == load ? rq_load.addr : state == store ? rq_store.addr : 0;
  assign wdata = state == store ? rq_store.wdata : 0;
  assign wmask = state == store ? rq_store.wmask : 0;
  assign read_t = state == load ? rq_load.read_t : 0;

  logic in_dcache;
`ifdef CONFIG_YSYXSOC
  assign in_dcache = addr[31]==1 || addr[29:28]==2'b11 || addr[31:24]==8'h0f;
`else
  assign in_dcache = addr[31:28] == 4'b1000;
`endif
  assign rq_dcache.rq = in_dcache ? rq : 0;
  assign rq_dcache.ren = in_dcache ? ren : 0;
  assign rq_dcache.wen = in_dcache ? wen : 0;
  assign rq_dcache.addr = in_dcache ? addr : 0;
  assign rq_dcache.wdata = in_dcache ? wdata : 0;
  assign rq_dcache.wmask = in_dcache ? wmask : 0;
  assign rq_dcache.ready = in_dcache ? ready : 0;

  assign rq_axi.rq = !in_dcache ? rq : 0;
  assign rq_axi.wen = !in_dcache ? wen : 0;
  assign rq_axi.ren = !in_dcache ? ren : 0;
  assign rq_axi.addr = !in_dcache ? addr : 0;
  assign rq_axi.wdata = !in_dcache ? wdata : 0;
  assign rq_axi.wmask = !in_dcache ? wmask : 0;
  assign rq_axi.read_t = !in_dcache ? read_t : 0;
  assign rq_axi.ready = !in_dcache ? ready : 0;

  assign rdata = in_dcache ? rq_dcache.rdata : rq_axi.rdata;
  assign valid = in_dcache ? rq_dcache.valid : rq_axi.valid;
  assign ack = in_dcache ? rq_dcache.ack : rq_axi.ack;

  assign rq_load.rdata = state == load ? rdata : 0;
  assign rq_load.valid = state == load ? valid : 0;
  assign rq_load.ack = state == load ? ack : 0;
  assign rq_store.valid = state == store ? valid : 0;
  assign rq_store.ack = state == store ? ack : 0;
endmodule
