`include "common_config.sv"
module ysyx_24110006_IDU (
    input i_clock,
    input i_reset,
    input pipe::ifu2idu_single_t from_ifu,
    output ooo::idu2rename_t to_rename,
    input i_flush,

    if_pipeline_vr.in  i_vr,
    if_pipeline_vr.out o_vr
);

  pipe::ifu2idu_single_t ifu_data;

  wire update_reg;
  always @(posedge i_clock) begin
    if (update_reg) ifu_data <= from_ifu;
  end
  logic r_valid;
  assign r_valid = i_vr.valid & ~i_flush;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) o_vr.valid <= 0;
    else if (r_ready && r_valid && !o_vr.valid) begin
      o_vr.valid <= 1;
    end else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) begin
      o_vr.valid <= 0;
    end
  end
  reg r_ready;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) r_ready <= 1;
    else if (r_ready && r_valid && !o_vr.valid) r_ready <= 0;
    else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) r_ready <= 1;
  end
  assign i_vr.ready = (r_ready | o_vr.ready);
  assign update_reg = r_valid && (r_ready || o_vr.ready) && !i_flush;


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
  wire U = AUIPC | LUI;
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


  assign to_rename.vrs1 = inst[19:15];
  assign to_rename.vrs2 = inst[24:20];
  assign to_rename.vrd = inst[11:7];
  assign to_rename.reg_wen = !(S || B || FENCE) && inst[11:7]!=0;
  assign to_rename.op = inst[6:0];
  assign to_rename.func = inst[14:12];
  assign to_rename.csr_t = {mret, CSR & (inst_func != 0)};
  assign to_rename.pc = ifu_data.pc;
  assign to_rename.imm = ifu_data.imm;
  assign to_rename.csr = inst[31:20];
  assign to_rename.exception = exception;
  assign to_rename.mcause = mcause;
  assign to_rename.quit = breakpoint;
  assign to_rename.mret = mret;
  assign to_rename.is_lsu = L || S;
  assign to_rename.mem_wen = S;
  assign to_rename.need_rs[0] = !(U||JAL);
  assign to_rename.need_rs[1] = B | S | R;
  assign to_rename.bp_info = ifu_data.bp_info;
endmodule
