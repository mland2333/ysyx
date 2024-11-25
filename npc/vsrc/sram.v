import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

module ysyx_24110006_SRAM(
  input i_ren,
  input i_wen,
  input [31:0] i_raddr,
  input [31:0] i_waddr,
  input [31:0] i_wdata,
  input [7:0]  i_wmask,
  output reg [31:0] o_rdata
);

always@(i_ren or i_raddr)begin
  if(i_ren) o_rdata = pmem_read(i_raddr);
end

always@(i_wen or i_waddr or i_wdata or i_wmask)begin
  if(i_wen) pmem_write(i_waddr, i_wdata, i_wmask);
end
endmodule
