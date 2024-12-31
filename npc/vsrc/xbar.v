module ysyx_24110006_XBAR(
  input [31:0] i_axi_araddr,
  input i_axi_arvalid,
  output o_axi_arready,
  input [3:0] i_axi_arid,
  input [7:0] i_axi_arlen,
  input [2:0] i_axi_arsize,
  input [1:0] i_axi_arburst,
  output [31:0] o_axi_rdata,
  output o_axi_rvalid,
  output [1:0] o_axi_rresp,
  input i_axi_rready,
  output [3:0] o_axi_rid,
  output o_axi_rlast,
  input [31:0] i_axi_awaddr,
  input i_axi_awvalid,
  output o_axi_awready,
  input [3:0] i_axi_awid,
  input [7:0] i_axi_awlen,
  input [2:0] i_axi_awsize,
  input [1:0] i_axi_awburst,
  input [31:0] i_axi_wdata,
  input [3:0] i_axi_wstrb,
  input i_axi_wvalid,
  output o_axi_wready,
  input i_axi_wlast,
  output [1:0] o_axi_bresp,
  output o_axi_bvalid,
  input i_axi_bready,
  output [3:0] o_axi_bid,

  output [31:0] o_axi_araddr0,
  output o_axi_arvalid0,
  input i_axi_arready0,
  output [3:0] o_axi_arid0,
  output [7:0] o_axi_arlen0,
  output [2:0] o_axi_arsize0,
  output [1:0] o_axi_arburst0,
  input [31:0] i_axi_rdata0,
  input i_axi_rvalid0,
  input [1:0] i_axi_rresp0,
  output o_axi_rready0,
  input [3:0] i_axi_rid0,
  input i_axi_rlast0,
  output [31:0] o_axi_awaddr0,
  output o_axi_awvalid0,
  input i_axi_awready0,
  output [3:0] o_axi_awid0,
  output [7:0] o_axi_awlen0,
  output [2:0] o_axi_awsize0,
  output [1:0] o_axi_awburst0,
  output [31:0] o_axi_wdata0,
  output [3:0] o_axi_wstrb0,
  output o_axi_wvalid0,
  input i_axi_wready0,
  output o_axi_wlast0,
  input [1:0] i_axi_bresp0,
  input i_axi_bvalid0,
  output o_axi_bready0,
  input [3:0] i_axi_bid0,
  /*
  //sram
  output [31:0] o_axi_araddr0,
  output o_axi_arvalid0,
  input i_axi_arready0,
  input [31:0] i_axi_rdata0,
  input i_axi_rvalid0,
  input [1:0] i_axi_rresp0,
  output o_axi_rready0,
  output [31:0] o_axi_awaddr0,
  output o_axi_awvalid0,
  input i_axi_awready0,
  output [31:0] o_axi_wdata0,
  output [7:0] o_axi_wstrb0,
  output o_axi_wvalid0,
  input i_axi_wready0,
  input [1:0] i_axi_bresp0,
  input i_axi_bvalid0,
  output o_axi_bready0,
//uart
  output [31:0] o_axi_awaddr1,
  output o_axi_awvalid1,
  input i_axi_awready1,
  output [31:0] o_axi_wdata1,
  output [7:0] o_axi_wstrb1,
  output o_axi_wvalid1,
  input i_axi_wready1,
  input [1:0] i_axi_bresp1,
  input i_axi_bvalid1,
  output o_axi_bready1,
  */
//clint
  output [31:0] o_axi_araddr2,
  output o_axi_arvalid2,
  input i_axi_arready2,
  input [31:0] i_axi_rdata2,
  input i_axi_rvalid2,
  input [1:0] i_axi_rresp2,
  output o_axi_rready2
);

/* `define UART 32'ha00003f8 */
`define RTC_ADDR 32'h02000000
`define RTC_ADDR_HIGH 32'h02000004

/* wire is_write_uart = i_axi_awaddr == `UART; */
wire is_read_rtc = i_axi_araddr == `RTC_ADDR || i_axi_araddr == `RTC_ADDR_HIGH;

assign o_axi_arready = is_read_rtc ? i_axi_arready2 : i_axi_arready0;
assign o_axi_rdata = is_read_rtc ? i_axi_rdata2 : i_axi_rdata0;
assign o_axi_rvalid = is_read_rtc ? i_axi_rvalid2 : i_axi_rvalid0;
assign o_axi_rresp = is_read_rtc ? i_axi_rresp2 : i_axi_rresp0;
assign o_axi_rid = is_read_rtc ? 0 : i_axi_rid0;
assign o_axi_rlast = is_read_rtc ? 0 : i_axi_rlast0;

assign o_axi_awready = i_axi_awready0;
assign o_axi_wready = i_axi_wready0;
assign o_axi_bvalid = i_axi_bvalid0;
assign o_axi_bresp = i_axi_bresp0;
assign o_axi_bid = i_axi_bid0;
/* assign o_axi_awready = is_write_uart ? i_axi_awready1 : i_axi_awready0; */
/* assign o_axi_wready = is_write_uart ? i_axi_wready1 : i_axi_wready0; */
/* assign o_axi_bvalid = is_write_uart ? i_axi_bvalid1 : i_axi_bvalid0; */
/* assign o_axi_bresp = is_write_uart ? i_axi_bresp1 : i_axi_bresp0; */

assign o_axi_araddr0 = is_read_rtc ? 0 : i_axi_araddr;
assign o_axi_arvalid0 = is_read_rtc ? 0 : i_axi_arvalid;
assign o_axi_arid0 = is_read_rtc ? 0 : i_axi_arid; 
assign o_axi_arlen0 = is_read_rtc ? 0 : i_axi_arlen;
assign o_axi_arsize0 = is_read_rtc ? 0 : i_axi_arsize;
assign o_axi_arburst0 = is_read_rtc ? 0 : i_axi_arburst;
assign o_axi_rready0 = is_read_rtc ? 0 : i_axi_rready;

assign o_axi_awaddr0 = i_axi_awaddr;
assign o_axi_awvalid0 = i_axi_awvalid;
assign o_axi_awid0 = i_axi_awid;
assign o_axi_awlen0 = i_axi_awlen;
assign o_axi_awsize0 = i_axi_awsize;
assign o_axi_awburst0 = i_axi_awburst;
assign o_axi_wdata0 = i_axi_wdata;
assign o_axi_wstrb0 = i_axi_wstrb;
assign o_axi_wlast0 = i_axi_wlast;
assign o_axi_wvalid0 = i_axi_wvalid;
assign o_axi_bready0 = i_axi_bready;
/* assign o_axi_awaddr0 = is_write_uart ? 0 : i_axi_awaddr; */
/* assign o_axi_awvalid0 = is_write_uart ? 0 : i_axi_awvalid; */
/* assign o_axi_wdata0 = is_write_uart ? 0 : i_axi_wdata; */
/* assign o_axi_wstrb0 = is_write_uart ? 0 : i_axi_wstrb; */
/* assign o_axi_wvalid0 = is_write_uart ? 0 : i_axi_wvalid; */
/* assign o_axi_bready0 = is_write_uart ? 0 : i_axi_bready; */

/* assign o_axi_awaddr1 = is_write_uart ? i_axi_awaddr : 0; */
/* assign o_axi_awvalid1 = is_write_uart ? i_axi_awvalid : 0; */
/* assign o_axi_wdata1 = is_write_uart ? i_axi_wdata : 0; */
/* assign o_axi_wstrb1 = is_write_uart ? i_axi_wstrb : 0; */
/* assign o_axi_wvalid1 = is_write_uart ? i_axi_wvalid : 0; */
/* assign o_axi_bready1 = is_write_uart ? i_axi_bready : 0; */

assign o_axi_araddr2 = is_read_rtc ? i_axi_araddr : 0;
assign o_axi_arvalid2 = is_read_rtc ? i_axi_arvalid : 0;
assign o_axi_rready2 = is_read_rtc ? i_axi_rready : 0;

endmodule
