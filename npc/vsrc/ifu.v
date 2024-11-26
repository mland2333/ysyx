/* import "DPI-C" function int inst_fetch(input int addr); */
module ysyx_24110006_IFU(
  input i_clock,
  input i_reset,
  input [31:0] i_pc,
  output reg [31:0] o_inst,

  input i_valid,
  output reg o_valid,
  
  output [31:0] o_axi_araddr,
  output o_axi_arvalid,
  input i_axi_arready,
  input [31:0] i_axi_rdata,
  input i_axi_rvalid,
  output o_axi_rready,
  input [1:0] i_axi_rresp
);

reg [31:0] pc;
reg [31:0] inst;

assign o_inst = inst;

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
  if(i_reset) inst <= 0;
  else if(rvalid && !o_valid) inst <= i_axi_rdata;
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

assign o_axi_araddr = pc;
assign o_axi_arvalid = arvalid;
assign arready = i_axi_arready;

assign rvalid = i_axi_rvalid;
assign rresp = i_axi_rresp;
assign o_axi_rready = rready;


always@(posedge i_clock) begin
  if(i_reset) arvalid <= 0;
  else if(i_valid && !arvalid) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end

endmodule
