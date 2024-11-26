module ysyx_24110006_CLINT(
  input i_clock,
  input i_reset,

  input [31:0] i_axi_araddr,
  input i_axi_arvalid,
  output o_axi_arready,

  output [31:0] o_axi_rdata,
  output o_axi_rvalid,
  output [1:0] o_axi_rresp,
  input i_axi_rready
);
reg [63:0] mtime;

wire [31:0] lmtime = mtime[31:0];
wire [31:0] hmtime = mtime[63:32];
always@(posedge i_clock)begin
 if(i_reset) mtime <= 0;
 else mtime <= mtime + 1;
end

reg [31:0] araddr;
reg arready;
reg [31:0] rdata;
reg rvalid;
reg [1:0] rresp;

// Read address channel
wire arvalid = i_axi_arvalid;
assign o_axi_arready = arready;
// Read data channel
assign o_axi_rdata = rdata;
assign o_axi_rvalid = rvalid;
assign o_axi_rresp = rresp;
wire rready = i_axi_rready;

always@(posedge i_clock)begin
  arready <= 1;
end

always@(posedge i_clock)begin
  if(i_reset) rdata <= 0;
  else if(arvalid && arready)begin
    rdata <= i_axi_araddr[2] ? hmtime : lmtime;
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
