module ysyx_24110006_LSU2AXI (
    input i_clock,
    input i_reset,

    // LSU adapter interface
    if_lsu_adapter.slave i_lsu_adapter,

    // AXI interface
    if_axi.master o_axi
);

  // Internal signals
  reg arvalid;
  wire arready;
  wire rvalid;
  reg rready;
  wire [1:0] rresp;
  reg awvalid;
  wire awready;
  reg wvalid;
  wire wready;
  wire [1:0] bresp;
  wire bvalid;
  reg bready;
  assign i_lsu_adapter.ack = 1;
  // Memory transaction completion
  assign i_lsu_adapter.valid = (i_lsu_adapter.ren && rvalid && rready) || (i_lsu_adapter.wen && bvalid && bready);

  // Pass raw data back to LSU for processing
  assign i_lsu_adapter.rdata = o_axi.rdata;

  // AXI read address channel
  always_ff @(posedge i_clock) begin
    if (i_reset) arvalid <= 0;
    else if (i_lsu_adapter.rq && i_lsu_adapter.ren && !arvalid) arvalid <= 1;
    else if (arvalid && arready) arvalid <= 0;
  end

  // AXI read data channel
  always_ff @(posedge i_clock) begin
    rready <= 1;  // Always ready to receive data
  end

  // AXI write address channel
  always_ff @(posedge i_clock) begin
    if (i_reset) awvalid <= 0;
    else if (i_lsu_adapter.rq && i_lsu_adapter.wen && !awvalid) awvalid <= 1;
    else if (awvalid && awready && wvalid && wready) awvalid <= 0;
  end

  // AXI write data channel
  always_ff @(posedge i_clock) begin
    if (i_reset) wvalid <= 0;
    else if (i_lsu_adapter.rq && i_lsu_adapter.wen && !wvalid) wvalid <= 1;
    else if (awvalid && awready && wvalid && wready) wvalid <= 0;
  end

  // AXI write response channel
  always_ff @(posedge i_clock) begin
    bready <= 1;  // Always ready to receive write response
  end

  // AXI interface connections
  // Read address channel
  assign o_axi.araddr = i_lsu_adapter.addr;
  assign o_axi.arvalid = arvalid;
  assign arready = o_axi.arready;
  assign o_axi.arid = 0;
  assign o_axi.arlen = 0;  // Single transfer
  assign o_axi.arsize = i_lsu_adapter.read_t[1] ? 3'b010 : i_lsu_adapter.read_t[0] ? 3'b001 : 3'b000; // Size based on read type
  assign o_axi.arburst = 0;  // Fixed burst type

  // Read data channel
  assign rvalid = o_axi.rvalid;
  assign rresp = o_axi.rresp;
  assign o_axi.rready = rready;

  // Write address channel
  assign o_axi.awaddr = i_lsu_adapter.addr;
  assign o_axi.awvalid = awvalid;
  assign awready = o_axi.awready;
  assign o_axi.awid = 0;
  assign o_axi.awlen = 0;  // Single transfer
  assign o_axi.awsize = i_lsu_adapter.wmask == 4'b0011 ? 3'b001 : i_lsu_adapter.wmask == 4'b1111 ? 3'b010 : 3'b000; // Size based on write mask
  assign o_axi.awburst = 0;  // Fixed burst type

  // Write data channel
  assign o_axi.wdata = i_lsu_adapter.wdata;
  assign o_axi.wstrb = i_lsu_adapter.wmask;
  assign o_axi.wvalid = wvalid;
  assign wready = o_axi.wready;
  assign o_axi.wlast = 1;  // Always last for single transfer

  // Write response channel
  assign bresp = o_axi.bresp;
  assign bvalid = o_axi.bvalid;
  assign o_axi.bready = bready;

endmodule

