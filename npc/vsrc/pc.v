module ysyx_20020207_PC(
  input clock,
  input reset,
  input jump,
  input [31:0] upc,
  output reg [31:0] pc
);

always@(posedge clock)begin
  if(reset) pc <= 32'h80000000;
  else if(jump) pc <= upc;
  else pc <= pc + 4;
  end
endmodule
