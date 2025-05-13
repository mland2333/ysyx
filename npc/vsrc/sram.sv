`ifndef CONFIG_YSYXSOC
import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

module ysyx_24110006_SRAM #(
  parameter FIFO_DEPTH = 8
)
(
  input i_clock,
  input i_reset,
  if_axi.slave i_axi
  /* output        o_axi_awready, */
  /* input         i_axi_awvalid, */
  /* input  [31:0] i_axi_awaddr, */
  /* input  [3:0]  i_axi_awid, */
  /* input  [7:0]  i_axi_awlen, */
  /* input  [2:0]  i_axi_awsize, */
  /* input  [1:0]  i_axi_awburst, */
  /* output        o_axi_wready, */
  /* input         i_axi_wvalid, */
  /* input  [31:0] i_axi_wdata, */
  /* input  [3:0]  i_axi_wstrb, */
  /* input         i_axi_wlast, */
  /* input         i_axi_bready, */
  /* output        o_axi_bvalid, */
  /* output [1:0]  o_axi_bresp, */
  /* output [3:0]  o_axi_bid, */
  /* output        o_axi_arready, */
  /* input         i_axi_arvalid, */
  /* input  [31:0] i_axi_araddr, */
  /* input  [3:0]  i_axi_arid, */
  /* input  [7:0]  i_axi_arlen, */
  /* input  [2:0]  i_axi_arsize, */
  /* input  [1:0]  i_axi_arburst, */
  /* input         i_axi_rready, */
  /* output        o_axi_rvalid, */
  /* output [1:0]  o_axi_rresp, */
  /* output [31:0] o_axi_rdata, */
  /* output        o_axi_rlast, */
  /* output [3:0]  o_axi_rid */
);
/* localparam COUNT = 8'h05; */

/* reg[7:0] out; */
/* always@(is_begin)begin */
/*   if(i_reset || out==0) begin out <= COUNT;end */
/*   else if(is_begin)begin */
/*     out[6:0] <= out[7:1]; */
/*     out[7] <= out[4]^out[3]^out[2]^out[0]; */
/*   end */
/* end */
/**/
/* reg [7:0] count; */
/* reg is_begin; */
/**/
/* always@(posedge i_clock)begin */
/*   if(i_reset) is_begin <= 0; */
/*   else if(arvalid && !arready || awvalid && !awready) is_begin <= 1; */
/*   else if(count == 0) is_begin <= 0; */
/* end */
/**/
/* always@(posedge i_clock)begin */
/*   if(i_reset) count <= COUNT; */
/*   else if(is_begin && count != 0) */
/*     count <= count - 1; */
/*   else if(count == 0) */
/*     count <= out; */
/* end */

reg [31:0] araddr;
reg arready;
reg [31:0] rdata;
reg rvalid;
reg [1:0] rresp;
reg [31:0] awaddr;
reg awready;
reg [31:0] wdata;
reg wready;
reg [3:0] wstrb;
reg bvalid;
reg [1:0] bresp;

wire arvalid = i_axi.arvalid;
assign i_axi.arready = arready;
assign i_axi.rdata = rdata;
assign i_axi.rvalid = rvalid;
assign i_axi.rresp = rresp;
wire rready = i_axi.rready;
wire awvalid = i_axi.awvalid;
assign i_axi.awready = awready;
wire wvalid = i_axi.wvalid;
assign i_axi.wready = wready;
assign i_axi.bresp = bresp;
assign i_axi.bvalid = bvalid;
wire bready = i_axi.bready;

logic [2:0] arsize;
logic [7:0] arlen;
logic [1:0] arburst;
logic [7:0] rtrans_nums;
logic rlast;
always_ff@(posedge i_clock)begin
  if(arvalid && arready) begin
    arsize <= i_axi.arsize;
    arlen <= i_axi.arlen;
    arburst <= i_axi.arburst;
  end
end
always@(posedge i_clock)begin
  if(i_reset || rtrans_nums == arlen) rtrans_nums <= 0;
  else if(rvalid && rready) rtrans_nums <= rtrans_nums + 1;
end

always_ff@(posedge i_clock)begin
  if(i_reset) rvalid <= 0;
  else begin
    if(!rvalid && in_trans) rvalid <= 1;
    else if(rvalid && rready) rvalid <= 0;
  end
end

always_ff@(posedge i_clock)begin
  if(i_reset) rlast <= 0;
  else if(in_trans && rtrans_nums == arlen) rlast <= 1;
  else if(rlast && rvalid && rready) rlast <= 0;
end
/* typedef struct { */
/*   logic [2:0] arsize; */
/*   logic [7:0] arlen; */
/*   logic [1:0] arburst; */
/*   logic [31:0] araddr; */
/* } read_task_t; */
/* localparam FIFO_INDEX_WIDTH = $clog2(FIFO_DEPTH); */
/* read_task_t rfifo [8]; */
/**/
/* logic [FIFO_INDEX_WIDTH-1:0] rfifo_rptr, rfifo_wptr; */
/* logic is_empty; */
/* always_ff@(posedge i_clock)begin */
/*   if(i_reset) begin */
/*     rfifo_rptr <= 0; */
/*     rfifo_wptr <= 0; */
/*     is_empty <= 1; */
/*   end */
/* end */

//arready
always@(posedge i_clock)begin
  /* if(i_reset) arready <= 0; */
  /* else if(arvalid && count == 0 && !arready) */
  /*   arready <= 1; */
  /* else if(arvalid && arready) */
  /*   arready <= 0; */
  arready <= 1;
end
//araddr
always@(posedge i_clock)begin
  if(i_reset) araddr <= 0;
  else if(arvalid && arready)begin
    araddr <= i_axi_araddr;
  end
end
//rdata
always@(posedge i_clock)begin
  if(i_reset) rdata <= 0;
  else if(arvalid && arready)begin
    rdata <= pmem_read(i_axi_araddr);
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
//awready
always@(posedge i_clock)begin
  /* if(i_reset) awready <= 0; */
  /* else if(awvalid && count == 0 && !awready) */
  /*   awready <= 1; */
  /* else if(awvalid && awready) */
  /*   awready <= 0; */
  awready <= 1;
end
//awaddr
always@(posedge i_clock)begin
  if(i_reset) awaddr <= 0;
  else if(awvalid && awready)begin
    awaddr <= i_axi_awaddr;
  end
end
//wready
always@(posedge i_clock)begin
  /* if(i_reset) wready <= 0; */
  /* else if(wvalid && count == 0 && !wready) */
  /*   wready <= 1; */
  /* else if(wvalid && wready) */
  /*   wready <= 0; */
  wready <= 1;
end
//wdata
always@(posedge i_clock)begin
  if(i_reset) wdata <= 0;
  else if(wvalid && wready)begin
    wdata <= i_axi_wdata;
  end
end
//wstrb
always@(posedge i_clock)begin
  if(i_reset) wstrb <= 0;
  else if(wvalid && wready)begin
    wstrb <= i_axi_wstrb;
  end
end

always@(posedge i_clock)begin
  if(awvalid && awready && wvalid && wready && !bvalid)begin
    pmem_write(i_axi_awaddr, i_axi_wdata, {4'b0, i_axi_wstrb});
  end
end
//bvlid
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
`endif
