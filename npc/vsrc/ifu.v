/* import "DPI-C" function int inst_fetch(input int addr); */
module ysyx_24110006_IFU(
  input i_clock,
  input i_reset,
  input [31:0] i_pc,
  output reg [31:0] o_inst,

  input i_valid,
  output reg o_valid
);

reg [31:0] pc;
always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(rvalid && !o_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    pc <= i_pc;
end
/* always@(posedge i_clock)begin */
/*   if(!i_reset && !o_valid && i_valid) */
/*     o_inst <= inst_fetch(i_pc); */
/* end */

reg arvalid;
wire arready;

wire rvalid;
wire rready = 1;
wire [1:0] rresp;

always@(posedge i_clock) begin
  if(i_reset) arvalid <= 0;
  else if(i_valid && !arvalid) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end

ysyx_24110006_SRAM msram(
  .i_clock(i_clock),
  .i_reset(i_reset),
  .i_axi_araddr(pc),
  .i_axi_arvalid(arvalid),
  .o_axi_arready(arready),

  .o_axi_rdata(o_inst),
  .o_axi_rvalid(rvalid),
  .o_axi_rresp(rresp),
  .i_axi_rready(rready),

  .i_axi_awaddr(0),
  .i_axi_awvalid(0),
  .o_axi_awready(),

  .i_axi_wdata(0),
  .i_axi_wstrb(0),
  .i_axi_wvalid(0),
  .o_axi_wready(),

  .o_axi_bresp(),
  .o_axi_bvalid(),
  .i_axi_bready(0)
);

endmodule
