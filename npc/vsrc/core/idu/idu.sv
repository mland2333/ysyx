`include "common_config.sv"
module ysyx_24110006_IDU (
    input i_clock,
    input i_reset,
    input pipe::ifu2idu_t from_ifu,
    output pipe::idu2exu_t to_exu,
    output pipe::idu2aluop_t to_aluop,
    output pipe::reg_rinfo_t to_reg,
    output pipe::csr_rinfo_t to_csr,
    input i_flush,
    input i_stall,
    input i_wen,
    input i_ren,
`ifdef CONFIG_SIM
    input pipe::sim_t i_sim,
    output pipe::sim_t o_sim,
`endif
    if_pipeline_vr.in i_vr,
    if_pipeline_vr.out o_vr
);

  pipe::ifu2idu_t ifu_data;

  wire update_reg;
  always @(posedge i_clock) begin
    if (update_reg) ifu_data <= from_ifu;
  end
  always @(posedge i_clock) begin
    if (i_reset || i_flush) o_vr.valid <= 0;
    else if (i_vr.valid) begin
      o_vr.valid <= 1;
    end else if (o_vr.valid && o_vr.ready && !i_stall) begin
      o_vr.valid <= 0;
    end
  end
  reg r_ready;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) r_ready <= 1;
    else if (i_stall) r_ready <= 0;
    else if (i_vr.valid && o_vr.valid && (i_wen || i_ren)) r_ready <= 0;
    else if (o_vr.ready) r_ready <= 1;
    else if (i_vr.valid) r_ready <= 0;
  end
  assign i_vr.ready = (r_ready | o_vr.ready) & ~i_stall;
  assign update_reg = i_vr.valid && (r_ready || o_vr.ready) && !i_stall && !i_flush;


  wire [6:0] inst_op = inst[6:0];
  wire [2:0] inst_func = inst[14:12];

  wire I = inst_op[6:2] == 5'b00100;
  wire R = inst_op[6:2] == 5'b01100;
  wire L = inst_op[6:0] == 7'b0000011;
  wire S = inst_op[6:2] == 5'b01000;
  wire JAL = inst_op[6:2] == 5'b11011;
  wire JALR = inst_op[6:2] == 5'b11001;
  wire AUIPC = inst_op[6:2] == 5'b00101;
  wire LUI = inst_op[6:2] == 5'b01101;
  wire B = inst_op[6:2] == 5'b11000;
  wire CSR = inst_op[6:2] == 5'b11100;
  wire FENCE = inst_op[6:2] == 5'b00011;

  logic exception;
  logic [3:0] mcause;
  wire illegal_inst = !(I | R | L | S | JAL | JALR | AUIPC | LUI | B | CSR | FENCE) && !i_flush;
  wire breakpoint = inst == 32'h00100073;
  wire ecall_m = inst == 32'h00000073;
  wire my_exception = illegal_inst | breakpoint | ecall_m;
  wire [3:0] my_mcause = ({4{illegal_inst}} & 4'd2) |
                       ({4{breakpoint}} & 4'd3)   |
                       ({4{ecall_m}} & 4'd11);

  assign exception = ifu_data.exception | my_exception;
  assign mcause = ifu_data.exception ? ifu_data.mcause : my_mcause;

  logic [31:0] inst;
  logic mret;
  assign inst = ifu_data.inst;
  assign mret = inst == 32'h30200073;
  assign to_exu.op = inst[6:0];
  assign to_exu.func = inst[14:12];
  assign to_exu.reg_rd = inst[11:7];
  assign to_exu.csr_t = {mret, CSR & (inst_func != 0)};
  assign to_exu.pc = ifu_data.pc;
  assign to_exu.imm = ifu_data.imm;
  assign to_exu.csr = inst[31:20];
  assign to_exu.exception = exception;
  assign to_exu.mcause = mcause;

  assign to_reg.rs1 = inst[19:15];
  assign to_reg.rs2 = inst[24:20];

  assign to_csr.csr_r = inst[31:20];
  assign to_csr.mret = mret;

  assign to_aluop.op = inst[6:0];
  assign to_aluop.func = inst[14:12];
  assign to_aluop.imm = ifu_data.imm;
  assign to_aluop.pc = ifu_data.pc;
`ifdef CONFIG_SIM
  always @(posedge i_clock) begin
    if(o_vr.valid && !(I||R||L||S||JAL||JALR||AUIPC||LUI||B||CSR||FENCE) && !i_flush) begin
      $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh` in pc `%xh` \n",
              to_exu.op, ifu_data.pc);
      quit();
    end
  end
  always_ff@(posedge i_clock)begin
    if(update_reg) o_sim <= i_sim;
  end
`endif

endmodule
