module ysyx_24110006_PC(
  input i_clock,
  input i_reset,
  input i_jump,
  input [31:0] i_upc,
  output [31:0] o_pc,
  
  input i_valid,
  output reg o_valid
);
localparam MROM = 32'h20000000;
localparam FLASH = 32'h30000000;
localparam PC = FLASH;
reg[31:0] pc;
reg reset;

always@(posedge i_clock)
  reset <= i_reset;

always@(posedge i_clock)begin
  if(reset && !i_reset) o_valid <= 1;
  else if(i_reset) o_valid <= 0;
  else if(!o_valid && i_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(reset) pc <= PC;
  else if(!o_valid && i_valid) begin
    if(i_jump) pc <= i_upc;
    else pc <= pc + 4;
  end
end
assign o_pc = pc;
endmodule
