module ysyx_24110006_PC(
  input i_clock,
  input i_reset,
  input i_jump,
  input [31:0] i_upc,
  output [31:0] o_pc,

  input i_valid,
  output reg o_valid,
  input i_ready,
  input i_flush
);
localparam MROM = 32'h20000000;
localparam FLASH = 32'h30000000;
`ifdef CONFIG_YSYXSOC
  localparam PC = FLASH;
`else
  localparam PC = 32'h80000000;
`endif
reg[31:0] pc;
reg reset;

always@(posedge i_clock)
  reset <= i_reset;

always@(posedge i_clock)begin
  if(reset && !i_reset) o_valid <= 1;
  else if(i_reset) o_valid <= 0;
end

always@(posedge i_clock)begin
  if(reset) pc <= PC;
  else if(i_flush) pc <= i_upc;
  else if(o_valid && i_ready) begin
    pc <= pc + 4;
  end
end

assign o_pc = pc;
endmodule
