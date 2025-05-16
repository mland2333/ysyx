module ysyx_24110006_CACHE2AXI(
  input i_clock,
  input i_reset,
  //cache <--> axi
  if_dcache_axi.slave i_dcache,
  //axi <--> mem
  if_axi.master o_axi
);

assign i_dcache.rdata_mem = o_axi.rdata;
assign i_dcache.rdata_valid = o_axi.rvalid;
assign i_dcache.fin_r = o_axi.rlast;
assign i_dcache.fin_w = o_axi.bvalid;

always_ff@(posedge i_clock)begin
  if(i_reset) arvalid <= 0;
  else if(i_dcache.rq_mem && !i_dcache.wen_mem) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end

always_ff@(posedge i_clock)begin
  if(i_reset) awvalid <= 0;
  else if(i_dcache.rq_mem && i_dcache.wen_mem) awvalid <= 1;
  else if(awvalid && awready) awvalid <= 0;
end

always_ff@(posedge i_clock)begin
  if(i_reset) wvalid <= 0;
  else if(i_dcache.rq_mem && i_dcache.wen_mem) wvalid <= 1;
  else if(wvalid && wready) wvalid <= 0;
end

always_ff@(posedge i_clock)begin
  if(i_reset) i_dcache.rq_ack <= 0;
  else if(arvalid && arready || awvalid && awready) i_dcache.rq_ack <= 1;
  else if(i_dcache.rq_ack) i_dcache.rq_ack <= 0;
end

logic arvalid, arready, rvalid, rready, rlast;
logic awvalid, wvalid, awready, wready, wlast, bvalid, bready;
logic [1:0] rresp, bresp;
logic [3:0] wstrb;
logic [31:0] awaddr, araddr, axi_wdata;

assign rready = 1;
assign bready = 1;
assign axi_wdata = i_dcache.wdata_mem;
assign wlast = i_dcache.wlast;
assign wstrb = 4'b1111;
assign awaddr = i_dcache.addr;
assign araddr = i_dcache.addr;
assign i_dcache.wdata_ready = wready;

assign o_axi.araddr = araddr;
assign o_axi.arvalid = arvalid;
assign arready = o_axi.arready;
assign o_axi.arid = 0;
assign o_axi.arlen = 8'(BURST_LEN-1);
assign o_axi.arsize = 3'b010;
assign o_axi.arburst = 2'b10;

assign rvalid = o_axi.rvalid;
assign rresp = o_axi.rresp;
assign o_axi.rready = rready;
assign rlast = o_axi.rlast;

assign o_axi.awaddr = awaddr;
assign o_axi.awvalid = awvalid;
assign o_axi.wvalid = wvalid;
assign awready = o_axi.awready;
assign wready = o_axi.wready;
assign o_axi.wdata = axi_wdata;
assign o_axi.wlast = wlast;
assign o_axi.wstrb = wstrb;
assign o_axi.awid = 0;
assign o_axi.awlen = 8'(BURST_LEN-1);
assign o_axi.awsize = 3'b010;
assign o_axi.awburst = 2'b10;

assign o_axi.bready = bready;
assign bvalid = o_axi.bvalid;
assign bresp = o_axi.bresp;

endmodule
