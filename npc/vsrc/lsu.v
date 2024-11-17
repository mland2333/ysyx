import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

module ysyx_24110006_LSU(
  input i_ren,
  input i_wen,
  input[31:0] i_addr,
  input[31:0] i_wdata,
  input[3:0]  i_wmask,
  input[2:0]  i_read_t,
  output reg[31:0] o_rdata
);

reg[31:0] rdata;

 always @(*) begin
  case (i_read_t)
    3'b000:  o_rdata = {{24{rdata[7]}}, rdata[7:0]};
    3'b001:  o_rdata = {{16{rdata[15]}}, rdata[15:0]};
    3'b010:  o_rdata = rdata;
    3'b100:  o_rdata = {24'b0, rdata[7:0]};
    3'b101:  o_rdata = {16'b0, rdata[15:0]};
    default: o_rdata = rdata;
  endcase
end

always@(i_ren or i_addr)begin
  if(i_ren) begin
    rdata = pmem_read(i_addr);
  end
  else begin 
    rdata = 0;
  end
end

always@(i_wen or i_addr)begin
  if(i_wen) begin
    pmem_write(i_addr, i_wdata, {4'b0, i_wmask});
  end
end

endmodule
