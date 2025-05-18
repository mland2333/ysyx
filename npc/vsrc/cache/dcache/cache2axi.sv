module ysyx_24110006_CACHE2AXI(
  input i_clock,
  input i_reset,
  //cache <--> axi
  if_dcache_axi.slave i_dcache_rq,
  //axi <--> mem
  if_axi.master o_axi_rq
);

always_ff@(posedge i_clock)begin
  if(i_reset) i_dcache_rq.ack <= 0;
  else if(i_dcache_rq.rq && !i_dcache_rq.ack) i_dcache_rq.ack <= 1;
  else if(i_dcache_rq.ack) i_dcache_rq.ack <= 0;
end
always_ff@(posedge i_clock)begin
  if(i_reset) i_dcache_rq.valid <= 0;
  else if(rvalid && rready && rlast || bvalid && bready) i_dcache_rq.valid <= 1;
  else if(i_dcache_rq.valid && i_dcache_rq.ready) i_dcache_rq.valid <= 0;
end

logic [`CACHE_LINE_WIDTH-1:0] w_cache_line;
logic [`CACHE_LINE_WIDTH-1:0] r_cache_line;
always_ff@(posedge i_clock)begin
  if(i_dcache_rq.rq && i_dcache_rq.wen) w_cache_line <= i_dcache_rq.w_cache_line;
end
always_ff@(posedge i_clock)begin
  if(o_axi_rq.rvalid && o_axi_rq.rready) r_cache_line[read_cache_index*32+:32] <= rdata;
end
assign i_dcache_rq.r_cache_line = r_cache_line;

always_ff@(posedge i_clock)begin
  if(i_reset) arvalid <= 0;
  else if(i_dcache_rq.rq && i_dcache_rq.ack && !i_dcache_rq.wen) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end

always_ff@(posedge i_clock)begin
  if(i_reset) awvalid <= 0;
  else if(i_dcache_rq.rq && i_dcache_rq.ack && i_dcache_rq.wen) awvalid <= 1;
  else if(awvalid && awready) awvalid <= 0;
end

always_ff@(posedge i_clock)begin
  if(i_reset) wvalid <= 0;
  else if(i_dcache_rq.rq && i_dcache_rq.ack && i_dcache_rq.wen) wvalid <= 1;
  else if(wlast && wvalid && wready) wvalid <= 0;
end
assign wdata = w_cache_line[write_cache_index*32+:32];
localparam int BURST_LEN = `CACHE_LINE_WIDTH / 32;
localparam int ADDR_WIDTH = 32 - $clog2(BURST_LEN) - 2;
logic [BURST_LEN-1:0] read_cache_index, write_cache_index;
always_ff@(posedge i_clock)begin
  if(i_reset || rlast) read_cache_index <= 0;
  else if(rvalid && rready) read_cache_index <= read_cache_index + 1;
end
always_ff@(posedge i_clock)begin
  if(i_reset || (wlast && wvalid && wready)) write_cache_index <= 0;
  else if(wvalid && wready) write_cache_index <= write_cache_index + 1;
end


logic arvalid, arready, rvalid, rready, rlast;
logic awvalid, wvalid, awready, wready, wlast, bvalid, bready;
logic [1:0] rresp, bresp;
logic [3:0] wstrb;
logic [31:0] awaddr, araddr, wdata, rdata;

assign rready = 1;
assign bready = 1;
assign wstrb = 4'b1111;
assign awaddr = {i_dcache_rq.addr[31:32-ADDR_WIDTH], (32-ADDR_WIDTH)'(0)};
assign araddr = {i_dcache_rq.addr[31:32-ADDR_WIDTH], (32-ADDR_WIDTH)'(0)};
assign rdata = o_axi_rq.rdata;
assign wlast = write_cache_index == BURST_LEN-1;

assign o_axi_rq.araddr = araddr;
assign o_axi_rq.arvalid = arvalid;
assign arready = o_axi_rq.arready;
assign o_axi_rq.arid = 0;
assign o_axi_rq.arlen = 8'(BURST_LEN-1);
assign o_axi_rq.arsize = 3'b010;
assign o_axi_rq.arburst = 2'b01;

assign rvalid = o_axi_rq.rvalid;
assign rresp = o_axi_rq.rresp;
assign o_axi_rq.rready = rready;
assign rlast = o_axi_rq.rlast;

assign o_axi_rq.awaddr = awaddr;
assign o_axi_rq.awvalid = awvalid;
assign o_axi_rq.wvalid = wvalid;
assign awready = o_axi_rq.awready;
assign wready = o_axi_rq.wready;
assign o_axi_rq.wdata = wdata;
assign o_axi_rq.wlast = wlast;
assign o_axi_rq.wstrb = wstrb;
assign o_axi_rq.awid = 0;
assign o_axi_rq.awlen = 8'(BURST_LEN-1);
assign o_axi_rq.awsize = 3'b010;
assign o_axi_rq.awburst = 2'b01;

assign o_axi_rq.bready = bready;
assign bvalid = o_axi_rq.bvalid;
assign bresp = o_axi_rq.bresp;

endmodule
