module ysyx_24110006_EXU_CTRL(
  input i_clock,
  input i_reset,
  input [3:0] i_alu_t,
  input i_cmp,
  input i_zero,
  input i_result_t,
  input i_reg_wen,
  input i_csr_wen,
  input i_jump,
  input i_trap,
  input [31:0] i_result,
  input [31:0] i_upc,
  
  output [31:0] o_upc,
  output o_result_t,
  output o_reg_wen,
  output o_csr_wen,
  output o_jump,
  output [31:0] o_result,

  input i_valid
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
reg result_t;
reg reg_wen;
reg csr_wen;
reg jump;
reg trap;
reg cmp;
reg zero;

always@(posedge i_clock)begin
  if(i_valid)
    upc <= i_upc;
end
always@(posedge i_clock)begin
  if(i_valid)
    result <= i_result;
end
always@(posedge i_clock)begin
  if(i_valid)
    result_t <= i_result_t;
end
always@(posedge i_clock)begin
  if(i_valid)
    reg_wen <= i_reg_wen;
end
always@(posedge i_clock)begin
  if(i_valid)
    csr_wen <= i_csr_wen;
end
always@(posedge i_clock)begin
  if(i_valid)
    jump <= i_jump;
end
always@(posedge i_clock)begin
  if(i_valid)
    trap <= i_trap;
end
always@(posedge i_clock)begin
  if(i_valid)
    alu_t <= i_alu_t;
end
always@(posedge i_clock)begin
  if(i_valid)
    cmp <= i_cmp;
end
always@(posedge i_clock)begin
  if(i_valid)
    zero <= i_zero;
end

wire branch = (alu_t==BEQ)&&zero||(alu_t==BNE)&&~zero||(alu_t==BLT||alu_t==BLTU)&&cmp||(alu_t==BGE||alu_t==BGEU)&&~cmp;

assign o_jump = trap || jump || branch;
assign o_upc = upc;
assign o_reg_wen = reg_wen;
assign o_csr_wen = csr_wen;
assign o_result_t = result_t;
assign o_result = result;

endmodule
