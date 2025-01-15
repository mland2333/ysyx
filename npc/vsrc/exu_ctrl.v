module ysyx_24110006_EXU_CTRL(
  input i_clock,
  input i_reset,
  input [3:0] i_alu_t,
  input [4:0] i_reg_rd,
  input i_cmp,
  input i_zero,
  input i_result_t,
  input i_reg_wen,
  input i_csr_wen,
  input i_jump,
  input i_trap,
  input i_ren,
  input i_wen,
  input [31:0] i_result,
  input [31:0] i_upc,
  
  output [31:0] o_upc,
  output o_result_t,
  output o_reg_wen,
  output o_reg_rd,
  output o_csr_wen,
  output o_jump,
  output [31:0] o_result,

  input i_valid,
  output reg o_valid
`ifdef CONFIG_PIPELINE
  ,input i_ready,
  output o_ready
`endif
);
localparam BEQ = 4'b1000;
localparam BNE = 4'b1001;
localparam BLT = 4'b1100;
localparam BGE = 4'b1101;
localparam BLTU = 4'b1110;
localparam BGEU = 4'b1111;

reg [31:0] result;
reg [31:0] upc;
reg [3:0] alu_t;
reg [4:0] reg_rd;
reg result_t;
reg reg_wen;
reg csr_wen;
reg jump;
reg trap;
reg cmp;
reg zero;
wire update_reg;
`ifdef CONFIG_PIPELINE
always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(i_valid && !o_valid && i_ready && !(i_wen||i_ren)) o_valid <= 1;
  else if(o_valid && i_ready) o_valid <= 0;
end
always@(posedge i_clock)begin
  if(i_reset) o_ready <= 1;
  else if(i_ready) o_ready <= 1;
  else if(i_valid) o_ready <= 0;
end
assign update_reg = i_valid && o_ready;
`else
always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(i_valid && !(i_wen||i_ren)) o_valid <= 1;
  else if(o_valid) o_valid <= 0;
end
assign update_reg = i_valid;
`endif

always@(posedge i_clock)begin
  if(update_reg)
    upc <= i_upc;
end
always@(posedge i_clock)begin
  if(update_reg)
    result <= i_result;
end
always@(posedge i_clock)begin
  if(update_reg)
    result_t <= i_result_t;
end
always@(posedge i_clock)begin
  if(update_reg)
    reg_wen <= i_reg_wen;
end
always@(posedge i_clock)begin
  if(update_reg)
    reg_rd <= i_reg_rd;
end
always@(posedge i_clock)begin
  if(update_reg)
    csr_wen <= i_csr_wen;
end
always@(posedge i_clock)begin
  if(update_reg)
    jump <= i_jump;
end
always@(posedge i_clock)begin
  if(update_reg)
    trap <= i_trap;
end
always@(posedge i_clock)begin
  if(update_reg)
    alu_t <= i_alu_t;
end
always@(posedge i_clock)begin
  if(update_reg)
    cmp <= i_cmp;
end
always@(posedge i_clock)begin
  if(update_reg)
    zero <= i_zero;
end

wire branch = (alu_t==BEQ)&&zero||(alu_t==BNE)&&~zero||(alu_t==BLT||alu_t==BLTU)&&cmp||(alu_t==BGE||alu_t==BGEU)&&~cmp;

assign o_jump = trap || jump || branch;
assign o_upc = upc;
assign o_reg_wen = reg_wen;
assign o_csr_wen = csr_wen;
assign o_result_t = result_t;
assign o_result = result;
assign o_reg_rd = reg_rd;
endmodule
