module ysyx_24110006_UART(
  input i_clock,
  input i_reset,
  input [31:0] i_axi_awaddr,
  input i_axi_awvalid,
  output o_axi_awready,
  input [31:0] i_axi_wdata,
  input [7:0] i_axi_wstrb,
  input i_axi_wvalid,
  output o_axi_wready,
  output [1:0] o_axi_bresp,
  output o_axi_bvalid,
  input i_axi_bready
);

reg [31:0] awaddr;
reg awready;
reg [31:0] wdata;
reg wready;
reg [7:0] wstrb;
reg bvalid;
reg [1:0] bresp;

wire awvalid = i_axi_awvalid;
assign o_axi_awready = awready;
wire wvalid = i_axi_wvalid;
assign o_axi_wready = wready;
assign o_axi_bresp = bresp;
assign o_axi_bvalid = bvalid;
wire bready = i_axi_bready;

always@(posedge i_clock)begin
  awready <= 1;
end
always@(posedge i_clock)begin
  wready <= 1;
end

always@(posedge i_clock)begin
  if(awvalid && awready && wvalid && wready && !bvalid)begin
    $write("%c", i_axi_wdata[7:0]);
  end
end

always@(posedge i_clock)begin
  if(i_reset) bvalid <= 0;
  else if(awvalid && awready && wvalid && wready && !bvalid)begin
    bvalid <= 1;
  end
  else if(bvalid && bready) begin
    bvalid <= 0;
  end
end

endmodule
