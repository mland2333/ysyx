module ysyx_24110006(
  input clock,
`ifdef CONFIG_YSYXSOC
  input         io_interrupt,
  input         io_master_awready,
  output        io_master_awvalid,
  output [31:0] io_master_awaddr,
  output [3:0]  io_master_awid,
  output [7:0]  io_master_awlen,
  output [2:0]  io_master_awsize,
  output [1:0]  io_master_awburst,
  input         io_master_wready,
  output        io_master_wvalid,
  output [31:0] io_master_wdata,
  output [3:0]  io_master_wstrb,
  output        io_master_wlast,
  output        io_master_bready,
  input         io_master_bvalid,
  input  [1:0]  io_master_bresp,
  input  [3:0]  io_master_bid,
  input         io_master_arready,
  output        io_master_arvalid,
  output [31:0] io_master_araddr,
  output [3:0]  io_master_arid,
  output [7:0]  io_master_arlen,
  output [2:0]  io_master_arsize,
  output [1:0]  io_master_arburst,
  output        io_master_rready,
  input         io_master_rvalid,
  input  [1:0]  io_master_rresp,
  input  [31:0] io_master_rdata,
  input         io_master_rlast,
  input  [3:0]  io_master_rid,

  output        io_slave_awready,
  input         io_slave_awvalid,
  input  [31:0] io_slave_awaddr,
  input  [3:0]  io_slave_awid,
  input  [7:0]  io_slave_awlen,
  input  [2:0]  io_slave_awsize,
  input  [1:0]  io_slave_awburst,
  output        io_slave_wready,
  input         io_slave_wvalid,
  input  [31:0] io_slave_wdata,
  input  [3:0]  io_slave_wstrb,
  input         io_slave_wlast,
  input         io_slave_bready,
  output        io_slave_bvalid,
  output [1:0]  io_slave_bresp,
  output [3:0]  io_slave_bid,
  output        io_slave_arready,
  input         io_slave_arvalid,
  input  [31:0] io_slave_araddr,
  input  [3:0]  io_slave_arid,
  input  [7:0]  io_slave_arlen,
  input  [2:0]  io_slave_arsize,
  input  [1:0]  io_slave_arburst,
  input         io_slave_rready,
  output        io_slave_rvalid,
  output [1:0]  io_slave_rresp,
  output [31:0] io_slave_rdata,
  output        io_slave_rlast,
  output [3:0]  io_slave_rid,
`endif
  input reset
);
 if_axi master ();
 if_axi slave ();
ysyx_24110006_top top(
  .clock(clock),
`ifdef CONFIG_YSYXSOC
  .master(master)
`endif
  .reset(reset)
);
`ifdef CONFIG_YSYXSOC
  assign io_master_awvalid = master.awvalid;
  assign io_master_awaddr  = master.awaddr;
  assign io_master_awid    = master.awid;
  assign io_master_awlen   = master.awlen;
  assign io_master_awsize  = master.awsize;
  assign io_master_awburst = master.awburst;
  assign master.awready   = io_master_awready;
  assign io_master_wvalid  = master.wvalid;
  assign io_master_wdata   = master.wdata;
  assign io_master_wstrb   = master.wstrb;
  assign io_master_wlast   = master.wlast;
  assign master.wready    = io_master_wready;
  assign io_master_bready  = master.bready;
  assign master.bvalid    = io_master_bvalid;
  assign master.bresp     = io_master_bresp;
  assign master.bid       = io_master_bid;
  assign io_master_arvalid = master.arvalid;
  assign io_master_araddr  = master.araddr;
  assign io_master_arid    = master.arid;
  assign io_master_arlen   = master.arlen;
  assign io_master_arsize  = master.arsize;
  assign io_master_arburst = master.arburst;
  assign master.arready   = io_master_arready;
  assign io_master_rready  = master.rready;
  assign master.rvalid    = io_master_rvalid;
  assign master.rresp     = io_master_rresp;
  assign master.rdata     = io_master_rdata;
  assign master.rlast     = io_master_rlast;
  assign master.rid       = io_master_rid;
`endif



endmodule
