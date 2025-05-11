module ysyx_24110006_CACHE2AXI(
  input i_clock,
  input i_reset,
  //cache <--> axi
  input i_rq_mem,
  input i_wen_mem,
  output logic o_rq_ack,
  input [31:0] i_addr,
  output logic [31:0] o_rdata_mem,
  output logic o_rdata_valid,
  input i_rdata_ready,
  output logic o_fin_r,
  input [31:0] i_wdata_mem,
  input i_wdata_valid,
  output logic o_wdata_ready,
  output logic o_fin_w,
  input i_wlast,
  //axi <--> mem
  if_axi.master o_axi
);
assign o_rdata_mem = o_axi.rdata;
assign o_rdata_valid = o_axi.rvalid;
assign o_fin_r = o_axi.rlast;
assign o_fin_w = o_axi.bvalid;
always_ff@(posedge i_clock)begin
  if(i_reset) arvalid <= 0;
  else if(i_rq_mem && !i_wen_mem) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end
always_ff@(posedge i_clock)begin
  if(i_reset) awvalid <= 0;
  else if(i_rq_mem && i_wen_mem) awvalid <= 1;
  else if(awvalid && awready) awvalid <= 0;
end
always_ff@(posedge i_clock)begin
  if(i_reset) wvalid <= 0;
  else if(i_rq_mem && i_wen_mem) wvalid <= 1;
  else if(wvalid && wready) wvalid <= 0;
end

always_ff@(posedge i_clock)begin
  if(i_reset) o_rq_ack <= 0;
  else if(arvalid && arready || awvalid && awready) o_rq_ack <= 1;
  else if(o_rq_ack) o_rq_ack <= 0;
end

logic arvalid, arready, rvalid, rready, rlast;
logic awvalid, wvalid, awready, wready, wlast, bvalid, bready;
logic [1:0] rresp, bresp;
logic [3:0] wstrb;
logic [31:0] awaddr, araddr;
assign rready = 1;
assign bready = 1;
assign axi_wdata = i_wdata_mem;
assign wlast = i_wlast;
assign wstrb = 4'b1111;
assign awaddr = i_addr;
assign araddr = i_addr;

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
