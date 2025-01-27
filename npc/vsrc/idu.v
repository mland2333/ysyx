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

  input i_valid,
  output reg o_valid
`ifdef CONFIG_PIPELINE
  ,input i_ready,
  output o_ready,
  input i_flush,
  input i_stall,
  input i_exception,
  output o_exception,
  input [3:0] i_mcause,
  output [3:0] o_mcause,
  input i_wen,
  input i_ren
`endif
);

reg [31:0] inst;
reg [31:0] imm;
reg [31:0] pc;
wire update_reg;

`ifdef CONFIG_PIPELINE
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

assign update_reg = i_valid && (o_ready || i_ready&&!i_stall) && !i_flush;
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

wire I = o_op == 7'b0010011;
wire R = o_op == 7'b0110011;
wire L = o_op == 7'b0000011;
wire S = o_op == 7'b0100011;
wire JAL = o_op == 7'b1101111;
wire JALR = o_op == 7'b1100111;
wire AUIPC = o_op == 7'b0010111;
wire LUI = o_op == 7'b0110111;
wire B = o_op == 7'b1100011;
wire CSR = o_op == 7'b1110011;
wire FENCE = o_op == 7'b0001111;

wire illegal_inst = !(I|R|L|S|JAL|JALR|AUIPC|LUI|B|CSR|FENCE);
wire breakpoint = inst == 32'h00100073;
wire ecall_m = inst == 32'h00000073;
wire my_exception = illegal_inst | breakpoint | ecall_m;
wire [3:0] my_mcause = ({4{illegal_inst}} & 4'd2) |
                       ({4{breakpoint}} & 4'd3)   |
                       ({4{ecall_m}} & 4'd11);
`else
always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(!o_valid && i_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end

assign update_reg = !o_valid && i_valid;
`endif
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
  if(o_valid && !(I||R||L||S||JAL||JALR||AUIPC||LUI||B||CSR||FENCE)) begin
    $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh` in pc `%xh` \n", o_op, o_pc);
    quit();
  end
end
`endif
/* wire is_i = inst[6:0] == 7'b0010011 || inst[6:0] == 7'b1100111 || inst[6:0] == 7'b0000011 || inst[6:0] == 7'b1110011; */
/* wire is_u = inst[6:0] == 7'b0110111 || inst[6:0] == 7'b0010111; */
/* wire is_j = inst[6:0] == 7'b1101111; */
/* wire is_s = inst[6:0] == 7'b0100011; */
/* wire is_b = inst[6:0] == 7'b1100011; */
/* wire is_r = inst[6:0] == 7'b0110011; */
/**/
/* wire [31:0] immi = {{20{inst[31]}}, inst[31:20]}; */
/* wire [31:0] immu = {inst[31:12], 12'b0}; */
/* wire [31:0] immj = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}; */
/* wire [31:0] imms = {{20{inst[31]}}, inst[31:25], inst[11:7]}; */
/* wire [31:0] immb = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}; */
/* wire [31:0] immr = {25'b0, inst[31:25]}; */

/* wire [31:0] iri = is_i ? immi : immr; */
/* wire [31:0] jbi = is_j ? immj : immb; */
/* wire [31:0] sui = is_s ? imms : immu; */
/**/
/* wire is_iri = is_i | is_r; */
/* wire is_sui = is_s | is_u; */
/**/
/* wire [31:0] irjbi = is_iri ? iri : jbi; */
/* wire [31:0] su0i  = is_sui ? sui : 0; */
/**/
/* wire is_irjb = is_i | is_r | is_j | is_b; */
/**/
/* assign o_imm = is_irjb ? irjbi : su0i; */

/* assign o_imm = is_i ? immi : is_j ? immj : is_u ? immu : is_s ? imms : is_b ? immb : immr; */
assign o_csr_t[0] = CSR & (o_func != 0);
assign o_csr_t[1] = o_mret;

endmodule
