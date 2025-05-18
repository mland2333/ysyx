import "DPI-C" function int inst_fetch(input int addr);

module ysyx_24110006_IFU(
  input i_en,
  input [31:0] i_pc,
  output reg [31:0] o_inst
);

always@(i_en or i_pc) begin
  if(i_en) o_inst = inst_fetch(i_pc);
  else o_inst = 0;
end

endmodule
