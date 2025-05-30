module ysyx_24110006_PC(
  input i_clock,
  input i_reset,
  input i_jump,
  input [31:0] i_upc,
  output [31:0] o_pc,

  input i_valid,
  output reg o_valid
`ifdef CONFIG_PIPELINE
  ,input i_ready,
  input i_flush
`endif
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

`ifdef CONFIG_PIPELINE
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

`else
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
`endif


assign o_pc = pc;
endmodule
