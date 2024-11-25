/* import "DPI-C" function int pmem_read(input int raddr); */
/* import "DPI-C" function void pmem_write( */
/*   input int waddr, input int wdata, input byte wmask); */
/**/
module ysyx_24110006_LSU(
  input i_clock,
  input i_reset,
  input i_ren,
  input i_wen,
  input[31:0] i_addr,
  input[31:0] i_wdata,
  input[3:0] i_wmask,
  input[2:0] i_read_t,
  output reg[31:0] o_rdata,

  input i_valid,
  output reg o_valid
);

localparam COUNT = 8'h05;

reg[7:0] out;
always@(is_begin)begin
  if(i_reset || out==0) begin out <= COUNT;end
  else if(is_begin)begin
    out[6:0] <= out[7:1];
    out[7] <= out[4]^out[3]^out[2]^out[0];
  end
end

reg [7:0] count;
reg is_begin;

always@(posedge i_clock)begin
  if(i_reset) is_begin <= 0;
  else if(rvalid && !rready || bvalid && !bready) is_begin <= 1;
  else if(count == 0) is_begin <= 0;
end

always@(posedge i_clock)begin
  if(i_reset) count <= COUNT;
  else if(is_begin && count != 0)
    count <= count - 1;
  else if(count == 0)
    count <= out;
end

reg ren;
reg wen;
reg[31:0] addr;
reg[31:0] wdata;
reg[3:0] wmask;
reg[2:0] read_t;

always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(!o_valid && (ren&&rvalid&&rready || wen&&bvalid&&bready || !i_wen&&!i_ren&&i_valid)) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    ren <= i_ren;
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    wen <= i_wen;
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    addr <= i_addr;
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    wdata <= i_wdata;
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    wmask <= i_wmask;
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    read_t <= i_read_t;
end

reg[31:0] rdata, rdata0;
reg[31:0] wdata0;
reg[7:0] wmask0;

always@(*)begin
  case(addr[1:0])
    2'b00:begin
      rdata = rdata0;
    end
    2'b01:begin
      rdata = {8'b0, rdata0[31:8]};
    end
    2'b10:begin
      rdata = {16'b0, rdata0[31:16]};
    end
    2'b11:begin
      rdata = {24'b0, rdata0[31:24]};
    end
  endcase
end

always @(*) begin
  case (read_t)
    3'b000:  o_rdata = {{24{rdata[7]}}, rdata[7:0]};
    3'b001:  o_rdata = {{16{rdata[15]}}, rdata[15:0]};
    3'b010:  o_rdata = rdata;
    3'b100:  o_rdata = {24'b0, rdata[7:0]};
    3'b101:  o_rdata = {16'b0, rdata[15:0]};
    default: o_rdata = rdata;
  endcase
end


always@(wen or addr or wdata)begin
  if(wen)begin
    case(addr[1:0])
      2'b00:begin
        wdata0 = wdata;
        wmask0 = {4'b0, wmask};
      end
      2'b01:begin
        wdata0 = {wdata[23:0], wdata[31:24]};
        wmask0 = {4'b0, wmask[2:0], 1'b0};
      end
      2'b10:begin
        wdata0 = {wdata[15:0], wdata[31:16]};
        wmask0 = {4'b0, wmask[1:0], 2'b0};
      end
      2'b11:begin
        wdata0 = {wdata[7:0], wdata[31:8]};
        wmask0 = {4'b0, wmask[0], 3'b0};
      end
    endcase
  end
end

reg arvalid;
wire arready;

wire rvalid;
reg rready;
wire [1:0] rresp;

reg awvalid;
wire awready;

reg wvalid;
wire wready;

wire [1:0] bresp;
wire bvalid;
reg bready;

always@(posedge i_clock) begin
  if(i_reset) arvalid <= 0;
  else if(i_valid && !arvalid && i_ren) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end

always@(posedge i_clock)begin
  if(i_reset) rready <= 0;
  else if(rvalid && !rready && count == 0)
    rready <= 1;
  else if(rvalid && rready)
    rready <= 0;
end

always@(posedge i_clock) begin
  if(i_reset) awvalid <= 0;
  else if(i_valid && !awvalid && i_wen) awvalid <= 1;
  else if(awvalid && awready) awvalid <= 0;
end

always@(posedge i_clock) begin
  if(i_reset) wvalid <= 0;
  else if(i_valid && !wvalid && i_wen) wvalid <= 1;
  else if(wvalid && wready) wvalid <= 0;
end

always@(posedge i_clock)begin
  if(i_reset) bready <= 0;
  else if(bvalid && !bready && count == 0)
    bready <= 1;
  else if(bvalid && bready)
    bready <= 0;
end

ysyx_24110006_SRAM msram(
  .i_clock(i_clock),
  .i_reset(i_reset),
  .i_axi_araddr(addr),
  .i_axi_arvalid(arvalid),
  .o_axi_arready(arready),

  .o_axi_rdata(rdata0),
  .o_axi_rvalid(rvalid),
  .o_axi_rresp(rresp),
  .i_axi_rready(rready),

  .i_axi_awaddr(addr),
  .i_axi_awvalid(awvalid),
  .o_axi_awready(awready),

  .i_axi_wdata(wdata0),
  .i_axi_wstrb(wmask0),
  .i_axi_wvalid(wvalid),
  .o_axi_wready(wready),

  .o_axi_bresp(bresp),
  .o_axi_bvalid(bvalid),
  .i_axi_bready(bready)
);



endmodule
