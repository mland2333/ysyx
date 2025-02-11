module ysyx_24110006_CLINT(
  input i_clock,
  input i_reset,
  if_axi_read.slave in
);
reg [31:0] lmtime;
reg [31:0] hmtime;

/* wire [31:0] lmtime = mtime[31:0]; */
/* wire [31:0] hmtime = mtime[63:32]; */
wire is_full = &lmtime;
always@(posedge i_clock)begin
  if(i_reset) lmtime <= 0;
  else if(is_full) lmtime <= 0;
  else lmtime <= lmtime + 1;
end

always@(posedge i_clock)begin
  if(is_full) hmtime <= 0;
  else if(&lmtime) hmtime <= hmtime + 1;
end

reg [31:0] araddr;
reg arready;
reg [31:0] rdata;
reg rvalid;
reg [1:0] rresp;

// Read address channel
wire arvalid = in.arvalid;
assign in.arready = arready;
// Read data channel
assign in.rdata = rdata;
assign in.rvalid = rvalid;
assign in.rresp = rresp;
wire rready = in.rready;

always@(posedge i_clock)begin
  arready <= 1;
end

always@(posedge i_clock)begin
  if(i_reset) rdata <= 0;
  else if(arvalid && arready)begin
    rdata <= in.araddr[2] ? hmtime : lmtime;
  end
end
//rvalid
always@(posedge i_clock)begin
  if(i_reset) rvalid <= 0;
  else if(arvalid && arready && !rvalid)begin
    rvalid <= 1;
  end
  else if(rvalid && rready) begin
    rvalid <= 0;
  end
end

endmodule
