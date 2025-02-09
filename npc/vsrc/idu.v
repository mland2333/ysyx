`include "common_config.v"
module ysyx_24110006_IDU(
  input i_clock,
  input i_reset,
  input [31:0] i_inst,
  input [31:0] i_imm,
  input [31:0] i_pc,
  output [6:0] o_op,
  output [2:0] o_func,
  output [4:0] o_reg_rs1,
  output [4:0] o_reg_rs2,
  output [4:0] o_reg_rd,
  output o_reg_wen,
  output [31:0] o_imm,
  output [31:0] o_pc,
  output [1:0] o_csr_t,
  output [11:0] o_csr,
  output o_mret,
  input i_exception,
  output o_exception,
  input [3:0] i_mcause,
  output [3:0] o_mcause,

  input i_valid,
  output reg o_valid,
  input i_ready,
  output o_ready,

  input i_flush,
  input i_stall,
  input i_wen,
  input i_ren
);

reg [31:0] inst;
reg [31:0] imm;
reg [31:0] pc;
wire update_reg;

always@(posedge i_clock)begin
  if(i_reset || i_flush) o_valid <= 0;
  else if(i_valid) begin
    o_valid <= 1;
  end
  else if(o_valid && i_ready && !i_stall) begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(i_reset || i_flush) o_ready <= 1;
  else if(i_stall) o_ready <= 0;
  else if(i_valid && o_valid && (i_wen || i_ren)) o_ready <= 0;
  else if(i_ready) o_ready <= 1;
  else if(i_valid) o_ready <= 0;
end

assign update_reg = i_valid && (o_ready || i_ready) &&!i_stall && !i_flush;
reg exception;
always@(posedge i_clock)begin
  if(update_reg)
    exception <= i_exception;
end
assign o_exception = exception | my_exception;
reg [3:0] mcause;
always@(posedge i_clock)begin
  if(update_reg)
    mcause <= i_mcause;
end
assign o_mcause = exception ? mcause : my_mcause;

wire I = o_op[6:2] == 5'b00100;
wire R = o_op[6:2] == 5'b01100;
wire L = o_op[6:2] == 5'b00000;
wire S = o_op[6:2] == 5'b01000;
wire JAL = o_op[6:2] == 5'b11011;
wire JALR = o_op[6:2] == 5'b11001;
wire AUIPC = o_op[6:2] == 5'b00101;
wire LUI = o_op[6:2] == 5'b01101;
wire B = o_op[6:2] == 5'b11000;
wire CSR = o_op[6:2] == 5'b11100;
wire FENCE = o_op[6:2] == 5'b00011;

/* wire illegal_inst = 0; */
wire illegal_inst = !(I|R|L|S|JAL|JALR|AUIPC|LUI|B|CSR|FENCE) && !i_flush;
wire breakpoint = inst == 32'h00100073;
wire ecall_m = inst == 32'h00000073;
wire my_exception = illegal_inst | breakpoint | ecall_m;
wire [3:0] my_mcause = ({4{illegal_inst}} & 4'd2) |
                       ({4{breakpoint}} & 4'd3)   |
                       ({4{ecall_m}} & 4'd11);

always@(posedge i_clock)begin
  if(update_reg)
    inst <= i_inst;
end
always@(posedge i_clock)begin
  if(update_reg)
    pc <= i_pc;
end
always@(posedge i_clock)begin
  if(update_reg)
    imm <= i_imm;
end
assign o_op = inst[6:0];
assign o_func = inst[14:12];
assign o_reg_rd = inst[11:7];
assign o_reg_rs1 = inst[19:15];
assign o_reg_rs2 = inst[24:20];
assign o_pc = pc;
assign o_imm = imm;
assign o_reg_wen = I|R|L|JAL|JALR|AUIPC|LUI;
assign o_csr = inst[31:20];
assign o_mret = inst == 32'h30200073;
`ifndef CONFIG_YOSYS
always@(posedge i_clock)begin
  if(o_valid && !(I||R||L||S||JAL||JALR||AUIPC||LUI||B||CSR||FENCE) && !i_flush) begin
    $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh` in pc `%xh` \n", o_op, o_pc);
    quit();
  end
end
`endif
assign o_csr_t[0] = CSR & (o_func != 0);
assign o_csr_t[1] = o_mret;

endmodule
