module ysyx_24110006_PC(
  input i_clock,
  input i_reset,
  input i_jump,
  input [31:0] i_upc,
  output [31:0] o_pc
);

reg[31:0] pc;
reg reset;

always@(posedge i_clock)
  reset <= i_reset;

always@(posedge i_clock)begin
  if(reset) pc <= 32'h80000000;
  else if(i_jump) pc <= i_upc;
  else pc <= pc + 4;
end
assign o_pc = pc;
endmodule
