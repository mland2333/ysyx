module ysyx_24110006_ARBITER(
  input i_clock,
  input i_reset,

  input [31:0] i_axi_araddr0,
  input i_axi_arvalid0,
  output o_axi_arready0,
  input [3:0] i_axi_arid0,
  input [7:0] i_axi_arlen0,
  input [2:0] i_axi_arsize0,
  input [1:0] i_axi_arburst0,
  output [31:0] o_axi_rdata0,
  output o_axi_rvalid0,
  output [1:0] o_axi_rresp0,
  input i_axi_rready0,
  output [3:0] o_axi_rid0,
  output o_axi_rlast0,

  input [31:0] i_axi_araddr1,
  input i_axi_arvalid1,
  output o_axi_arready1,
  input [3:0] i_axi_arid1,
  input [7:0] i_axi_arlen1,
  input [2:0] i_axi_arsize1,
  input [1:0] i_axi_arburst1,
  output [31:0] o_axi_rdata1,
  output o_axi_rvalid1,
  output [1:0] o_axi_rresp1,
  input i_axi_rready1,
  output [3:0] o_axi_rid1,
  output o_axi_rlast1,
  input [31:0] i_axi_awaddr1,
  input i_axi_awvalid1,
  output o_axi_awready1,
  input [3:0] i_axi_awid1,
  input [7:0] i_axi_awlen1,
  input [2:0] i_axi_awsize1,
  input [1:0] i_axi_awburst1,
  input [31:0] i_axi_wdata1,
  input [3:0] i_axi_wstrb1,
  input i_axi_wvalid1,
  output o_axi_wready1,
  input i_axi_wlast1,
  output [1:0] o_axi_bresp1,
  output o_axi_bvalid1,
  input i_axi_bready1,
  output [3:0] o_axi_bid1,

  output [31:0] o_axi_araddr,
  output o_axi_arvalid,
  input i_axi_arready,
  output [3:0] o_axi_arid,
  output [7:0] o_axi_arlen,
  output [2:0] o_axi_arsize,
  output [1:0] o_axi_arburst,
  input [31:0] i_axi_rdata,
  input i_axi_rvalid,
  input [1:0] i_axi_rresp,
  output o_axi_rready,
  input [3:0] i_axi_rid,
  input i_axi_rlast,
  output [31:0] o_axi_awaddr,
  output o_axi_awvalid,
  input i_axi_awready,
  output [3:0] o_axi_awid,
  output [7:0] o_axi_awlen,
  output [2:0] o_axi_awsize,
  output [1:0] o_axi_awburst,
  output [31:0] o_axi_wdata,
  output [3:0] o_axi_wstrb,
  output o_axi_wvalid,
  input i_axi_wready,
  output o_axi_wlast,
  input [1:0] i_axi_bresp,
  input i_axi_bvalid,
  output o_axi_bready,
  input [3:0] i_axi_bid
);
localparam IDLE_READ = 2'b00;
localparam MEM0_READ = 2'b01;
localparam MEM1_READ = 2'b10;
localparam IDLE_WRITE = 2'b00;
localparam MEM1_WRITE = 2'b01;
reg [1:0] read_state;
reg [1:0] write_state;

always@(posedge i_clock)begin
  if(i_reset) read_state <= IDLE_READ;
  else begin
    case(read_state)
      IDLE_READ:begin
        if(i_axi_arvalid0) read_state <= MEM0_READ;
        else if(i_axi_arvalid1) read_state <= MEM1_READ;
      end
      MEM0_READ:begin
        if(i_axi_rvalid && o_axi_rready) read_state <= IDLE_READ;
      end
      MEM1_READ:begin
        if(i_axi_rvalid && o_axi_rready) read_state <= IDLE_READ;
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

assign o_axi_araddr = is_read0 ? i_axi_araddr0 : is_read1 ? i_axi_araddr1 : 0;
assign o_axi_arvalid = is_read0 ? i_axi_arvalid0 : is_read1 ? i_axi_arvalid1 : 0;
assign o_axi_arid = is_read0 ? i_axi_arid0 : is_read1 ? i_axi_arid1 : 0;
assign o_axi_arlen = is_read0 ? i_axi_arlen0 : is_read1 ? i_axi_arlen1 : 0;
assign o_axi_arsize = is_read0 ? i_axi_arsize0 : is_read1 ? i_axi_arsize1 : 0;
assign o_axi_arburst = is_read0 ? i_axi_arburst0 : is_read1 ? i_axi_arburst1 : 0;
assign o_axi_rready = is_read0 ? i_axi_rready0 : is_read1 ? i_axi_rready1 : 0;


assign o_axi_arready0 = is_read0 ? i_axi_arready : 0;
assign o_axi_rdata0 = is_read0 ? i_axi_rdata : 0;
assign o_axi_rvalid0 = is_read0 ? i_axi_rvalid : 0;
assign o_axi_rresp0 = is_read0 ? i_axi_rresp : 0;
assign o_axi_rid0 = is_read0 ? i_axi_rid : 0;
assign o_axi_rlast0 = is_read0 ? i_axi_rlast : 0;

assign o_axi_arready1 = is_read1 ? i_axi_arready : 0;
assign o_axi_rdata1 = is_read1 ? i_axi_rdata : 0;
assign o_axi_rvalid1 = is_read1 ? i_axi_rvalid : 0;
assign o_axi_rresp1 = is_read1 ? i_axi_rresp : 0;
assign o_axi_rid1 = is_read1 ? i_axi_rid : 0;
assign o_axi_rlast1 = is_read1 ? i_axi_rlast : 0;

always@(posedge i_clock)begin
  if(i_reset) write_state <= IDLE_WRITE;
  else begin
    case(write_state)
      IDLE_WRITE:begin
        if(i_axi_awvalid1) write_state <= MEM1_WRITE;
      end
      MEM1_WRITE:begin
        if(i_axi_bvalid && o_axi_bready) write_state <= IDLE_WRITE;
      end
      default: begin
        write_state <= IDLE_WRITE;
      end
    endcase
  end
end

assign o_axi_awaddr = is_write1 ? i_axi_awaddr1 : 0;
assign o_axi_awvalid = is_write1 ? i_axi_awvalid1 : 0;
assign o_axi_awid = is_write1 ? i_axi_awid1 : 0;
assign o_axi_awlen = is_write1 ? i_axi_awlen1 : 0;
assign o_axi_awsize = is_write1 ? i_axi_awsize1 : 0;
assign o_axi_awburst = is_write1 ? i_axi_awburst1 : 0;
assign o_axi_wdata = is_write1 ? i_axi_wdata1 : 0;
assign o_axi_wstrb = is_write1 ? i_axi_wstrb1 : 0;
assign o_axi_wvalid = is_write1 ? i_axi_wvalid1 : 0;
assign o_axi_wlast = is_write1 ? i_axi_wlast1 : 0;
assign o_axi_bready = is_write1 ? i_axi_bready1 : 0;

assign o_axi_awready1 = is_write1 ? i_axi_awready : 0;
assign o_axi_wready1 = is_write1 ? i_axi_wready : 0;
assign o_axi_bresp1 = is_write1 ? i_axi_bresp : 0;
assign o_axi_bvalid1 = is_write1 ? i_axi_bvalid : 0;
assign o_axi_bid1 = is_write1 ? i_axi_bid : 0;
endmodule
