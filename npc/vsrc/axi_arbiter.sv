module ysyx_24110006_ARBITER(
  input i_clock,
  input i_reset,
  input i_flush,
  output o_busy,
  if_axi_read.slave ifu,
  if_axi.slave lsu,
  if_axi.master out
);
localparam IDLE_READ = 2'b00;
localparam MEM0_READ = 2'b01;
localparam MEM1_READ = 2'b10;
localparam IDLE_WRITE = 2'b00;
localparam MEM1_WRITE = 2'b01;
reg [1:0] read_state;
reg [1:0] write_state;
reg arready;
assign o_busy = read_state == MEM0_READ;

always@(posedge i_clock)begin
  if(i_reset) read_state <= IDLE_READ;
  else begin
    case(read_state)
      IDLE_READ:begin
        if(ifu.arvalid && !i_flush) read_state <= MEM0_READ;
        else if(lsu.arvalid) read_state <= MEM1_READ;
      end
      MEM0_READ:begin
        if(out.rlast && out.rvalid && out.rready) read_state <= IDLE_READ;
      end
      MEM1_READ:begin
        if(out.rvalid && out.rready) read_state <= IDLE_READ;
      end
      default: begin
        read_state <= IDLE_READ;
      end
    endcase
  end
end

wire is_read0 = read_state == MEM0_READ;
wire is_read1 = read_state == MEM1_READ;
wire is_write1 = write_state == MEM1_WRITE;

/* reg [31:0] raddr; */
/* always@(posedge i_clock)begin */
/*   if(ifu.arvalid) raddr <= out.araddr0; */
/*   else if(lsu.arvalid) raddr <= out.araddr1; */
/*   else raddr <= 0; */
/* end */

assign out.araddr = is_read0 ? ifu.araddr : is_read1 ? lsu.araddr : 0;
/* assign out.araddr = raddr; */
assign out.arvalid = is_read0 ? ifu.arvalid : is_read1 ? lsu.arvalid : 0;
assign out.arid = is_read0 ? ifu.arid : is_read1 ? lsu.arid : 0;
assign out.arlen = is_read0 ? ifu.arlen : is_read1 ? lsu.arlen : 0;
assign out.arsize = is_read0 ? ifu.arsize : is_read1 ? lsu.arsize : 0;
assign out.arburst = is_read0 ? ifu.arburst : is_read1 ? lsu.arburst : 0;
assign out.rready = is_read0 ? ifu.rready : is_read1 ? lsu.rready : 0;

assign ifu.arready = is_read0 ? out.arready : i_flush;
assign ifu.rvalid = is_read0 ? out.rvalid : i_flush;
assign ifu.rlast = is_read0 ? out.rlast : i_flush;
assign ifu.rdata = is_read0 ? out.rdata : 0;
assign ifu.rresp = is_read0 ? out.rresp : 0;
assign ifu.rid = is_read0 ? out.rid : 0;


assign lsu.arready = is_read1 ? out.arready : 0;
assign lsu.rdata = is_read1 ? out.rdata : 0;
assign lsu.rvalid = is_read1 ? out.rvalid : 0;
assign lsu.rresp = is_read1 ? out.rresp : 0;
assign lsu.rid = is_read1 ? out.rid : 0;
assign lsu.rlast = is_read1 ? out.rlast : 0;

always@(posedge i_clock)begin
  if(i_reset) write_state <= IDLE_WRITE;
  else begin
    case(write_state)
      IDLE_WRITE:begin
        if(lsu.awvalid) write_state <= MEM1_WRITE;
      end
      MEM1_WRITE:begin
        if(out.bvalid && out.bready) write_state <= IDLE_WRITE;
      end
      default: begin
        write_state <= IDLE_WRITE;
      end
    endcase
  end
end

assign out.awaddr = is_write1 ? lsu.awaddr : 0;
assign out.awvalid = is_write1 ? lsu.awvalid : 0;
assign out.awid = is_write1 ? lsu.awid : 0;
assign out.awlen = is_write1 ? lsu.awlen : 0;
assign out.awsize = is_write1 ? lsu.awsize : 0;
assign out.awburst = is_write1 ? lsu.awburst : 0;
assign out.wdata = is_write1 ? lsu.wdata : 0;
assign out.wstrb = is_write1 ? lsu.wstrb : 0;
assign out.wvalid = is_write1 ? lsu.wvalid : 0;
assign out.wlast = is_write1 ? lsu.wlast : 0;
assign out.bready = is_write1 ? lsu.bready : 0;

assign lsu.awready = is_write1 ? out.awready : 0;
assign lsu.wready = is_write1 ? out.wready : 0;
assign lsu.bresp = is_write1 ? out.bresp : 0;
assign lsu.bvalid = is_write1 ? out.bvalid : 0;
assign lsu.bid = is_write1 ? out.bid : 0;
endmodule
