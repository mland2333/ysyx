module ysyx_24110006_XBAR(
  input i_clock,
  input i_reset,
  
  if_axi.slave in,
  if_axi.master mem,
`ifndef CONFIG_YSYXSOC
  if_axi_write.master uart,
`endif
  if_axi_read.master clint
);

/* `define UART 32'ha00003f8 */
`ifdef CONFIG_YSYXSOC
  `define RTC_ADDR 32'h02000000
  `define RTC_ADDR_HIGH 32'h02000004
`endif

`ifndef CONFIG_YSYXSOC
  `define UART_ADDR 32'ha00003f8
  `define RTC_ADDR 32'ha0000048
  `define RTC_ADDR_HIGH 32'ha000004c
  wire is_write_uart = in.awaddr == `UART_ADDR;
`endif
/* wire is_write_uart = in.awaddr == `UART; */
wire is_read_clint = in.araddr == `RTC_ADDR || in.araddr == `RTC_ADDR_HIGH;
reg r_is_read_clint;

always@(posedge i_clock)begin
  if(i_reset) r_is_read_clint <= 0;
  else if(in.arvalid)begin
    r_is_read_clint <= is_read_clint;
  end
  else if(r_is_read_clint && in.rvalid)
    r_is_read_clint <= 0;
end

assign in.arready = r_is_read_clint ? clint.arready : mem.arready;
assign in.rdata = r_is_read_clint ? clint.rdata : mem.rdata;
assign in.rvalid = r_is_read_clint ? clint.rvalid : mem.rvalid;
assign in.rresp = r_is_read_clint ? clint.rresp : mem.rresp;
assign in.rid = r_is_read_clint ? 0 : mem.rid;
assign in.rlast = r_is_read_clint ? 0 : mem.rlast;

assign mem.araddr = is_read_clint ? 0 : in.araddr;
assign mem.arvalid = is_read_clint ? 0 : in.arvalid;
assign mem.arid = is_read_clint ? 0 : in.arid; 
assign mem.arlen = is_read_clint ? 0 : in.arlen;
assign mem.arsize = is_read_clint ? 0 : in.arsize;
assign mem.arburst = is_read_clint ? 0 : in.arburst;
assign mem.rready = is_read_clint ? 0 : in.rready;

assign clint.araddr = is_read_clint ? in.araddr : 0;
assign clint.arvalid = is_read_clint ? in.arvalid : 0;
assign clint.rready = is_read_clint ? in.rready : 0;

`ifdef CONFIG_YSYXSOC
assign mem.awaddr = in.awaddr;
assign mem.awvalid = in.awvalid;
assign mem.awid = in.awid;
assign mem.awlen = in.awlen;
assign mem.awsize = in.awsize;
assign mem.awburst = in.awburst;
assign mem.wdata = in.wdata;
assign mem.wstrb = in.wstrb;
assign mem.wlast = in.wlast;
assign mem.wvalid = in.wvalid;
assign mem.bready = in.bready;

assign in.awready = mem.awready;
assign in.wready = mem.wready;
assign in.bvalid = mem.bvalid;
assign in.bresp = mem.bresp;
assign in.bid = mem.bid;
`endif

`ifndef CONFIG_YSYXSOC
assign in.awready = is_write_uart ? uart.awready : mem.awready;
assign in.wready = is_write_uart ? uart.wready : mem.wready;
assign in.bvalid = is_write_uart ? uart.bvalid : mem.bvalid;
assign in.bresp = is_write_uart ? uart.bresp : mem.bresp;
assign in.bid = is_write_uart ? uart.bid : mem.bid ;

assign mem.awaddr = is_write_uart ? 0 : in.awaddr;
assign mem.awvalid = is_write_uart ? 0 : in.awvalid;
assign mem.awid = is_write_uart ? 0 : in.awid;
assign mem.awlen = is_write_uart ? 0 : in.awlen;
assign mem.awsize = is_write_uart ? 0 : in.awsize;
assign mem.awburst = is_write_uart ? 0 : in.awburst;
assign mem.wdata = is_write_uart ? 0 : in.wdata;
assign mem.wstrb = is_write_uart ? 0 : in.wstrb;
assign mem.wlast = is_write_uart ? 0 : in.wlast;
assign mem.wvalid = is_write_uart ? 0 : in.wvalid;
assign mem.bready = is_write_uart ? 0 : in.bready;

assign uart.awaddr = is_write_uart ? in.awaddr : 0;
assign uart.awvalid = is_write_uart ? in.awvalid : 0;
assign uart.awid = is_write_uart ? in.awid : 0;
assign uart.awlen = is_write_uart ? in.awlen : 0;
assign uart.awsize = is_write_uart ? in.awsize : 0;
assign uart.awburst = is_write_uart ? in.awburst : 0;
assign uart.wdata = is_write_uart ? in.wdata : 0;
assign uart.wstrb = is_write_uart ? in.wstrb : 0;
assign uart.wlast = is_write_uart ? in.wlast : 0;
assign uart.wvalid = is_write_uart ? in.wvalid : 0;
assign uart.bready = is_write_uart ? in.bready : 0;

`endif


endmodule
