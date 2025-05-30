module ysyx_24110006_ICACHE2AXI(
  input i_clock,
  input i_reset,
  if_mem_rq.slave i_icache_rq,
  if_axi_read.master o_axi_rq
);

always_ff@(posedge i_clock)begin
  if(i_reset) i_icache_rq.ack <= 0;
  else if(i_icache_rq.rq && !i_icache_rq.ack) i_icache_rq.ack <= 1;
  else if(i_icache_rq.ack) i_icache_rq.ack <= 0;
end
always_ff@(posedge i_clock)begin
  if(i_reset) i_icache_rq.valid <= 0;
  else if(rvalid && rready && rlast) i_icache_rq.valid <= 1;
  else if(i_icache_rq.valid && i_icache_rq.ready) i_icache_rq.valid <= 0;
end

localparam int BURST_LEN = `CACHE_LINE_WIDTH / 32;
localparam int ADDR_WIDTH = 32 - $clog2(BURST_LEN) - 2;
logic [`CACHE_LINE_WIDTH-1:0] r_cache_line;

always_ff@(posedge i_clock)begin
  if(o_axi_rq.rvalid && o_axi_rq.rready) r_cache_line[read_cache_index*32+:32] <= rdata;
end
assign i_icache_rq.r_cache_line = r_cache_line;

logic [BURST_LEN-1:0] read_cache_index;
always_ff@(posedge i_clock)begin
  if(i_reset || rlast) read_cache_index <= 0;
  else if(rvalid && rready) read_cache_index <= read_cache_index + 1;
end

logic arvalid, arready, rvalid, rready, rlast;
logic [1:0] rresp, bresp;

always_ff@(posedge i_clock)begin
  if(i_reset) arvalid <= 0;
  else if(i_icache_rq.rq && i_icache_rq.ack) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end

logic [31:0]araddr, rdata;
assign rready = 1;
assign araddr = {i_icache_rq.addr[31:32-ADDR_WIDTH], (32-ADDR_WIDTH)'(0)};
assign rdata = o_axi_rq.rdata;

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

endmodule
