module ysyx_24110006_EXU(
  input i_clock,
  input i_reset,
  input [6:0] i_op,
  input [2:0] i_func,
  input [31:0] i_alu_a,
  input [31:0] i_alu_b,
  input [3:0] i_alu_t,
  input i_alu_sign,
  input i_alu_sub,
  input i_alu_sra,
  input [4:0] i_reg_rd,
  input [1:0] i_csr_t,
  input [31:0] i_reg_src1,
  input [31:0] i_reg_src2,
  input [31:0] i_csr_src,
  input [31:0] i_imm,
  input [31:0] i_pc,
  input [31:0] i_csr_upc,

  output [31:0] o_result,
  output [31:0] o_upc,
  output o_result_t,
  /* output [3:0] o_alu_t, */
  output [1:0] o_csr_t,
  /* output o_cmp, */
  /* output o_zero, */
  output o_reg_wen,
  output o_csr_wen,
  output o_jump,
  /* output o_trap, */
  output o_mem_ren,
  output o_mem_wen,
  output [3:0] o_mem_wmask,
  output [2:0] o_mem_read_t,
  output [31:0] o_mem_addr,
  output [31:0] o_mem_wdata,
  output [4:0] o_reg_rd,
  output [31:0] o_pc,
  output o_fencei,

  input i_valid,
  output reg o_valid
`ifdef CONFIG_PIPELINE
  ,input i_ready,
  output o_ready,
  input i_flush,
  output o_flush
`endif
);

reg [6:0] op;
reg [2:0] func;
reg [31:0] reg_src1;
reg [31:0] csr_src;
reg [31:0] imm;
reg [31:0] pc;
reg [4:0] reg_rd;
reg [1:0] csr_t;
reg [31:0] mem_wdata;
wire update_reg;
/* reg valid; */
/**/
/* always@(posedge i_clock)begin */
/*   if(i_reset) valid <= 0; */
/*   else if(i_valid && !valid) valid <= 1; */
/*   else if(valid && !o_valid) valid <= 0; */
/* end */

`ifdef CONFIG_PIPELINE
always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(i_valid && !i_flush) begin
    o_valid <= 1;
  end
  else if(o_valid && i_ready) begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(i_reset) o_ready <= 1;
  else if(i_valid && o_valid && (o_mem_wen || o_mem_ren)) o_ready <= 0;
  else if(i_ready) o_ready <= 1;
  else if(i_valid) o_ready <= 0;
end

assign update_reg = i_valid && (o_ready || i_ready) && !i_flush;
reg flush_valid;
always@(posedge i_clock)begin
  if(i_reset) flush_valid <= 0;
  else if(update_reg) flush_valid <= 1;
  else if(flush_valid) flush_valid <= 0;
end
assign o_flush = o_jump && flush_valid;

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

assign update_reg = !i_reset && !o_valid && i_valid;
`endif

always@(posedge i_clock)begin
  if(update_reg)
    op <= i_op;
end
always@(posedge i_clock)begin
  if(update_reg)
    func <= i_func;
end
always@(posedge i_clock)begin
  if(update_reg)
    reg_src1 <= i_reg_src1;
end
always@(posedge i_clock)begin
  if(update_reg)
    csr_src <= i_csr_src;
end
always@(posedge i_clock)begin
  if(update_reg)
    imm <= i_imm;
end
always@(posedge i_clock)begin
  if(update_reg)
    pc <= i_pc;
end
always@(posedge i_clock)begin
  if(update_reg)
    reg_rd <= i_reg_rd;
end
always@(posedge i_clock)begin
  if(update_reg)
    csr_t <= i_csr_t;
end
always@(posedge i_clock)begin
  if(update_reg)
    mem_wdata <= i_reg_src2;
end
always@(posedge i_clock)begin
  if(update_reg)
    upc <= i_op == 7'b1110011 ? i_csr_upc : (i_op == 7'b1100111 ? i_reg_src1 : i_pc);
end

always@(posedge i_clock)begin
  if(update_reg) alu_a <= i_alu_a;
end
always@(posedge i_clock)begin
  if(update_reg) alu_b <= i_alu_b;
end
always@(posedge i_clock)begin
  if(update_reg) alu_sub <= i_alu_sub;
end
always@(posedge i_clock)begin
  if(update_reg) alu_sign <= i_alu_sign;
end
always@(posedge i_clock)begin
  if(update_reg) alu_sra <= i_alu_sra;
end
always@(posedge i_clock)begin
  if(update_reg) alu_t <= i_alu_t;
end

`ifndef CONFIG_YOSYS
always@(posedge i_clock)begin
  if(o_valid && !(I||R||L||S||JAL||JALR||AUIPC||LUI||B||CSR||FENCE)) begin
    $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh` in pc `%xh` \n", i_op, i_pc);
    quit();
  end
end
`endif

wire I = op == 7'b0010011;
wire R = op == 7'b0110011;
wire L = op == 7'b0000011;
wire S = op == 7'b0100011;
wire JAL = op == 7'b1101111;
wire JALR = op == 7'b1100111;
wire AUIPC = op == 7'b0010111;
wire LUI = op == 7'b0110111;
wire B = op == 7'b1100011;
wire CSR = op == 7'b1110011;
wire FENCE = op == 7'b0001111;
localparam BEQ = 4'b1000;
localparam BNE = 4'b1001;
localparam BLT = 4'b1100;
localparam BGE = 4'b1101;
localparam BLTU = 4'b1110;
localparam BGEU = 4'b1111;
wire f000 = func == 3'b000;
wire f001 = func == 3'b001;
wire f010 = func == 3'b010;
wire f011 = func == 3'b011;
wire f100 = func == 3'b100;
wire f101 = func == 3'b101;
wire f110 = func == 3'b110;
wire f111 = func == 3'b111;

assign o_result_t = L;
assign o_mem_wen = S;
assign o_mem_ren = L;
assign o_mem_wmask = S ? (f000 ? 4'b0001 : f001 ? 4'b0011 : 4'b1111) : 0;
assign o_mem_read_t = L ? func : 0;
assign o_fencei = FENCE && f001;
assign o_reg_rd = reg_rd;
assign o_csr_t = csr_t;
assign o_pc = pc;
assign o_mem_wdata = mem_wdata;
/* always@(posedge i_clock)begin */
/*   if(update_reg)  */
/*     $fwrite(32'h80000002, "`%xh` in pc `%xh` \n", i_op, i_pc); */
/* end */
reg [31:0] alu_a, alu_b;
reg alu_sub;
reg alu_sign;
reg alu_sra;
reg [3:0] alu_t;
wire cmp, zero;
wire branch = (alu_t==BEQ)&&zero||(alu_t==BNE)&&~zero||(alu_t==BLT||alu_t==BLTU)&&cmp||(alu_t==BGE||alu_t==BGEU)&&~cmp;
/* assign alu_a = JAL || JALR || AUIPC ? pc : LUI ? 0 : reg_src1; */
/* assign alu_b = I || L || AUIPC || S  || LUI ? imm : JAL || JALR ? 32'b100 : CSR && f001 ? 32'b0 : CSR && f010 ? csr_src : reg_src2; */
/* assign alu_t = I||R ? {1'b0, func} : B ? {1'b1, func} : CSR && f010 ? 4'b0110 : 0; */
/* assign alu_sign = R && f010 || B && (f100 || f101); */
/* assign alu_sub = (I || R) && (f011 || f010) || B || R && f000 && imm[5]; */
/* assign alu_sra = R && imm[5] || I && imm[10]; */

/* reg [31:0] r_alu_a, r_alu_b; */
/* reg r_alu_sub; */
/* reg r_alu_sign; */
/* reg r_alu_sra; */
/* reg [3:0] r_alu_t; */
/**/
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_a <= alu_a; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_b <= alu_b; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_sub <= alu_sub; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_sign <= alu_sign; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_sra <= alu_sra; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_t <= alu_t; */
/* end */


ysyx_24110006_ALU malu(
  .i_a(alu_a),
  .i_b(alu_b),
  .i_sub(alu_sub),
  .i_sign(alu_sign),
  .i_alu_t(alu_t),
  .i_alu_sra(alu_sra),
  .o_r(o_result),
  .o_cmp(cmp),
  .o_zero(zero),
  .o_add_r(o_mem_addr)
);

reg [31:0] upc;

assign o_upc = upc + imm;
assign o_jump = JAL || JALR || branch || trap;
wire trap = CSR && f000;
assign o_reg_wen = !(S || B);
assign o_csr_wen = CSR;
/* assign o_alu_t = alu_t; */
endmodule
