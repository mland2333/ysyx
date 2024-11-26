module ysyx_24110006_XBAR(
  input [31:0] i_axi_araddr,
  input i_axi_arvalid,
  output o_axi_arready,
  output [31:0] o_axi_rdata,
  output o_axi_rvalid,
  output [1:0] o_axi_rresp,
  input i_axi_rready,
  input [31:0] i_axi_awaddr,
  input i_axi_awvalid,
  output o_axi_awready,
  input [31:0] i_axi_wdata,
  input [7:0] i_axi_wstrb,
  input i_axi_wvalid,
  output o_axi_wready,
  output [1:0] o_axi_bresp,
  output o_axi_bvalid,
  input i_axi_bready,
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
//clint
  output [31:0] o_axi_araddr2,
  output o_axi_arvalid2,
  input i_axi_arready2,
  input [31:0] i_axi_rdata2,
  input i_axi_rvalid2,
  input [1:0] i_axi_rresp2,
  output o_axi_rready2
);

`define UART 32'ha00003f8
`define RTC_ADDR 32'ha0000048
`define RTC_ADDR_HIGH 32'ha000004c

wire is_write_uart = i_axi_awaddr == `UART;
wire is_read_rtc = i_axi_araddr == `RTC_ADDR || i_axi_araddr == `RTC_ADDR_HIGH;

assign o_axi_arready = is_read_rtc ? i_axi_arready2 : i_axi_arready0;
assign o_axi_rdata = is_read_rtc ? i_axi_rdata2 : i_axi_rdata0;
assign o_axi_rvalid = is_read_rtc ? i_axi_rvalid2 : i_axi_rvalid0;
assign o_axi_rresp = is_read_rtc ? i_axi_rresp2 : i_axi_rresp0;
assign o_axi_awready = is_write_uart ? i_axi_awready1 : i_axi_awready0;
assign o_axi_wready = is_write_uart ? i_axi_wready1 : i_axi_wready0;
assign o_axi_bvalid = is_write_uart ? i_axi_bvalid1 : i_axi_bvalid0;
assign o_axi_bresp = is_write_uart ? i_axi_bresp1 : i_axi_bresp0;

assign o_axi_araddr0 = is_read_rtc ? 0 : i_axi_araddr;
assign o_axi_arvalid0 = is_read_rtc ? 0 : i_axi_arvalid;
assign o_axi_rready0 = is_read_rtc ? 0 : i_axi_rready;
assign o_axi_awaddr0 = is_write_uart ? 0 : i_axi_awaddr;
assign o_axi_awvalid0 = is_write_uart ? 0 : i_axi_awvalid;
assign o_axi_wdata0 = is_write_uart ? 0 : i_axi_wdata;
assign o_axi_wstrb0 = is_write_uart ? 0 : i_axi_wstrb;
assign o_axi_wvalid0 = is_write_uart ? 0 : i_axi_wvalid;
assign o_axi_bready0 = is_write_uart ? 0 : i_axi_bready;

assign o_axi_awaddr1 = is_write_uart ? i_axi_awaddr : 0;
assign o_axi_awvalid1 = is_write_uart ? i_axi_awvalid : 0;
assign o_axi_wdata1 = is_write_uart ? i_axi_wdata : 0;
assign o_axi_wstrb1 = is_write_uart ? i_axi_wstrb : 0;
assign o_axi_wvalid1 = is_write_uart ? i_axi_wvalid : 0;
assign o_axi_bready1 = is_write_uart ? i_axi_bready : 0;

assign o_axi_araddr2 = is_read_rtc ? i_axi_araddr : 0;
assign o_axi_arvalid2 = is_read_rtc ? i_axi_arvalid : 0;
assign o_axi_rready2 = is_read_rtc ? i_axi_rready : 0;

endmodule
