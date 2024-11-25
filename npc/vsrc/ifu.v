/* import "DPI-C" function int inst_fetch(input int addr); */
module ysyx_24110006_IFU(
  input i_clock,
  input i_reset,
  input [31:0] i_pc,
  output reg [31:0] o_inst,

  input i_valid,
  output reg o_valid
);

always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(!o_valid && i_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end

/* always@(posedge i_clock)begin */
/*   if(!i_reset && !o_valid && i_valid) */
/*     o_inst <= inst_fetch(i_pc); */
/* end */

reg ren;
always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    ren <= 1;
  else 
    ren <= 0;
end

ysyx_24110006_SRAM msram(
  .i_ren(ren),
  .i_wen(0),
  .i_raddr(i_pc),
  .i_waddr(0),
  .i_wdata(0),
  .i_wmask(0),
  .o_rdata(o_inst)
);

endmodule
