import "DPI-C" function int inst_fetch(input int addr);

module ysyx_20020207_IFU(
  input en,
  input [31:0] pc,
  output reg [31:0] inst
);

always@* begin
  if(en) inst = inst_fetch(pc);
  else inst = 0;
end

endmodule
