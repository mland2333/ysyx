import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

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
reg ren;
reg wen;
reg[31:0] addr;
reg[31:0] wdata;
reg[3:0] wmask;
reg[2:0] read_t;

always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(!o_valid && i_valid) begin
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

reg[31:0] rdata0;
reg[31:0] rdata1, rdata2;
reg[31:0] wdata0, wdata1, wdata2;
reg[3:0] wmask0, wmask1, wmask2;

always@(ren or addr)begin
  if(ren)begin
    rdata1 = pmem_read(addr);
    rdata2 = 0;
    case(addr[1:0])
      2'b00:begin
        rdata0 = rdata1;
      end
      2'b01:begin
        if(read_t[1])begin
          rdata2 = pmem_read(addr+4);
          rdata0 = {rdata2[7:0], rdata1[31:8]};
        end
        else begin
          rdata0 = {8'b0, rdata1[31:8]};
        end
      end
      2'b10:begin
        if(read_t[1])begin
          rdata2 = pmem_read(addr+4);
          rdata0 = {rdata2[15:0], rdata1[31:16]};
        end
        else begin
          rdata0 = {16'b0, rdata1[31:16]};
        end
      end
      2'b11:begin
        if(read_t[1] || read_t[0])begin
          rdata2 = pmem_read(addr+4);
          rdata0 = {rdata2[23:0], rdata1[31:24]};
        end
        else begin
          rdata0 = {24'b0, rdata1[31:24]};
        end
      end
    endcase
  end
end

always @(*) begin
  case (read_t)
    3'b000:  o_rdata = {{24{rdata0[7]}}, rdata0[7:0]};
    3'b001:  o_rdata = {{16{rdata0[15]}}, rdata0[15:0]};
    3'b010:  o_rdata = rdata0;
    3'b100:  o_rdata = {24'b0, rdata0[7:0]};
    3'b101:  o_rdata = {16'b0, rdata0[15:0]};
    default: o_rdata = rdata0;
  endcase
end


always@(wen or addr or wdata)begin
  if(wen)begin
    case(addr[1:0])
      2'b00:begin
        wdata0 = wdata;
        pmem_write(addr, wdata0, {4'b0, wmask});
      end
      2'b01:begin
        wdata0 = {wdata[23:0], wdata[31:24]};
        if(wmask[3])begin
          pmem_write(addr, wdata0, {4'b0, wmask[2:0], 1'b0});
          pmem_write(addr + 4, wdata0, 8'b01);
        end
        else begin
          pmem_write(addr, wdata0, {4'b0, wmask[2:0], 1'b0});
        end
      end
      2'b10:begin
        wdata0 = {wdata[15:0], wdata[31:16]};
        if(wmask[3])begin
          pmem_write(addr, wdata0, {4'b0, wmask[1:0], 2'b0});
          pmem_write(addr + 4, wdata0, 8'b0011);
        end
        else begin
          pmem_write(addr, wdata0, {4'b0, wmask[1:0], 2'b0});
        end
      end
      2'b11:begin
        wdata0 = {wdata[7:0], wdata[31:8]};
        if(wmask[1])begin
          pmem_write(addr, wdata0, {4'b0, wmask[0], 3'b0});
          pmem_write(addr + 4, wdata0, {5'b0, wmask[3:1]});
        end
        else begin
          pmem_write(addr, wdata0, 8'b1000);
        end
      end
    endcase
  end
end

endmodule
